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
1. **User:** register webhook in Razorpay Dashboard (URL `https://ukjaypykfqauvkctgzir.supabase.co/functions/v1/verify-payment`, secret = value in `.env`, events payment.captured/failed/refund.processed)
2. **User:** configure SMS provider in Supabase Auth → Phone (needed for OTP login)
3. **First login** → put user's uid into `platform_config.admin_user_ids` (SQL update)
4. Live end-to-end test on device: OTP → book worker → pay ₹20 (test keys) → worker accepts → complete → confirm → payout path
5. Optional later: Cloudflare proxy wiring (`Env.apiOrigin` exists but unused), Crashlytics, Play Store release pipeline, i18n toggle actually switching strings

## Gotchas learned the hard way
- PowerShell 5.1: `ConvertTo-Json` turns raw JSON strings into nested objects — wrap values with `($raw | ConvertTo-Json -Compress)` to force string literals
- Gradle Kotlin DSL: cannot call `file()` inside `plugins {}`; apply google-services conditionally AFTER the block
- PostgREST embeds honor target-table RLS — users SELECT policy allows seeing approved workers' names + booking counterparties (discovery depends on it)
- `booking_actor()` derives uid from `request.jwt.claim.sub` OR falls back to parsing `request.jwt.claims` JSON
- Deno not installed locally; CI runs `deno check */index.ts` instead
