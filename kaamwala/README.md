# kaamwala

KaamWala v2 - Find a verified worker in 30 seconds. Pay by UPI. Done.

## Setup & Run

### Prerequisites

1. Flutter SDK (>=3.13.1)
2. Android Studio / VS Code with Flutter extensions
3. For production: Supabase project, Razorpay account, SMS API approval

### Environment Configuration

1. Copy `.env.example` to `.env`:
   ```bash
   cp ../env.example ../.env
   ```

2. Fill in your values in `.env` (for production):
   - `KW_SUPABASE_URL`: Your Supabase project URL
   - `KW_SUPABASE_ANON_KEY`: Your Supabase anon/public key
   - `KW_RAZORPAY_KEY_ID`: Your Razorpay public key ID

### Running in Demo Mode (Development)

Demo mode uses mock services (OTP shown in DEMO banner) and doesn't require backend configuration:

```bash
# Customer App (Booking side)
flutter run --flavor customer -t lib/main_customer.dart --dart-define-from-file=../.env

# Partner App (Worker side)
flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=../.env
```

SMS stays in mock mode by default — no API key required:
- `KW_SMS_PROVIDER=mock` (default)
- `KW_ENABLE_DEMO_OTP=true` (default)

OTPs are generated locally, shown in a DEMO banner on screen and printed to the
console. A real provider (MSG91/Twilio) can be plugged into
`lib/core/services/sms/sms_providers.dart` later without touching any UI.

### Running in Production Mode

For production with real backend services:

```bash
# Customer App
flutter run --dart-define-from-file=../.env --flavor customer -t lib/main_customer.dart

# Partner App
flutter run --dart-define-from-file=../.env --flavor partner -t lib/main_partner.dart
```

### Building for Release

```bash
# Customer APK
flutter build apk --release --flavor customer -t lib/main_customer.dart \
  --target-platform android-arm64 --dart-define-from-file=../.env

# Partner APK
flutter build apk --release --flavor partner -t lib/main_partner.dart \
  --target-platform android-arm64 --dart-define-from-file=../.env
```

## Architecture Overview

### Two-App Split

One codebase, two Android flavors (`mode` dimension):
- **Customer** (`com.kaamwala.kaamwala`): booking + payment + chat
- **Partner** (`com.kaamwala.partner`): job management + worker registration

### Key Directories

```
lib/
├── core/                  # Shared infrastructure
│   ├── config/            # App config, constants, flavor
│   ├── env/               # Environment variables (dart-define)
│   ├── error/             # Result<T>, failure types
│   ├── routing/           # go_router + appRedirect()
│   ├── services/          # SMS, payment, notification, booking abstractions
│   ├── theme/             # Design system (KwShadows, KwMotion, type ramp)
│   └── ui/                # Component library (KwButton, KwSkeleton, …)
├── features/
│   ├── auth/              # OTP phone login, role selection, onboarding
│   ├── client/            # Customer: home, worker list, booking, payment
│   ├── worker/            # Worker: registration, job list/detail
│   ├── chat/              # Real-time chat (text/image/location)
│   ├── notifications/     # Notification center + in-app banner
│   └── shared/            # Connectivity, shared providers/screens
├── models/                # Booking, Worker, Review, PricingConfig…
└── services/              # FCM, analytics/Crashlytics
```

## Checks

```bash
flutter pub get
flutter analyze        # must be clean
flutter test           # 139 tests, all pass
dart format lib test   # CI enforces formatting
```

E2E harness (requires Supabase connection):
```bash
powershell -ExecutionPolicy Bypass -File tools/kw_e2e.ps1   # 46/46
```
