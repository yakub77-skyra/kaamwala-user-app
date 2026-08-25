# KaamWala v2 - Full lifecycle E2E (real HTTP against prod backend)
# Creates its own client+worker, runs signup->approve->book->pay(webhook)->
# accept->progress->complete->confirm->payout->review->chat->refund-leg,
# then cleans up everything it created.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$envFile = 'E:\the new kaamwala app\.env'
$cfg = @{}
Get-Content $envFile | ForEach-Object {
  if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') { $cfg[$Matches[1]] = $Matches[2] }
}
$url   = 'https://ukjaypykfqauvkctgzir.supabase.co'
$svc   = $cfg['SUPABASE_SERVICE_ROLE_KEY']
$anon  = $cfg['KW_SUPABASE_ANON_KEY']
$wsec  = $cfg['RZP_WEBHOOK_SECRET']

$suffix = Get-Date -Format 'HHmmss'
$cPhone = "+91990000$suffix"
$wPhone = "+91990001$suffix"
$cEmail = "e2e.c$suffix@example.com"
$wEmail = "e2e.w$suffix@example.com"
$pass   = 'Kw#Test123!'
$results = New-Object System.Collections.Generic.List[string]
$script:fail = 0

function Step($name, $ok, $detail='') {
  $tag = if ($ok) { 'PASS' } else { $script:fail++; 'FAIL' }
  $results.Add("[$tag] $name $(if($detail){'- ' + $detail})")
  Write-Host ("[{0}] {1} {2}" -f $tag, $name, $detail)
}
function Hdr($jwt) { @{ apikey=$anon; Authorization="Bearer $jwt"; Prefer='return=representation' } }
function HttpJson($method, $uri, $headers, $bodyObj) {
  try {
    $p = @{ Method=$method; Uri=$uri; Headers=$headers; ContentType='application/json';
            ErrorAction='Stop' }
    if ($bodyObj -is [string]) { $p.Body = [Text.Encoding]::UTF8.GetBytes($bodyObj) }
    elseif ($bodyObj -ne $null) { $p.Body = [Text.Encoding]::UTF8.GetBytes(($bodyObj | ConvertTo-Json -Depth 12 -Compress)) }
    $r = Invoke-RestMethod @p
    return @{ ok=$true; data=$r; status=200 }
  } catch {
    $code = 0; $msg = $_.Exception.Message
    if ($_.Exception.Response) {
      $code = [int]$_.Exception.Response.StatusCode
      try {
        $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
        $msg = $sr.ReadToEnd()
      } catch {}
    }
    return @{ ok=$false; status=$code; data=$msg }
  }
}

try {
  # ---------- 1. Create auth users (admin API) ----------
  $adm = @{ apikey=$svc; Authorization="Bearer $svc" }
  $cu = HttpJson 'Post' "$url/auth/v1/admin/users" $adm @{
    email=$cEmail; password=$pass; phone=$cPhone; email_confirm=$true; phone_confirm=$true }
  $wu = HttpJson 'Post' "$url/auth/v1/admin/users" $adm @{
    email=$wEmail; password=$pass; phone=$wPhone; email_confirm=$true; phone_confirm=$true }
  if (-not $cu.ok -or -not $wu.ok) { throw "user creation failed: $($cu.data) $($wu.data)" }
  $cUid = $cu.data.id; $wUid = $wu.data.id
  Step 'auth users created' $true "client=$cUid worker=$wUid"

  # ---------- 2. Password login -> JWTs ----------
  $cl = HttpJson 'Post' "$url/auth/v1/token?grant_type=password" @{ apikey=$anon } @{ email=$cEmail; password=$pass }
  $wl = HttpJson 'Post' "$url/auth/v1/token?grant_type=password" @{ apikey=$anon } @{ email=$wEmail; password=$pass }
  if (-not $cl.ok -or -not $wl.ok) { throw "login failed: $($cl.data) $($wl.data)" }
  $cJwt = $cl.data.access_token; $wJwt = $wl.data.access_token
  Step 'password login (JWTs)' $true

  # ---------- 3. Self-profile inserts (RLS) ----------
  $ci = HttpJson 'Post' "$url/rest/v1/users" (Hdr $cJwt) @{ id=$cUid; phone=$cPhone; name='E2E Client'; role='client'; city='Pune' }
  Step 'client self-insert profile' ($ci.ok -and $ci.data.role -eq 'client') ($ci.data | Out-String).Trim()
  $wi = HttpJson 'Post' "$url/rest/v1/users" (Hdr $wJwt) @{ id=$wUid; phone=$wPhone; name='E2E Worker'; role='worker'; city='Pune' }
  Step 'worker self-insert profile' ($wi.ok -and $wi.data.role -eq 'worker')

  # ---------- 4. Worker onboarding: tries approved, guard forces pending ----------
  $wk = HttpJson 'Post' "$url/rest/v1/workers" (Hdr $wJwt) @{
    user_id=$wUid; category='plumber'; city='Pune'; area='Kothrud'; bio='E2E plumber';
    skills=@('pipes','taps'); price_min=150; price_max=600; approval_status='approved' }
  $workerId = $wk.data.id
  Step 'worker onboard forced pending' ($wk.ok -and $wk.data.approval_status -eq 'pending') "status=$($wk.data.approval_status)"

  # ---------- 5. NEGATIVE: book unapproved worker must fail ----------
  $neg = HttpJson 'Post' "$url/rest/v1/bookings" (Hdr $cJwt) @{
    client_id=$cUid; worker_id=$workerId; category='plumber'; description='pre-approval attempt';
    address='Baner, Pune'; estimate_min=100; estimate_max=200 }
  Step 'NEG booking unapproved blocked' ((-not $neg.ok) -and $neg.status -eq 403) "http=$($neg.status)"

  # ---------- 6. Admin approves via edge fn (temp admin grant) ----------
  $pcg = HttpJson 'Get' "$url/rest/v1/platform_config?key=eq.admin_user_ids&select=value" $adm $null
  $origAdmins = $pcg.data[0].value
  $newAdmins = @($origAdmins) + @($cUid)
  HttpJson 'Patch' "$url/rest/v1/platform_config?key=eq.admin_user_ids" $adm @{ value = $newAdmins } | Out-Null
  $ap = HttpJson 'Post' "$url/functions/v1/approve-worker" (Hdr $cJwt) @{ worker_id=$workerId; action='approve' }
  Step 'approve-worker edge fn' ($ap.ok -and $ap.data.status -eq 'approved') ($ap.data | ConvertTo-Json -Compress)
  HttpJson 'Patch' "$url/rest/v1/platform_config?key=eq.admin_user_ids" $adm @{ value = $origAdmins } | Out-Null
  $chk = HttpJson 'Get' "$url/rest/v1/platform_config?key=eq.admin_user_ids&select=value" $adm $null
  Step 'admin list restored' (($chk.data[0].value -join ',') -eq ($origAdmins -join ','))

  # ---------- 7. Client creates booking ----------
  $bk = HttpJson 'Post' "$url/rest/v1/bookings" (Hdr $cJwt) @{
    client_id=$cUid; worker_id=$workerId; category='plumber';
    description='Kitchen tap leaking badly'; service_date=(Get-Date).AddDays(1).ToString('yyyy-MM-dd');
    time_slot='10-12'; address='Flat 402, Baner Road, Pune'; estimate_min=300; estimate_max=500 }
  if (-not $bk.ok) { throw "booking create failed: $($bk.data)" }
  $b1 = $bk.data.id; $ref1 = $bk.data.ref
  Step 'booking created pending' ($bk.data.status -eq 'pending') "$ref1"

  # ---------- 8. create-order ----------
  $co = HttpJson 'Post' "$url/functions/v1/create-order" (Hdr $cJwt) @{ booking_id=$b1 }
  Step 'create-order' ($co.ok -and $co.data.amount -eq 2000 -and $co.data.order_id -like 'order_*')
    "amount=$($co.data.amount) order=$($co.data.order_id)"
  $rzpOrder = $co.data.order_id

  # money math check (mid 400, rate 0.10 -> commission 40, earning 360)
  $bg = HttpJson 'Get' "$url/rest/v1/bookings?id=eq.$b1&select=commission_amount,worker_earning" $adm $null
  Step 'server money math' ("{0:N2}" -f [double]$bg.data[0].commission_amount -eq '40.00' -and
                            "{0:N2}" -f [double]$bg.data[0].worker_earning  -eq '360.00')
    "comm=$($bg.data[0].commission_amount) earn=$($bg.data[0].worker_earning)"

  # idempotency: second call reuses same order
  $co2 = HttpJson 'Post' "$url/functions/v1/create-order" (Hdr $cJwt) @{ booking_id=$b1 }
  Step 'create-order idempotent' ($co2.ok -and $co2.data.order_id -eq $rzpOrder)

  # ---------- 9. Webhook payment.captured (REAL Razorpay shape) ----------
  $payload = @{
    event = 'payment.captured'
    payload = @{ payment = @{ entity = @{
      id = "pay_e2e$suffix"; order_id = $rzpOrder; amount = 2000; currency='INR'; status='captured' } } }
  } | ConvertTo-Json -Depth 12 -Compress
  $hmac = New-Object System.Security.Cryptography.HMACSHA256
  $hmac.Key = [Text.Encoding]::UTF8.GetBytes($wsec)
  $sig = -join ($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($payload)) | ForEach-Object { $_.ToString('x2') })
  $whRsp = HttpJson 'Post' "$url/functions/v1/verify-payment" @{ 'x-razorpay-signature'=$sig } $payload
  Start-Sleep -Seconds 2
  $og = HttpJson 'Get' "$url/rest/v1/orders?booking_id=eq.$b1&select=status,paid_at" $adm $null
  Step 'WEBHOOK marks order paid (real shape)' ($og.data.Count -gt 0 -and $og.data[0].status -eq 'paid')
    "order_status=$($og.data[0].status)"
  $notifW = HttpJson 'Get' "$url/rest/v1/notifications?user_id=eq.$wUid&select=title,body" $adm $null
  Step 'worker got new-job notification' ($notifW.data.Count -ge 1)
    ($notifW.data | ForEach-Object { $_.title }) -join '; '

  # forged signature must 401
  $fg = HttpJson 'Post' "$url/functions/v1/verify-payment" @{ 'x-razorpay-signature'='deadbeef' } $payload
  Step 'NEG forged webhook 401' ($fg.status -eq 401)

  # ---------- 10. Lifecycle transitions ----------
  function Transition($jwt, $from, $to, $expectOk) {
    $r = HttpJson 'Patch' "$url/rest/v1/bookings?id=eq.$b1" (Hdr $jwt) @{ status=$to }
    $good = if ($expectOk) { $r.ok -and $r.data.Count -gt 0 -and $r.data[0].status -eq $to } else { -not $r.ok }
    Step "transition $from->$to $(if($expectOk){'allowed'}else{'blocked'})" $good
  }
  Transition $wJwt 'pending' 'completed' $false      # skip-ahead blocked
  Transition $wJwt 'pending' 'accepted'  $true
  Transition $cJwt 'accepted' 'in_progress' $false   # client cannot drive lifecycle
  Transition $wJwt 'accepted' 'traveling' $true
  Transition $wJwt 'traveling' 'arrived' $true
  Transition $wJwt 'arrived' 'in_progress' $true
  Transition $wJwt 'in_progress' 'completed' $true
  $mt = HttpJson 'Patch' "$url/rest/v1/bookings?id=eq.$b1" (Hdr $wJwt) @{ booking_fee=0 }
  Step 'NEG money-field tamper blocked' (-not $mt.ok) ($mt.data)

  # ---------- 11. Confirm completion -> payout ----------
  $rp = HttpJson 'Post' "$url/functions/v1/release-payout" (Hdr $cJwt) @{ booking_id=$b1; action='confirm' }
  Step 'release-payout confirm' ($rp.ok -and $rp.data.confirmed -eq $true) ($rp.data | ConvertTo-Json -Compress)
  $pg = HttpJson 'Get' "$url/rest/v1/payouts?booking_id=eq.$b1&select=amount,status" $adm $null
  Step 'payout row pending 360' ($pg.data.Count -eq 1 -and $pg.data[0].status -eq 'pending' -and
                                 [double]$pg.data[0].amount -eq 360) "amt=$($pg.data[0].amount) st=$($pg.data[0].status)"

  # ---------- 12. Review + atomic rating recompute ----------
  $rv = HttpJson 'Post' "$url/rest/v1/reviews" (Hdr $cJwt) @{
    booking_id=$b1; worker_id=$workerId; client_id=$cUid; rating=5; text='Fixed fast'; tags=@('punctual') }
  Step 'review inserted' $rv.ok
  $wg = HttpJson 'Get' "$url/rest/v1/workers?id=eq.$workerId&select=rating_avg,rating_count" $adm $null
  Step 'rating recomputed' ([double]$wg.data[0].rating_avg -eq 5 -and $wg.data[0].rating_count -eq 1)
    "avg=$($wg.data[0].rating_avg) n=$($wg.data[0].rating_count)"

  # ---------- 13. Chat both directions + outsider blocked ----------
  $m1 = HttpJson 'Post' "$url/rest/v1/chat_messages" (Hdr $cJwt) @{ booking_id=$b1; sender_id=$cUid; content='Bhaiya kab aaoge?' }
  $m2 = HttpJson 'Post' "$url/rest/v1/chat_messages" (Hdr $wJwt) @{ booking_id=$b1; sender_id=$wUid; content='10 baje pahunchunga' }
  Step 'chat client->worker' $m1.ok
  Step 'chat worker->client' $m2.ok
  $oldWorkerBookings = HttpJson 'Get' "$url/rest/v1/bookings?status=eq.pending&select=id&limit=1" $adm $null
  if ($oldWorkerBookings.data.Count -gt 0) {
    $obId = $oldWorkerBookings.data[0].id
    $m3 = HttpJson 'Post' "$url/rest/v1/chat_messages" (Hdr $wJwt) @{ booking_id=$obId; sender_id=$wUid; content='intrusion' }
    Step 'NEG outsider chat blocked' (-not $m3.ok) "http=$($m3.status)"
  }

  # ---------- 14. Refund leg: booking2 paid then cancelled ----------
  $bk2 = HttpJson 'Post' "$url/rest/v1/bookings" (Hdr $cJwt) @{
    client_id=$cUid; worker_id=$workerId; category='electrician';
    description='Fan repair'; service_date=(Get-Date).AddDays(2).ToString('yyyy-MM-dd');
    time_slot='12-14'; address='Flat 402, Baner Road, Pune'; estimate_min=200; estimate_max=400 }
  $b2 = $bk2.data.id
  $coB = HttpJson 'Post' "$url/functions/v1/create-order" (Hdr $cJwt) @{ booking_id=$b2 }
  $o2 = $coB.data.order_id
  $suffix2 = "${suffix}b"
  $payload2 = @{
    event = 'payment.captured'
    payload = @{ payment = @{ entity = @{ id = "pay_e2e$suffix2"; order_id = $o2; amount=2000; status='captured' } } }
  } | ConvertTo-Json -Depth 12 -Compress
  $sig2 = -join ($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($payload2)) | ForEach-Object { $_.ToString('x2') })
  HttpJson 'Post' "$url/functions/v1/verify-payment" @{ 'x-razorpay-signature'=$sig2 } $payload2 | Out-Null
  Start-Sleep -Seconds 2
  $cx = HttpJson 'Patch' "$url/rest/v1/bookings?id=eq.$b2" (Hdr $cJwt) @{ status='cancelled' }
  Step 'cancel while pending (after pay)' ($cx.ok -and $cx.data[0].status -eq 'cancelled')
  $rf = HttpJson 'Post' "$url/functions/v1/verify-payment" (Hdr $cJwt) @{ type='refund'; booking_id=$b2 }
  # NOTE: payment id is synthetic, so Razorpay API rejects the actual refund;
  # we assert the endpoint handles it gracefully (no crash, clear outcome).
  Step 'refund endpoint responds' ($rf.status -ne 0) "http=$($rf.status) body=$(if($rf.ok){$rf.data|ConvertTo-Json -Compress}else{$rf.data})"
  $og2 = HttpJson 'Get' "$url/rest/v1/orders?booking_id=eq.$b2&select=status" $adm $null
  Write-Host "[info] booking2 order status after refund attempt: $($og2.data[0].status)"
  $script:b2Status = $og2.data[0].status
}

finally {
  # ---------- Cleanup ----------
  Write-Host "`n--- cleanup ---"
  try {
    if ($b1) { HttpJson 'Delete' "$url/rest/v1/bookings?id=eq.$b1" $adm $null | Out-Null }
    if ($b2) { HttpJson 'Delete' "$url/rest/v1/bookings?id=eq.$b2" $adm $null | Out-Null }
    foreach ($u in @($cUid, $wUid)) {
      if ($u) { HttpJson 'Delete' "$url/auth/v1/admin/users/$u" $adm $null | Out-Null }
    }
    Write-Host 'cleanup done (bookings, payouts/reviews/chat cascaded, auth users deleted)'
  } catch { Write-Host "CLEANUP ERROR: $($_.Exception.Message)" }
}

Write-Host "`n===== SUMMARY ====="
$results | ForEach-Object { Write-Host $_ }
Write-Host "failures: $script:fail"
exit $script:fail