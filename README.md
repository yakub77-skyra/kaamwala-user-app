# KaamWala v2 🇮🇳

> **"Find a verified worker in 30 seconds. Pay by UPI. Done."**

A trust-first marketplace connecting urban Indian households with verified
blue-collar workers (Plumber • Electrician • Painter • Carpenter).

Built from the four phase documents in this repository:

| Phase | Document | Status |
|---|---|---|
| 1 | `PHASE_1_IDEA_AND_VALIDATION.md` — problem, competitors, personas | ✅ |
| 2 | `Phase 2 Requirements Gathering.md` — PRD: MVP features, user stories | ✅ |
| 3 | `phase_3_system_design.md` — design tokens, wireframes, ERD, RLS | ✅ |
| 4 | `phase_4_tech_stack.md` — Flutter/Dart stack decision | ✅ |

## Stack (Phase 4)

- **Flutter (Dart) 3.47** + **Riverpod** + **go_router** + Material 3
- **Supabase**: Postgres + RLS, Phone OTP Auth, Storage, Realtime, Edge Functions (Deno)
- **Razorpay + Razorpay X**: ₹20 booking fee collection + same-day UPI payouts
- **Cloudflare Worker**: reverse proxy bypassing Jio/Airtel Supabase DNS blocks
- **FCM**: push notifications

## Project layout

```
kaamwala/
├── lib/
│   ├── core/            # constants, theme (design tokens), routing, error types, env
│   ├── features/
│   │   ├── auth/        # login, OTP, role selection (locked role)
│   │   ├── client/      # home, search, profile, booking, payment, chat, reviews
│   │   ├── worker/      # register(3-step), review gate, dashboard, jobs, earnings
│   │   └── shared/      # settings, notifications, common widgets
│   ├── models/          # typed models - no Map<String,dynamic> leaks into UI
│   └── services/        # Supabase / Razorpay / FCM wrappers
├── supabase/
│   ├── migrations/      # 0001 schema · 0002 RLS · 0003 triggers
│   └── functions/       # create-order · verify-payment · release-payout
│                        # approve-worker · send-push
└── test/
cloudflare/supabase-proxy.js   # deploy via wrangler.toml
.env.example                   # dart-define template
```

## Setup

All tooling on this machine was installed on **E:** drive (C: has no space):

| Component | Location |
|---|---|
| Flutter SDK | `E:\flutter` |
| Pub cache (`PUB_CACHE`) | `E:\pub-cache` |
| JDK 17 (`JAVA_HOME`) | `E:\java\jdk-17.0.20+8` |
| Android SDK (`ANDROID_HOME`) | `E:\android-sdk` (platform 36, build-tools 36) |
| Gradle home (`GRADLE_USER_HOME`) | `E:\gradle-home` |
| Temp (`TEMP`/`TMP`) | `E:\tmp` |

```powershell
cd kaamwala
flutter pub get
flutter analyze     # clean
flutter test        # green
```

### Run against your Supabase project

```bash
cp ../.env.example .env    # fill in URL + anon key (+ Razorpay key id)
flutter run --dart-define-from-file=.env
```

Without a `.env`, the app runs in **demo mode** so you can explore all 22 MVP
screens offline.

### Backend deployment

1. SQL Editor → run `supabase/migrations/0001_schema.sql`, then `0002_rls_policies.sql`, then `0003_triggers.sql`.
2. Storage buckets (private): `aadhar_scans`, `chat_media`; public: `profiles`, `portfolios`.
3. Edge Functions:
   ```bash
   supabase functions deploy create-order verify-payment release-payout approve-worker send-push
   supabase secrets set RAZORPAY_KEY_ID=... RAZORPAY_KEY_SECRET=... \
     RAZORPAY_WEBHOOK_SECRET=... FCM_SERVER_KEY=... RZPX_ACCOUNT_NUMBER=...
   ```
4. Cloudflare proxy: edit `UPSTREAM` in `cloudflare/supabase-proxy.js`, then `wrangler deploy`.
5. Webhook URL (Razorpay dashboard): `https://<ref>.supabase.co/functions/v1/verify-payment`
   with event `payment.captured` + `refund.processed`.

## Security model (non-negotiable)

- App holds only **public** keys (anon key, Razorpay key id).
- All money math (commission 10%, ₹20 fee) computed **server-side** in Edge Functions.
- Razorpay webhooks verified with **HMAC-SHA256**; unsigned requests rejected.
- Every table has **RLS**; Aadhar photos live in a **private** bucket.
- Double-payout guard: order must be `PAID` + client confirmed + no prior payout.

## Money flow

```
Client pays ₹20 fee → Razorpay → webhook verifies → booking PAID → worker notified
Worker completes job → client confirms → Edge Function computes 90% share
→ Razorpay X UPI payout → worker paid same day → notification sent
```

North Star metric: **completed bookings per week**.
