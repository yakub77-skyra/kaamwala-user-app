```markdown
# KaamWala v2 — Phase 4: Tech Stack Decision

> **Document Type:** Technology Stack & Architecture Specification
> **Version:** 2.0.0
> **Date:** 2026
> **Author:** yakubpasha123
> **Status:** Finalized & Approved
> **Previous Docs:** Phase 1 (Validation) ✅ → Phase 2 (PRD) ✅ → Phase 3 (Design) ✅

---

## Executive Summary

For KaamWala v2, we are moving away from the React Native + JavaScript stack used in v1. The new stack is chosen for **type safety, performance, maintainability, and the specific realities of the Indian market** (budget Android devices, UPI dominance, ISP DNS blocking).

| Layer | Technology Chosen | Why? |
|---|---|---|
| **Frontend** | **Flutter (Dart)** | Compiled, null-safe, single codebase, superior UI performance on budget Android. |
| **State Mgmt** | **Riverpod** | Compile-time safe, no BuildContext dependency, testable. |
| **Navigation** | **go_router** | Declarative, deep-link friendly, type-safe. |
| **Backend API** | **Supabase (PostgREST + Edge Fns)** | Zero-backend maintenance, RLS security, server-side Dart/Deno logic. |
| **Database** | **PostgreSQL** | Relational integrity, ACID compliance, triggers, JSONB support. |
| **Auth** | **Supabase Auth (Phone OTP)** | India-first, SMS OTP, no password fatigue. |
| **Payments** | **Razorpay + Razorpay X** | Best UPI support, native checkout, automated payouts. |
| **Proxy** | **Cloudflare Workers** | Bypasses Jio/Airtel Supabase DNS blocks. |
| **Push Notifs** | **Firebase Cloud Messaging (FCM)** | Most reliable Android push delivery. |

---

## 1. Frontend (Mobile App)

### 1.1 Framework: Flutter (Dart)
We are abandoning React Native (Expo) for this rebuild. 

| Feature | React Native (v1) | Flutter (v2) |
|---|---|---|
| **Language** | JavaScript (loosely typed) | **Dart (strongly typed, null-safe)** |
| **Rendering** | Native components via JS Bridge | **Skia/Impeller (renders own pixels, 60/120fps)** |
| **Performance** | Bridge overhead on heavy lists/maps | **Compiled to native ARM code** |
| **UI Consistency** | Varies by Android OEM skin | **Pixel-perfect across all devices** |
| **App Size** | ~40MB+ | **~15MB base** |

**Core Flutter Packages:**
- `flutter_riverpod` (State management)
- `go_router` (Navigation & deep linking)
- `supabase_flutter` (Backend client)
- `razorpay_flutter` (Payments)
- `google_fonts` (Typography: Plus Jakarta Sans & Noto Sans Devanagari)
- `flutter_svg` (Vector icons)
- `cached_network_image` (Image caching & optimization)
- `image_picker` & `image_cropper` (Camera/Gallery)
- `flutter_image_compress` (Client-side WebP compression)

### 1.2 State Management: Riverpod
v1 used Zustand (JavaScript). v2 uses Riverpod (Dart).
- **Why:** Riverpod catches errors at *compile time*. If a provider fails to load, the UI handles it gracefully without crashing. It removes the need for `BuildContext` in business logic, making services easily testable.

### 1.3 Architecture Pattern: Clean Architecture + MVVM
```
lib/
 ├── core/           # Constants, themes, routing, error handling
 ├── features/       # Domain-driven folders
 │    ├── auth/      # Login, OTP, Role Selection
 │    ├── client/    # Home, Search, Booking, Chat
 │    ├── worker/    # Dashboard, Jobs, Earnings
 │    └── shared/    # Profile, Settings, Notifications
 └── services/       # Supabase, Razorpay, FCM wrappers
```
Each feature contains: `screens/`, `widgets/`, `providers/` (Riverpod), and `repositories/`.

---

## 2. Backend & API

### 2.1 API Layer: Supabase PostgREST + Edge Functions
We are **not** building a custom Node.js/Express backend. Supabase handles the API layer automatically.

- **Standard CRUD:** Handled directly by the Flutter app talking to Supabase via PostgREST (secured by RLS).
- **Complex Logic:** Handled by **Supabase Edge Functions** (written in Deno/TypeScript).
  - *Why Edge Functions?* Payment math, commission calculations, and payout triggers **must** happen server-side to prevent client tampering.

### 2.2 Network Proxy: Cloudflare Workers
**Critical for India:** Major ISPs (Jio, Airtel) frequently block or throttle `supabase.co` domains via DNS.
- **Solution:** A lightweight Cloudflare Worker acts as a reverse proxy.
- **Flow:** Flutter App → `api.kaamwala.com` (Cloudflare) → `xyz.supabase.co`.
- **Cost:** Free tier (100,000 requests/day).

---

## 3. Database

### 3.1 Engine: PostgreSQL (via Supabase)
We rejected Firebase (NoSQL) and MongoDB. 
- **Why Postgres?** KaamWala is highly relational. A `booking` links a `client`, a `worker`, an `order`, a `payout`, and `reviews`. SQL handles this natively with foreign keys and `JOIN`s. NoSQL would require massive data duplication and complex client-side joins.

### 3.2 Security: Row Level Security (RLS)
Instead of writing API middleware to check "Is this user allowed to see this booking?", we write RLS policies in the database.
```sql
-- Example: Users can only see their own bookings
CREATE POLICY "Users can view own bookings"
ON bookings FOR SELECT
USING (auth.uid() = client_id OR auth.uid() IN (SELECT user_id FROM workers WHERE id = worker_id));
```
**Result:** Even if someone steals the Supabase anon key, they cannot read other people's data.

---

## 4. Authentication

### 4.1 Provider: Supabase Auth (Phone OTP)
- **Method:** SMS OTP only for MVP.
- **Why no Email/Password?** Target audience (especially workers) forgets passwords. Phone number is the universal ID in India.
- **Why no Google Login?** Adds friction for blue-collar workers. Keep it dead simple: Enter Phone → Get SMS → Enter Code → Done.
- **Session Management:** Supabase Flutter SDK handles JWT storage, auto-refresh, and session persistence securely in the device keychain/keystore.

---

## 5. Payments & Financials

### 5.1 Collection: Razorpay (Standard)
- **SDK:** `razorpay_flutter` (Native Android/iOS checkout).
- **Why:** 95%+ UPI market share in India. Supports GPay, PhonePe, Paytm natively inside the app without redirecting to a browser.
- **Security:** The mobile app only receives the `order_id` and `key_id`. The **Razorpay Secret Key** lives exclusively in the Supabase Edge Function.

### 5.2 Payouts: Razorpay X
- **Purpose:** Sending money *from* KaamWala *to* the Worker's bank/UPI.
- **Why:** Automates daily payouts. No manual bank transfers. Handles TDS compliance and penny-drop verification automatically.
- **Flow:** Edge Function calls Razorpay X API → Worker gets money in UPI instantly.

---

## 6. Infrastructure & DevOps

### 6.1 Storage: Supabase Storage
- **Buckets:** `profiles` (public), `portfolios` (public), `aadhar_scans` (private), `chat_media` (private).
- **Pipeline:** Images are compressed client-side (Flutter) to WebP before upload to save bandwidth and storage costs.

### 6.2 Push Notifications: Firebase Cloud Messaging (FCM)
- **Why FCM over Expo Push?** FCM is the native Android push standard. It has better delivery rates on budget Android phones with aggressive battery savers (MIUI, OxygenOS).
- **Flow:** Supabase Edge Function receives an event (e.g., "New Booking") → calls FCM API → FCM delivers to device.

### 6.3 Analytics & Crash Reporting
- **Crashlytics:** Firebase Crashlytics (Free, catches Dart stack traces).
- **Analytics:** Firebase Analytics or Mixpanel (to track the "North Star Metric": Completed Bookings).

### 6.4 CI/CD (Continuous Integration / Deployment)
- **Tool:** **Codemagic** or **GitHub Actions**.
- **Flow:** 
  1. Push to `main` branch.
  2. CI runs `flutter analyze` and `flutter test`.
  3. CI builds Android `.aab` (App Bundle).
  4. CI uploads to Google Play Console (Internal Testing track).

---

## 7. Rejected Alternatives (The "Why Not")

| Technology | Why we rejected it for v2 |
|---|---|
| **React Native** | JS bridge overhead, lack of strict typing caused bugs in v1, fragmented UI across Android OEMs. |
| **Firebase (Firestore)** | NoSQL is terrible for complex marketplace relations (bookings ↔ payouts ↔ reviews). Lack of RLS makes security hard. |
| **Node.js / Express** | Requires managing servers, scaling, PM2, Docker. Supabase Edge Functions are serverless and scale to zero. |
| **Stripe** | Poor UPI support in India compared to Razorpay. High failure rates on local Indian debit cards. |
| **Redux / Bloc** | Redux is too much boilerplate. Bloc is good, but Riverpod is more modern, compile-safe, and easier to read for a solo/small team. |
| **Native Android (Kotlin)** | We eventually want an iOS app. Flutter gives us iOS for free later without rewriting the UI. |

---

## 8. Environment & Secrets Management

Secrets are strictly compartmentalized to prevent leaks.

| Secret | Where it lives | Who can see it |
|---|---|---|
| Supabase Anon Key | Flutter `.env` | Public (safe, protected by RLS) |
| Supabase Service Role Key | Supabase Edge Functions | Server only (can bypass RLS) |
| Razorpay Key ID | Flutter `.env` | Public (safe, required for checkout) |
| Razorpay Key Secret | Supabase Edge Functions | Server only (creates orders) |
| Razorpay Webhook Secret | Supabase Edge Functions | Server only (verifies webhooks) |
| FCM Server Key | Supabase Edge Functions | Server only (sends pushes) |
| Cloudflare API Token | GitHub Actions / CI | CI/CD pipeline only |

