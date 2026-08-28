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
   cp .env.example .env
   ```

2. Fill in your values in `.env` (for production):
   - `KW_SUPABASE_URL`: Your Supabase project URL
   - `KW_SUPABASE_ANON_KEY`: Your Supabase anon/public key
   - `KW_RAZORPAY_KEY_ID`: Your Razorpay public key ID
   - `KW_DEMO_MODE`: Set to `true` for development, `false` for production

### Running in Demo Mode (Development)

Demo mode uses mock services (hardcoded OTP: 123456) and doesn't require backend configuration:

```bash
# Customer App (Booking side)
flutter run \
  --dart-define=KW_DEMO_MODE=true \
  -t lib/main_customer.dart

# Partner App (Worker side)
flutter run \
  --dart-define=KW_DEMO_MODE=true \
  -t lib/main_partner.dart
```

### Running in Production Mode

For production with real backend services:

```bash
# Customer App
flutter run \
  --dart-define-from-file=.env \
  --flavor customer \
  -t lib/main_customer.dart

# Partner App
flutter run \
  --dart-define-from-file=.env \
  --flavor partner \
  -t lib/main_partner.dart
```

### Building for Release

```bash
# Customer APK
flutter build apk \
  --dart-define-from-file=.env \
  --flavor customer \
  -t lib/main_customer.dart

# Partner APK
flutter build apk \
  --dart-define-from-file=.env \
  --flavor partner \
  -t lib/main_partner.dart
```

## Architecture Overview

### Phase 1: Frontend Foundation

- **SMS Service Abstraction**: Pluggable SMS service (DemoSmsService → RealSmsService)
- **Error Handling**: User-friendly error messages via `AppException` and `ErrorMapper`
- **Loading States**: Skeleton loaders, loading buttons, empty states
- **Trust UI**: Legal screens, support screen, language selection

### Key Directories

```
lib/
├── core/                  # Shared infrastructure
│   ├── analytics/         # Analytics tracking
│   ├── config/            # App configuration & constants
│   ├── env/               # Environment variables
│   ├── error/             # Error handling & exceptions
│   ├── services/          # SMS service abstraction
│   ├── theme/             # App theme & colors
│   └── ui/                # Reusable UI components
├── features/              # Feature modules
│   ├── auth/              # Authentication (OTP login)
│   ├── client/            # Customer booking flow
│   ├── worker/            # Worker job management
│   ├── legal/             # Legal & policy screens
│   └── settings/          # Settings & preferences
├── models/                # Data models
└── services/              # External services (Supabase, Razorpay)
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
