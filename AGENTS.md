# KaamWala v2 — Agent Handbook

> This file is auto-loaded into every opencode session working in this repo.
> It carries project context across restarts so no re-explanation is needed.

## What this project is
KaamWala = India-first marketplace app connecting customers ("clients") with verified blue-collar workers (plumber/electrician/painter/carpenter) in Pune. Phone-OTP login, Razorpay ₹20 booking fee, 10% commission, UPI payouts, Hindi-first worker UI.

**Stack:** Flutter + Riverpod + go_router (app, `kaamwala/`) · Supabase (Postgres + RLS + Edge Functions + Storage + Realtime) · Razorpay (+X payouts) · FCM push · Cloudflare proxy (deferred, placeholder only).

**Specs:** read `PHASE_1_IDEA_AND_VALIDATION.md`, `Phase 2 Requirements Gathering.md`, `phase_3_system_design.md`, `phase_4_tech_stack.md` for product/design/DB decisions. Phase 3 §7 = DB schema source of truth.

## Current status (as of 2026-08-24)
- ✅ UI/UX overhaul (committed 2026-08-25 as `35a14bc`): tab shells switched to `StatefulShellRoute.indexedStack` (tabs keep state; back pops within tab - fixes "restarts from new"), all detail navs use `context.push`, splash delay removed, theme polished (shadows/transitions/dialogs/bottom sheets), emoji-as-icons replaced with Material icons, WorkerCard/StatusPill/SectionHeader redesigned. New features: bookings filter tabs + cancel confirm dialog, worker list sort menu, edit name/city sheet (`AuthRepository.updateDetails`), Help FAQ sheet, call-worker button (url_launcher, phone via `users(name, photo_url, phone)` embed), portfolio photo viewer, real price ranges in booking form (was hardcoded ₹300–800). Fixed: rate_review submitted placeholder ids ('worker-id') -> FK failures; payment screen fake UPI chips removed
- ✅ Production readiness Phase 0 done (`bde5afc`): dead hi/en toggle removed (PrefsState lost `language`), demo-mode fake data (booking/order/worker/chat-uid) replaced with typed errors, release builds without KW_* env show misconfiguration screen instead of demo mode, sqflite dropped (package_info_plus KEPT - used by Settings version display)
- ✅ Production readiness Phase 1 done (`aa4114e`): AnalyticsService (`lib/services/analytics_service.dart`) = Analytics funnel events + Crashlytics global handlers armed in main(); FcmService OWNS the single Firebase.initializeApp call; every repo exception reported via mapException->recordError. Events: app_open, otp_requested(/resend)/verified, onboarding_completed(role prop), booking_created(category), order_created/failed, payment_succeeded/failed, booking_cancelled, completion_confirmed, job_accepted, job_<status>. Connectivity: offline banner via `_OfflineBoundary` in MaterialApp.builder + reconnect auto-invalidate of list providers (`connectivity_provider.dart`). Startup health: network/server error during restore -> `AppStage.startupError` splash retry screen (was: silent dump to roleSelection). Gradle: crashlytics plugin conditionally applied with google-services.json; debug APK build verified. NOTE: connectivity_plus 7.x emits List<ConnectivityResult>; Riverpod Notifier has no dispose override - use ref.onDispose
- ✅ Production readiness Phase 2 done (`89cfe09`): 33 tests total. **CRITICAL FIX**: `BookingStatus.dbValue` wrote `'inProgress'` but `bookings_guard` trigger validates literal `'in_progress'` — real workers would be stuck at Start Work; E2E harness missed it because it bypasses the Flutter client. fromDb/dbValue now round-trip on dbValue (regression-pinned). Router redirect extracted to pure `appRedirect()`; booking.fromMap null-tolerant ids. New test files: failure_test, router_redirect_test, booking_model_test, worker_stats_test (provider-override pattern for money windows), prefs_test (shared_preferences mock caches per-process — order tests accordingly, poll-until-loaded instead of fixed delays)
- ✅ Production readiness Phase 3 done (`b00eee3`): send-push v7 admin-gated via platform_config.admin_user_ids (was: any authed user could push arbitrary text to anyone; live-tested non-admin JWT -> 403; internal callers unaffected — they use _shared/push.ts directly). verify-payment v10 refund leg requires booking.status='cancelled'. Storage audit clean: aadhar_scans private + owner-scoped writes, no owner-delete (by design for KYC); profiles/portfolios public-read only + owner-scoped writes. Advisors: perf 0 findings; security = 2 known WARNs (admin_pending_workers definer = accepted-by-design; leaked-password protection needs Pro plan — app is phone-OTP-only so risk ~zero, enable after upgrade). platform_config verified: fee ₹20 / commission 0.10 / otp_resends 3 / admin_user_ids SET (pending item #3 already done)
- ✅ UI 2.0 overhaul done (M1-M7, `8465c8e`..`e03a210`): Urban-Company-style premium trust design. Design system in app_theme.dart (action orange #F4511E + ink navy, KwShadows s1/s2/s3, 4-radius scale, full type ramp, KwMotion). Component library lib/core/ui/ (KwIconWell/KwButton/KwSkeleton/KwStatCard/KwEmptyState + 6 SVG illustrations in assets/illustrations/, pubspec assets registered). Legacy emoji EmptyState DELETED; BookingStatus.emoji removed; zero Devanagari (worker UI is English-only per user decision; Hindi returns with real i18n). All screens migrated M3-M7. Gates per milestone: format+analyze+33 tests green. NOTE: PS 5.1 console renders unicode as ? - always verify via ripgrep/byte checks, and never use Set-Content without UTF8 for .dart files
- ⚠️ User actions from Phase 3: enable PITR/backups in Supabase dashboard (Settings → Add-ons, paid) or accept logical-dump risk; enable Leaked Password Protection when upgrading to Pro
- ✅ Production backend LIVE on Supabase project ref `ukjaypykfqauvkctgzir`
  - 11 tables, RLS everywhere (security advisor: 0 findings), trigger-based state machine, money-field locks, notification triggers, storage buckets (`profiles`/`portfolios` public, `aadhar_scans` private), realtime on bookings/chat/orders
  - Migrations mirrored in `kaamwala/supabase/migrations/0001..0004` matching applied history (`bookings_guard_service_path`, `harden_functions_and_policies`, `robust_actor_detection` also applied)
- ✅ 5 Edge Functions deployed & ACTIVE: `create-order`, `verify-payment` (**verify_jwt=false**, webhook+refund dual-mode), `release-payout`, `approve-worker`, `send-push`. Sources in `kaamwala/supabase/functions/<name>/index.ts` + `_shared/{db,http,push,razorpay}.ts` (imports MUST be `./_shared/...`)
- ✅ All function secrets set via Management API: RZP_KEY_ID, RZP_KEY_SECRET, RZP_WEBHOOK_SECRET, FCM_SERVICE_ACCOUNT_JSON (SUPABASE_SERVICE_ROLE_KEY/SUPABASE_URL/SUPABASE_ANON_KEY are auto-provisioned)
- ✅ Webhook endpoint LIVE-TESTED end-to-end (2026-08-24): real-shape Razorpay payload (`"event":"payment.captured"`) + valid HMAC → order `created`→`paid` + worker notification; forged → 401. Two bugs found & fixed in `verify-payment` v9: (a) handler only read `event.type` but Razorpay sends top-level `event` — orders never marked paid, silently; (b) refund mode re-read `req.text()` after consumption → always 500 "Body already consumed". Refund leg now reaches the Razorpay API (404 on synthetic payment ids is expected in test mode; real captured payments refund fine)
- ✅ Full lifecycle E2E re-run 2026-08-24: 33/33 checks pass (signup→approve→book→create-order→webhook-pay→accept→traveling→arrived→in_progress→completed→confirm→payout-pending ₹360→review+rating→chat→cancel+refund-leg). Harness at `E:\tmp\opencode\kw_e2e.ps1` (temp dir - copy into repo if wanted); creates its own users, cleans up after itself
- ✅ Flutter app builds (debug APK verified): real UI everywhere (no hardcoded demo data left), FCM token lifecycle + tap deep-links, avatar/portfolio uploads, release signing via uncommitted `android/key.properties` (template: `key.properties.example`), proguard, custom launcher icon
- ✅ CI at `.github/workflows/ci.yml` (format check, analyze, test, deno check)
- ✅ Full-lifecycle DB smoke test passed under simulated client/worker/service JWTs
- ✅ Admin verification console LIVE: `/admin` route + Settings entry (admins only), backed by `admin_pending_workers()` SECURITY DEFINER RPC (migration `0005_admin_queue.sql`) whose allowlist check runs INSIDE the query - non-admins get 0 rows (tested). Advisor WARN about callable definer is accepted-by-design; do not "fix" by revoking execute or moving to kw_private (app needs PostgREST access)
- ✅ App env complete in `.env` (KW_SUPABASE_URL/KW_SUPABASE_ANON_KEY/KW_RAZORPAY_KEY_ID added) - run with `flutter run --dart-define-from-file=../.env`
- ✅ Booking detail shows real worker name/avatar; counterpart names in chat headers

## How to operate Supabase from this machine
- No supabase CLI installed. Use:
  1. MCP tools (supabase MCP configured in `opencode.json`) for SQL/migrations/functions deploy
  2. Management REST API for secrets: `Invoke-RestMethod` POST/GET `https://api.supabase.com/v1/projects/ukjaypykfqauvkctgzir/secrets` with Bearer token from `.env` (`SUPABASE_ACCESS_TOKEN`). Secret values must serialize as JSON *strings* (see PS 5.1 gotcha below).
- Deploying a function = `supabase_deploy_edge_function` tool with files array containing `index.ts` + every `_shared/*.ts` it imports. Relative import path inside deployed bundle must be `./_shared/x.ts`.
- After changing applied SQL, mirror it into `kaamwala/supabase/migrations/*.sql`.

## Run/test commands
```
cd kaamwala
flutter pub get
flutter analyze        # must be clean
flutter test           # 5 tests, all pass
flutter build apk --debug   # ~5-10 min first run
dart format lib test   # CI enforces formatting
```
App runs with env from `.env`: `flutter run --dart-define-from-file=../.env` — but `.env` holds SERVER keys too; the app only reads KW_* vars (`KW_SUPABASE_URL`, `KW_SUPABASE_ANON_KEY`, `KW_RAZORPAY_KEY_ID` are NOT yet in `.env` — add them or pass via --dart-define).

## Key conventions
- Repositories return `Result<T>` (`Success/Error` from `core/error/failure.dart`); UI never sees raw exceptions
- All money math server-side only (Edge Functions); client displays values from DB
- Statuses stored lowercase text matching Dart enum `.name` (e.g. `'in_progress'`, orders `'paid'`)
- Booking lifecycle guarded by DB trigger: pending→accepted→traveling→arrived→in_progress→completed; client can only cancel while pending; service role bypasses
- Worker approval gate: workers.approval_status='pending' until admin approves via `approve-worker` edge fn (admin list in `platform_config.admin_user_ids`)

## Pending checklist (next work items)
1. ~~Register webhook in Razorpay Dashboard~~ DONE - programmatically verified active (`rzp_test` account): URL `https://ukjaypykfqauvkctgzir.supabase.co/functions/v1/verify-payment`, includes payment.captured/failed/refund.processed (+ many harmless extra events); HMAC secret matches RZP_WEBHOOK_SECRET (proven by live forged=401/valid=pass tests)
2. **User:** MSG91 signup + DLT registration (entity, header e.g. KMWALA, OTP template with #OTP# variable). RECOMMENDATION: MSG91 (~₹0.15-0.25/OTP; Twilio ≈ ₹1.50+ = 3-10x pricier). DLT lead time 24-72h.
   **SMS PIPELINE ALREADY BUILT** (`4c34fd6`): `send-sms` edge fn v1 deployed DORMANT (Standard Webhooks sig check -> MSG91 V5 flow API; verify_jwt=false by design - authenticity via signature). ACTIVATION when keys arrive: (a) set fn secrets MSG91_AUTH_KEY + MSG91_TEMPLATE_ID (Management API POST /secrets array form); (b) PATCH /config/auth: hook_send_sms_enabled=true, hook_send_sms_uri=https://ukjaypykfqauvkctgzir.supabase.co/functions/v1/send-sms, hook_send_sms_secrets=`v1,whsec_WX0xc9C8nxfAYuZ51cYXgp54welGvEYuM7sAwdemnoM=` (fn-side SEND_SMS_HOOK_SECRET already stored WITHOUT prefix); (c) test real-number OTP delivery
3. ~~First login -> platform_config.admin_user_ids~~ DONE - already set (verified in Phase 3)
4. **DEVICE E2E NOW UNBLOCKED WITHOUT MSG91**: test-OTP bypass refreshed to 2026-12-31 for phone +916300204252 (= admin uid bea75642-b97a-4750-af47-b338f49b312a) with fixed code 123456 (`message_id:"test-otp"`, full login loop verified 2026-08-25). Walk on device: install release APK (--dart-define-from-file=../.env), login with that number/123456, book -> pay ₹20 test -> accept -> complete -> confirm; ALSO clears deferred R8/proguard runtime smoke. Release build: `flutter build apk --release --target-platform android-arm64 --dart-define-from-file=../.env` (~1/3 build time). NOTE: other phone numbers still need MSG91 (item 2)
   **SINGLE-DEVICE DUAL-ROLE FIXTURE (2026-08-25)**: second test number +919900001111=123456 -> "Test Worker Ramesh" (auth uid 692e11d0-d666-4ae9-910d-1fa48795892d), users+workers rows pre-seeded PENDING approval, plumber Kharadi/Pune ₹200-600 (worker_row_id 3374ba66-076f-48e8-b577-6a9d5994f061). Device flow: login client/admin number -> first-login profile screen (name/city/Customer) -> search plumber -> book Ramesh -> pay ₹20 rzp_test -> Settings>Admin console approve worker -> logout -> login 919900001111/123456 -> pick Worker role -> jobs -> accept->traveling->arrived->start->complete -> logout -> back as client -> confirm completion -> rate. Release APK arm64 built+ready at kaamwala\build\app\outputs\flutter-apk\app-release.apk (58.6MB, R8 on, upload-key signed)
5. E2E harness lives at `kaamwala/tools/kw_e2e.ps1`; run `powershell -ExecutionPolicy Bypass -File tools\kw_e2e.ps1` - self-contained, 33/33 PASS 2026-08-25 post-hardening
6. Optional later: Cloudflare proxy wiring (`Env.apiOrigin` exists but unused), Play Store upload (Phase 5 docs ready in kaamwala/store/, keystore password given to user), i18n proper hi/en (post-v1 backlog)

## Gotchas learned the hard way
- PowerShell 5.1: `ConvertTo-Json` turns raw JSON strings into nested objects — wrap values with `($raw | ConvertTo-Json -Compress)` to force string literals
- Gradle Kotlin DSL: cannot call `file()` inside `plugins {}`; apply google-services conditionally AFTER the block
- PostgREST embeds honor target-table RLS — users SELECT policy allows seeing approved workers' names + booking counterparties (discovery depends on it)
- `booking_actor()` derives uid from `request.jwt.claim.sub` OR falls back to parsing `request.jwt.claims` JSON
- Deno not installed locally; CI runs `deno check */index.ts` instead
