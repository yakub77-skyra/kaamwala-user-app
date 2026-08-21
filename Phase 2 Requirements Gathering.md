# KaamWala v2 — Phase 2: Product Requirements Document (PRD)

> **Document Type:** PRD + SRS (Product Requirements Document / Software Requirements Specification)
> **Version:** 2.0.0
> **Date:** 2026
> **Author:** yakubpasha123
> **Status:** Draft — Ready for Review
> **Previous Doc:** Phase 1: Idea & Validation ✅

---

## Table of Contents

1. [Product Vision & Goals](#1-product-vision--goals)
2. [User Roles](#2-user-roles)
3. [Full Feature List — MVP vs Future](#3-full-feature-list--mvp-vs-future)
4. [User Stories](#4-user-stories)
5. [Functional Requirements](#5-functional-requirements)
6. [Non-Functional Requirements](#6-non-functional-requirements)
7. [Out of Scope (Explicitly Excluded)](#7-out-of-scope-explicitly-excluded)
8. [Tech Stack Decision](#8-tech-stack-decision)
9. [Success Metrics](#9-success-metrics)
10. [Glossary](#10-glossary)

---

## 1. Product Vision & Goals

### One-Liner

> **"Find a verified worker in 30 seconds. Pay by UPI. Done."**

### Three Pillars

| Pillar | Meaning | Delivered By |
|---|---|---|
| **Trust** | Aadhar-verified workers, real reviews, portfolio proof | Verification badge, review system, work photos |
| **Speed** | Find a worker in 30 seconds, book in 3 taps | Location-based search, one-tap booking |
| **Fair Pay** | Workers keep 90% of earnings, paid same day | Razorpay X direct payout, 10% commission only |

### Business Model

| Revenue Stream | Detail |
|---|---|
| **Client convenience fee** | Flat ₹20 added to every booking (client pays) |
| **Worker commission** | 10% of job value deducted server-side (worker pays) |
| **Example** | Job = ₹500. Client pays ₹520 (₹500 + ₹20 fee). Worker receives ₹450 (₹500 − 10%). Platform earns ₹70. |

### Launch Strategy

| Parameter | Decision |
|---|---|
| Launch city | **ONE city only** (decided after Phase 1 validation interviews) |
| Categories at launch | **4 categories** (Plumber, Electrician, Painter, Carpenter) — not all 12 |
| Worker supply target | 50 verified workers before opening to clients |
| Platform | Android first (iOS later) |

### Key Lessons from v1 Applied

| v1 Mistake | v2 Fix |
|---|---|
| Dual-role switching | No role toggle. Workers apply separately. |
| Social feed (likes, follows, posts) | Removed from MVP. Portfolio on profile instead. |
| 3-tier booking fees (₹49/₹99/₹199) | Flat ₹20 convenience fee. Simple. |
| 8-step worker onboarding | 3 steps max. |
| Digital bills + agreements | Removed from MVP. |
| Wallet with ₹100 minimum | Direct UPI/bank payout. No wallet. |
| 12 categories × 8 sub-skills | 4 categories at launch. Sub-skills hidden. |
| JavaScript (no types) | Dart (compiled, typed, null-safe). |

---

## 2. User Roles

### Role Definitions

| Role | Description | How They Join |
|---|---|---|
| **Client** | A person who needs a home service (plumbing, electrical, etc.) | Signs up with phone OTP. Default role. |
| **Worker** | A skilled blue-collar worker who provides services | Signs up with phone OTP. Applies as a partner. Goes through verification. Approved by admin. |
| **Admin** | KaamWala team member (you) | Internal access only. Not in the mobile app. Web dashboard or Supabase Studio. |

### Role Rules (v2 — NOT like v1)

- ❌ **NO role switching.** A client cannot become a worker via a toggle.
- ❌ **NO dual-role.** One phone number = one role.
- ✅ **Worker application is a separate flow.** A client who wants to become a worker must log out and sign up as a worker (or contact support).
- ✅ **Workers are partners, not users.** They have a simpler, Hindi-first interface.

---

## 3. Full Feature List — MVP vs Future

### 🔴 MVP (v2.0) — "Ship This or Don't Ship at All"

> **Rule:** If a feature doesn't directly help a client find a worker OR help a worker get paid, it's NOT in MVP.

#### Client Features (MVP)

| # | Feature | Description | Priority |
|---|---|---|---|
| C1 | Phone OTP Login | Sign up / sign in with phone number + SMS OTP. No email, no Google for MVP. | P0 |
| C2 | Location Detection | Auto-detect city via GPS. Manual city fallback. | P0 |
| C3 | Category Selection | Browse 4 service categories (Plumber, Electrician, Painter, Carpenter) with icons. | P0 |
| C4 | Worker Search | Search workers by category + proximity. Sorted by rating. | P0 |
| C5 | Worker Profile | View worker: photo, name, rating, review count, price range, availability, Aadhar badge, portfolio photos (max 5), skills. | P0 |
| C6 | Book a Worker | Single-screen booking: pick worker, describe work (text), pick date, pick time slot. No tiers. No multi-step wizard. | P0 |
| C7 | Pay Booking Fee | Pay flat ₹20 convenience fee via Razorpay (UPI only for MVP). | P0 |
| C8 | Booking Status | Track booking: Pending → Accepted → In Progress → Completed / Cancelled. | P0 |
| C9 | Chat with Worker | Real-time text chat. No images, no location, no bills in MVP. | P0 |
| C10 | My Bookings | List of all bookings with status. Tap to view details. | P0 |
| C11 | Rate & Review | After completion: star rating (1-5) + text review. No photo upload in MVP. | P0 |
| C12 | Notifications | Push notifications: booking accepted, worker arriving, job completed. | P1 |
| C13 | Booking History | View past completed bookings. | P1 |
| C14 | Cancel Booking | Cancel before worker accepts. 100% refund of ₹20 fee. | P1 |

#### Worker Features (MVP)

| # | Feature | Description | Priority |
|---|---|---|---|
| W1 | Worker Registration | 3-step onboarding: (1) Phone OTP, (2) Name + Category + City, (3) Aadhar photo upload. | P0 |
| W2 | Profile Under Review | After registration, show "Under Review" screen. Worker cannot accept jobs until approved. | P0 |
| W3 | Worker Dashboard | Simple home: availability toggle (ON/OFF), today's jobs count, earnings today. Hindi-first UI. | P0 |
| W4 | Job Requests | View incoming booking requests. Show: client name, work description, date, time, location, estimated amount. | P0 |
| W5 | Accept / Decline Job | One-tap accept or decline. Push notification sent to client. | P0 |
| W6 | Update Job Status | Worker marks: Started Travel → Arrived → Work In Progress → Completed. | P0 |
| W7 | Earnings View | Total earned, this week, this month. List of completed jobs with amounts. | P0 |
| W8 | Receive Payment | Payment released to worker's UPI/bank after client confirms completion. No wallet. | P0 |
| W9 | Payment Setup | Worker enters UPI ID (validated) OR bank details (account + IFSC). One-time setup. | P0 |
| W10 | Push Notifications | New job request, payment received. | P1 |
| W11 | Edit Profile | Update name, photo, skills, price range, working hours. | P1 |

#### Admin Features (MVP)

| # | Feature | Description | Priority |
|---|---|---|---|
| A1 | Worker Approval | View pending worker applications. Verify Aadhar photo. Approve or Reject. | P0 |
| A2 | Booking Monitor | View all bookings, statuses, payments. | P1 |
| A3 | Basic Config | Set commission rate, convenience fee amount. | P1 |

#### Backend / Infrastructure (MVP)

| # | Feature | Description | Priority |
|---|---|---|---|
| B1 | Supabase Auth | Phone OTP authentication. | P0 |
| B2 | PostgreSQL + RLS | Database with Row Level Security. | P0 |
| B3 | Razorpay Orders | Create order → Checkout → Verify payment. | P0 |
| B4 | Razorpay X Payouts | Release payment to worker's UPI/bank. | P0 |
| B5 | Cloudflare Proxy | Reverse proxy to bypass Jio/Airtel DNS blocks. | P0 |
| B6 | Supabase Storage | Store profile photos, Aadhar scans, portfolio images. | P0 |
| B7 | Supabase Realtime | Real-time chat + booking status updates. | P0 |
| B8 | Push Notifications | Expo Push API for remote notifications. | P1 |
| B9 | Edge Functions | create-order, verify-payment, release-payout, approve-worker. | P0 |

---

### 🟡 v2.1 — "After MVP Ships and Gets 100 Users"

| # | Feature | Description |
|---|---|---|
| F1 | Portfolio Gallery | Workers upload up to 10 work photos. Displayed on profile. |
| F2 | Review Photos | Clients can attach 1-2 photos to reviews. |
| F3 | Saved Addresses | Client saves home/office addresses for faster booking. |
| F4 | Chat Images | Send photos in chat (e.g., show the broken pipe). |
| F5 | Chat Location | Share GPS location in chat. |
| F6 | Multiple Categories | Expand from 4 to 12 categories. |
| F7 | Search Filters | Filter by price range, availability, minimum rating. |
| F8 | Worker Working Hours | Worker sets available days + time slots. |
| F9 | Repeat Booking | Client can rebook a previous worker in 2 taps. |
| F10 | Hindi + English | Full i18n support (Hindi default for workers, Hinglish for clients). |
| F11 | Dispute Raising | Client or worker can raise a dispute. Basic admin resolution. |
| F12 | Worker Availability Calendar | Worker blocks dates when unavailable. |

### 🟢 v2.2+ — "When You Have 1,000+ Users"

| # | Feature | Description |
|---|---|---|
| G1 | Map-Based Discovery | See workers on a map. Distance-based sorting. |
| G2 | Admin Dashboard (Web) | Full web admin panel (worker approval, disputes, analytics, config). |
| G3 | In-App Calling | Voice call between client and worker (Twilio/Agora). |
| G4 | Worker Certification | Badge system: "Trained", "Background Checked", "Top Rated". |
| G5 | Referral System | Client refers friend → both get ₹50 credit. Worker refers worker → bonus. |
| G6 | Recurring Bookings | Schedule weekly/monthly service (e.g., monthly cleaning). |
| G7 | Bills & Invoices | Generate PDF bills for high-value jobs (₹5,000+). |
| G8 | Agreements | Digital work agreements with e-signatures for large projects. |
| G9 | Video Portfolio | Workers upload short videos of their work. |
| G10 | Advanced Analytics | Revenue tracking, worker retention, client LTV. |
| G11 | Multi-City Expansion | Expand to 9 cities. |
| G12 | iOS App | iOS build via Flutter (same codebase). |

### 🔵 v3.0 — "Someday / Only If Validated"

| # | Feature | Description |
|---|---|---|
| H1 | Social Feed | Workers post work updates. Clients follow workers. (Only if users demand it.) |
| H2 | Escrow Payments | Hold payment until both sides confirm. |
| H3 | AI Price Estimation | Suggest fair price based on job description. |
| H4 | Worker Loans / Credit | Financial services for workers. |
| H5 | Multi-Language (8+) | Tamil, Telugu, Bengali, Marathi, Gujarati, Kannada, Malayalam, Punjabi. |

---

## 4. User Stories

### Client Stories

| ID | User Story | Acceptance Criteria | MVP? |
|---|---|---|---|
| CS-01 | As a **client**, I want to **sign up with my phone number**, so that **I can start using the app without remembering a password.** | Phone OTP sent within 5 seconds. OTP expiry 5 minutes. 3 resend attempts max. | ✅ |
| CS-02 | As a **client**, I want to **see service categories on the home screen**, so that **I can quickly pick the type of worker I need.** | 4 categories visible with icons. Tapping opens worker list. | ✅ |
| CS-03 | As a **client**, I want to **see nearby workers sorted by rating**, so that **I can pick the best-rated one close to me.** | Workers sorted by rating (desc). Distance shown in km. Max 50 workers per page. | ✅ |
| CS-04 | As a **client**, I want to **see a worker's Aadhar verification badge**, so that **I trust they are a real person.** | Green "✅ Verified" badge shown if `aadhar_verified = true`. Red "⚠️ Unverified" if false. | ✅ |
| CS-05 | As a **client**, I want to **see a worker's portfolio photos**, so that **I can judge their work quality before booking.** | Up to 5 portfolio photos displayed in a horizontal scroll. | ✅ |
| CS-06 | As a **client**, I want to **book a worker in 3 taps**, so that **I don't waste time on long forms.** | Tap worker → Tap "Book" → Describe work + pick date/time → Tap "Pay ₹20". Done. | ✅ |
| CS-07 | As a **client**, I want to **pay the booking fee via UPI**, so that **I don't need to carry cash.** | Razorpay checkout opens. GPay/PhonePe/Paytm shortcuts shown. Payment completes in <30 seconds. | ✅ |
| CS-08 | As a **client**, I want to **know when the worker accepts my booking**, so that **I don't have to keep checking the app.** | Push notification within 5 seconds of worker accepting. Booking status changes to "Accepted". | ✅ |
| CS-09 | As a **client**, I want to **chat with the worker before they arrive**, so that **I can explain the problem in detail.** | Real-time text chat. Messages appear instantly. Chat linked to booking. | ✅ |
| CS-10 | As a **client**, I want to **track the booking status**, so that **I know what's happening.** | Status timeline: Pending → Accepted → In Progress → Completed. Visual indicator on booking card. | ✅ |
| CS-11 | As a **client**, I want to **rate and review the worker after the job**, so that **other clients can make informed decisions.** | After completion, prompt to rate (1-5 stars) + write review (max 500 chars). | ✅ |
| CS-12 | As a **client**, I want to **cancel a booking before the worker accepts**, so that **I get a full refund if I change my mind.** | Cancel button visible only in "Pending" status. ₹20 refunded via Razorpay refund API. | ✅ |
| CS-13 | As a **client**, I want to **see my booking history**, so that **I can rebook a good worker later.** | List of past bookings sorted by date (desc). Tap to view details. | ✅ |
| CS-14 | As a **client**, I want to **save my home address**, so that **I don't type it every time.** | Add/edit/delete addresses. Select during booking. | ❌ v2.1 |
| CS-15 | As a **client**, I want to **send a photo of the broken item in chat**, so that **the worker knows what tools to bring.** | Image picker in chat. Compressed before upload. Max 5MB. | ❌ v2.1 |
| CS-16 | As a **client**, I want to **filter workers by price and availability**, so that **I find someone within my budget.** | Filter bottom sheet: price range slider, available today toggle, min rating. | ❌ v2.1 |

### Worker Stories

| ID | User Story | Acceptance Criteria | MVP? |
|---|---|---|---|
| WS-01 | As a **worker**, I want to **register with just my phone number, name, and Aadhar photo**, so that **I can start getting work without filling long forms.** | 3 steps. Total time < 3 minutes. Hindi labels. Big buttons. | ✅ |
| WS-02 | As a **worker**, I want to **know when my profile is approved**, so that **I can start accepting jobs.** | Push notification on approval. "Under Review" screen disappears. Dashboard unlocks. | ✅ |
| WS-03 | As a **worker**, I want to **toggle my availability ON/OFF**, so that **I only get job requests when I'm free.** | Big toggle on dashboard. When OFF, no new job requests shown. | ✅ |
| WS-04 | As a **worker**, I want to **see incoming job requests with all details**, so that **I can decide whether to accept.** | Show: client name, work description, date, time, area, estimated amount. | ✅ |
| WS-05 | As a **worker**, I want to **accept a job with one tap**, so that **I don't lose the job to another worker.** | "Accept" button. Booking status → Accepted. Client notified. | ✅ |
| WS-06 | As a **worker**, I want to **decline a job without penalty**, so that **I can skip jobs I can't do.** | "Decline" button. Booking goes back to client as "Declined". Client notified. No penalty in MVP. | ✅ |
| WS-07 | As a **worker**, I want to **update the job status as I work**, so that **the client knows I'm on the way and working.** | Status buttons: "Started Travel" → "Arrived" → "Working" → "Completed". | ✅ |
| WS-08 | As a **worker**, I want to **see my earnings clearly**, so that **I know how much I've made.** | Total earned, this week, this month. List of completed jobs with amounts. Hindi numbers. | ✅ |
| WS-09 | As a **worker**, I want to **receive payment directly in my UPI/bank**, so that **I get money the same day.** | Razorpay X payout. Money in UPI within 24 hours. No wallet. No minimum withdrawal. | ✅ |
| WS-10 | As a **worker**, I want to **set my UPI ID once**, so that **I don't enter bank details every time.** | One-time setup. UPI format validated (name@upi). Stored securely. | ✅ |
| WS-11 | As a **worker**, I want to **get a push notification for new jobs**, so that **I respond quickly.** | Push notification: "🔔 New job! {client} needs {category} in {area}. ₹{amount}". | ✅ |
| WS-12 | As a **worker**, I want to **edit my profile and price**, so that **I can update my information.** | Edit name, photo, skills, price range. Changes reflect immediately. | ✅ |
| WS-13 | As a **worker**, I want to **set my working hours**, so that **I only get jobs during my available time.** | Day picker + time range. Jobs outside hours not shown. | ❌ v2.1 |
| WS-14 | As a **worker**, I want to **upload photos of my completed work**, so that **clients can see my quality.** | Upload up to 10 photos. Shown on profile. Compressed automatically. | ❌ v2.1 |

### Admin Stories

| ID | User Story | Acceptance Criteria | MVP? |
|---|---|---|---|
| AS-01 | As an **admin**, I want to **approve or reject worker applications**, so that **only verified workers are on the platform.** | View Aadhar photo, name, category. Approve → worker gets notification. Reject → worker gets reason. | ✅ |
| AS-02 | As an **admin**, I want to **see all bookings and their statuses**, so that **I can monitor the platform.** | Table view: booking ref, client, worker, status, amount, date. Filter by status. | ✅ |
| AS-03 | As an **admin**, I want to **change the commission rate and convenience fee**, so that **I can adjust pricing without a code deploy.** | Update in database config table. Reflected in Edge Functions. | ✅ |
| AS-04 | As an **admin**, I want to **resolve disputes between clients and workers**, so that **the platform stays trustworthy.** | Dispute queue. View evidence. Issue refund / penalty / dismiss. | ❌ v2.1 |
| AS-05 | As an **admin**, I want to **see revenue and booking analytics**, so that **I can make business decisions.** | Dashboard: total bookings, revenue, commission earned, active workers, active clients. | ❌ v2.2 |

---

## 5. Functional Requirements

### 5.1 Authentication

| ID | Requirement | Detail |
|---|---|---|
| FR-AUTH-01 | Phone OTP login | Supabase Auth Phone OTP. OTP valid for 5 minutes. Max 3 resends per hour. |
| FR-AUTH-02 | No email/password in MVP | Email and Google OAuth removed for MVP simplicity. |
| FR-AUTH-03 | Session persistence | JWT stored securely. Auto-refresh on app foreground. |
| FR-AUTH-04 | Logout | Clear session, clear local data, navigate to login. |
| FR-AUTH-05 | Role determination | On signup, user picks "I need a worker" (Client) or "I am a worker" (Worker). Cannot change later in MVP. |

### 5.2 Client — Discovery & Booking

| ID | Requirement | Detail |
|---|---|---|
| FR-CLIENT-01 | Category browsing | Home screen shows 4 categories with icons. Tap → worker list. |
| FR-CLIENT-02 | Worker search | Filter by category. Sort by rating (default), distance, price. |
| FR-CLIENT-03 | Worker profile | Display: photo, name, category, rating (avg), review count, price range, availability, Aadhar badge, portfolio (max 5 photos), skills list. |
| FR-CLIENT-04 | Booking creation | Fields: work description (text, max 500 chars), date, time slot, address (text). Auto-generate booking reference. |
| FR-CLIENT-05 | Booking fee payment | Flat ₹20 via Razorpay. UPI only in MVP. Payment verified server-side. |
| FR-CLIENT-06 | Booking status tracking | Statuses: pending → accepted → in_progress → completed / cancelled / declined. |
| FR-CLIENT-07 | Booking cancellation | Only in "pending" status. 100% refund of ₹20. |
| FR-CLIENT-08 | Rating & review | Post-completion: 1-5 stars + text (max 500 chars). One review per booking. |

### 5.3 Worker — Jobs & Earnings

| ID | Requirement | Detail |
|---|---|---|
| FR-WORKER-01 | 3-step registration | Step 1: Phone OTP. Step 2: Name + Category + City. Step 3: Aadhar photo (front + back). |
| FR-WORKER-02 | Profile approval gate | Worker cannot see job requests until admin approves. |
| FR-WORKER-03 | Availability toggle | Boolean flag on worker profile. When OFF, excluded from search results. |
| FR-WORKER-04 | Job request list | Show bookings where `worker_id = current_worker` AND `status = pending`. |
| FR-WORKER-05 | Accept job | Set booking status to `accepted`. Notify client. |
| FR-WORKER-06 | Decline job | Set booking status to `declined`. Notify client. Client can rebook another worker. |
| FR-WORKER-07 | Job status updates | Worker can set: `traveling`, `arrived`, `in_progress`, `completed`. |
| FR-WORKER-08 | Earnings calculation | Per completed booking: `job_amount - (job_amount × commission_rate)`. |
| FR-WORKER-09 | Payment release | After client confirms completion, trigger Razorpay X payout to worker's UPI/bank. |
| FR-WORKER-10 | Payment setup | Worker enters UPI ID (validated: `^[a-zA-Z0-9._-]+@[a-zA-Z]{2,}$`) OR bank details (account + IFSC validated). |

### 5.4 Chat

| ID | Requirement | Detail |
|---|---|---|
| FR-CHAT-01 | Text-only chat in MVP | No images, no location, no bill sharing. Text only. |
| FR-CHAT-02 | Real-time delivery | Supabase Realtime subscription on `chat_messages` table. |
| FR-CHAT-03 | Chat per booking | One chat thread per booking. Chat ID = booking ID. |
| FR-CHAT-04 | Message history | Load last 50 messages. Scroll up to load more. |
| FR-CHAT-05 | Read receipts | Single check (sent) → Double check (delivered). No "read" in MVP. |

### 5.5 Payments

| ID | Requirement | Detail |
|---|---|---|
| FR-PAY-01 | Order creation | Edge Function `create-order`: validates booking, calculates amount server-side, creates Razorpay order. |
| FR-PAY-02 | Payment verification | Webhook `verify-payment`: HMAC-SHA256 signature check. Update order + booking status. |
| FR-PAY-03 | Payout release | Edge Function `release-payout`: check order is PAID, check no double-payout, initiate Razorpay X payout. |
| FR-PAY-04 | Commission deduction | Server-side only. `commission = job_amount × 0.10`. Never calculated on client. |
| FR-PAY-05 | Convenience fee | Flat ₹20 added to client payment. Configurable in `platform_config` table. |
| FR-PAY-06 | Refund processing | On cancellation (pending status): auto-refund ₹20 via Razorpay Refund API. |
| FR-PAY-07 | No mock payments in production | Simulated payments only in `__DEV__` mode. Blocked in release builds. |

### 5.6 Notifications

| ID | Requirement | Detail |
|---|---|---|
| FR-NOTIF-01 | Push token registration | On login, register Expo push token in `push_tokens` table. |
| FR-NOTIF-02 | New booking → Worker | "🔔 New Job! {client} needs {category} in {area}. ₹{amount}" |
| FR-NOTIF-03 | Booking accepted → Client | "✅ {worker} accepted your booking!" |
| FR-NOTIF-04 | Booking declined → Client | "❌ {worker} declined. Try another worker." |
| FR-NOTIF-05 | Job completed → Client | "🎉 Job completed! Please rate {worker}." |
| FR-NOTIF-06 | Payment received → Worker | "💰 ₹{amount} sent to your UPI!" |
| FR-NOTIF-07 | Profile approved → Worker | "🎉 Your profile is approved! Start accepting jobs." |

### 5.7 Admin

| ID | Requirement | Detail |
|---|---|---|
| FR-ADMIN-01 | Worker approval | Admin views pending workers. Sees Aadhar photo, name, category. Approve/Reject with reason. |
| FR-ADMIN-02 | Booking monitor | View all bookings. Filter by status, date range, city. |
| FR-ADMIN-03 | Platform config | Update commission rate, convenience fee. Stored in `platform_config` table. |
| FR-ADMIN-04 | Admin access method | MVP: Supabase Studio (database GUI) + Edge Function triggers. No custom admin UI. |

---

## 6. Non-Functional Requirements

### 6.1 Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-PERF-01 | App cold start | < 3 seconds on a ₹10,000 Android phone (4GB RAM) |
| NFR-PERF-02 | Worker list load | < 2 seconds for first page (10 workers) |
| NFR-PERF-03 | Booking creation | < 1 second from tap to confirmation |
| NFR-PERF-04 | Chat message delivery | < 500ms from send to receive (real-time) |
| NFR-PERF-05 | Payment processing | < 10 seconds from tap to Razorpay checkout |
| NFR-PERF-06 | Image loading | Portfolio images lazy-loaded. Compressed to < 150KB each. |
| NFR-PERF-07 | Offline resilience | Worker list cached locally. Shows cached data on network failure with "offline" banner. |

### 6.2 App Size & Resource

| ID | Requirement | Target |
|---|---|---|
| NFR-SIZE-01 | APK size | < 20MB (critical for budget Android phones with limited storage) |
| NFR-SIZE-02 | RAM usage | < 150MB during normal usage |
| NFR-SIZE-03 | Battery | No background services draining battery. Push notifications only. |
| NFR-SIZE-04 | Data usage | < 5MB per 10-minute session. Images compressed. No auto-play media. |

### 6.3 Security

| ID | Requirement | Detail |
|---|---|---|
| NFR-SEC-01 | Row Level Security | Every Supabase table has RLS enabled. Users access only their own data. |
| NFR-SEC-02 | Server-side calculations | Commission, fees, totals calculated ONLY in Edge Functions. Never on client. |
| NFR-SEC-03 | Payment signature verification | HMAC-SHA256 verification on all Razorpay webhooks. Reject unsigned requests. |
| NFR-SEC-04 | No secret keys on client | Razorpay secret key, Supabase service key NEVER in mobile app. Only in Edge Functions. |
| NFR-SEC-05 | Aadhar storage | Aadhar images stored in PRIVATE bucket. Only admin can view. Never exposed to clients. |
| NFR-SEC-06 | Input sanitization | All text inputs sanitized before database write. Prevent SQL injection via PostgREST. |
| NFR-SEC-07 | Rate limiting | OTP: max 3 resends/hour. Booking: max 5 active bookings per client. Chat: max 100 messages/minute. |
| NFR-SEC-08 | JWT expiration | Access tokens expire in 1 hour. Refresh tokens rotate. |
| NFR-SEC-09 | Cloudflare proxy | All Supabase requests routed through Cloudflare Worker to bypass ISP DNS blocks. |
| NFR-SEC-10 | Double-payout prevention | `release-payout` checks order status is `PAID` before releasing. Prevents duplicate payouts. |

### 6.4 Scalability

| ID | Requirement | Target |
|---|---|---|
| NFR-SCAL-01 | Concurrent users | Support 500 concurrent users at launch. Scale to 10,000 without code changes. |
| NFR-SCAL-02 | Database indexing | Indexes on: `bookings.worker_id`, `bookings.status`, `bookings.created_at`, `workers.category`, `workers.city`, `reviews.worker_id`. |
| NFR-SCAL-03 | Pagination | All list endpoints paginated. Default 10 items/page. Max 50. Cursor-based for real-time data. |
| NFR-SCAL-04 | Image CDN | Supabase Storage serves images via CDN. Compressed variants (thumbnail + full). |

### 6.5 Usability

| ID | Requirement | Detail |
|---|---|---|
| NFR-USE-01 | Hindi-first for workers | Worker UI defaults to Hindi. All labels, buttons, notifications in Hindi. |
| NFR-USE-02 | Hinglish for clients | Client UI in Hinglish (Hindi + English mix). E.g., "Book karo", "Payment karo". |
| NFR-USE-03 | Large touch targets | All buttons minimum 48×48dp. Workers have rough hands, small screens. |
| NFR-USE-04 | Minimal text | Use icons > text wherever possible. Workers have low reading comfort. |
| NFR-USE-05 | Error messages in simple language | No technical jargon. "Payment failed. Try again." not "ERR_NETWORK_TIMEOUT". |
| NFR-USE-06 | Onboarding | First-time client sees 3-screen carousel explaining the app. Skippable. |
| NFR-USE-07 | Empty states | Every list has a friendly empty state with emoji + guidance. Not a blank white screen. |

### 6.6 Reliability

| ID | Requirement | Target |
|---|---|---|
| NFR-REL-01 | Uptime | 99.5% uptime (Supabase + Cloudflare SLA covers this). |
| NFR-REL-02 | Payment idempotency | Edge Functions are idempotent. Retrying a payment doesn't create duplicate orders. |
| NFR-REL-03 | Graceful degradation | If push notifications fail, in-app notifications still work. If real-time chat fails, polling fallback. |
| NFR-REL-04 | Data backup | Supabase automated daily backups. Point-in-time recovery enabled. |

### 6.7 Compliance

| ID | Requirement | Detail |
|---|---|---|
| NFR-COMP-01 | Aadhar data handling | Aadhar images encrypted at rest. Access logged. Compliant with Aadhar Act guidelines. No Aadhar number stored — only photo for visual verification. |
| NFR-COMP-02 | Payment compliance | PCI-DSS handled by Razorpay. App never touches card numbers. |
| NFR-COMP-03 | Data deletion | User can request account deletion. All personal data deleted within 30 days. |
| NFR-COMP-04 | Privacy policy | Privacy policy linked in app. Consent collected at signup. |

---

## 7. Out of Scope (Explicitly Excluded)

> **This section is as important as the feature list. If it's not in MVP, it's OUT. Period.**

| # | Feature | Why Excluded from MVP |
|---|---|---|
| 1 | Social feed (posts, likes, follows, comments) | Social media mechanics don't drive service bookings. Workers won't post consistently. Feed will look dead. |
| 2 | Digital bills & invoices | Overkill for ₹500 jobs. Only relevant for high-value work. Add in v2.2. |
| 3 | Digital agreements with e-signatures | Same as bills. Legal overhead for MVP. Add in v2.2. |
| 4 | Wallet system | Workers want money in bank TODAY. A wallet adds friction. Direct payout instead. |
| 5 | Role switching (client ↔ worker toggle) | Real users don't switch roles. Separate flows. |
| 6 | 12 service categories | Launch with 4. Validate demand. Add more when proven. |
| 7 | Sub-skills (8 per category) | Clients search "electrician", not "MCB/Fuse specialist". Sub-skills hidden in MVP. |
| 8 | Email/Google OAuth login | Phone OTP is India-first. Email/Google adds complexity. Add later if needed. |
| 9 | iOS app | Android first (95% of target market). iOS via Flutter later. |
| 10 | Web app | Mobile-only for MVP. |
| 11 | In-app calling | Chat is sufficient for MVP. Calling adds complexity (Twilio/Agora). |
| 12 | Multi-language (beyond Hindi + English) | Start with Hindi + English. Add regional languages when expanding to new cities. |
| 13 | Admin dashboard (custom UI) | Use Supabase Studio + Edge Functions for MVP admin. Build custom dashboard in v2.2. |
| 14 | Dispute resolution UI | Handle disputes manually in MVP. Build UI when volume justifies it. |
| 15 | Referral system | Growth feature. Not needed for MVP. |
| 16 | AI / ML features | No AI in MVP. Keep it simple. |
| 17 | Video content | No video upload, playback, or streaming in MVP. |
| 18 | Escrow payments | Direct payment is simpler. Escrow adds complexity. Consider in v3. |

---

## 8. Tech Stack Decision

### Final Stack for KaamWala v2

| Layer | Technology | Why |
|---|---|---|
| **Mobile Framework** | **Flutter (Dart)** | Compiled, typed, null-safe. Native ARM performance. One codebase for Android + iOS. |
| **State Management** | **Riverpod** | Typed, testable, no BuildContext dependency. Superior to Provider. |
| **Navigation** | **go_router** | Declarative routing. Deep link support. Type-safe. |
| **UI Components** | **Material 3 (built-in)** | No external UI library needed. Material 3 is beautiful out of the box. |
| **Backend** | **Supabase** | Auth + PostgreSQL + Storage + Realtime + Edge Functions. Proven in v1. |
| **Edge Functions** | **Deno (TypeScript)** | Server-side payment logic. Already proven in v1. |
| **Payments** | **Razorpay + Razorpay X** | Collection + Payouts. India-first. |
| **Proxy** | **Cloudflare Workers** | Bypass Jio/Airtel DNS blocks. Critical for India. |
| **Push Notifications** | **Firebase Cloud Messaging (FCM)** | More reliable than Expo Push for Android. Free tier sufficient. |
| **Image Compression** | **flutter_image_compress** | Compress before upload. WebP format. |
| **Local Storage** | **shared_preferences + sqflite** | Settings + offline cache. |
| **Maps** | **google_maps_flutter** | Worker location display (v2.1). Not in MVP. |
| **i18n** | **flutter_localizations + intl** | Hindi + English. |

### Architecture Pattern

┌─────────────────────────────────────────────────┐
│ PRESENTATION │
│ Screens (UI) ←→ Widgets ←→ Controllers/Riverpod │
├─────────────────────────────────────────────────┤
│ DOMAIN │
│ Use Cases / Business Logic / Entities │
├─────────────────────────────────────────────────┤
│ DATA │
│ Repositories ←→ Data Sources │
│ (SupabaseService, RazorpayService, LocalCache) │
├─────────────────────────────────────────────────┤
│ INFRASTRUCTURE │
│ Supabase (Auth, DB, Storage, Realtime) │
│ Razorpay (Orders, Webhooks, Payouts) │
│ Cloudflare Workers (Proxy) │
│ FCM (Push Notifications) │
└─────────────────────────────────────────────────┘


### Key Architecture Rules

| Rule | Detail |
|---|---|
| **Screens never call Supabase directly** | Screens talk to Controllers. Controllers talk to Repositories. Repositories talk to Supabase. |
| **Business logic in Edge Functions** | Payment calculations, commission, payouts — always server-side. |
| **Type safety everywhere** | Every API response mapped to a Dart model class. No `dynamic` or `Map<String, dynamic>` leaking into UI. |
| **Error handling at repository level** | Repositories catch exceptions and return typed results (Success/Failure). UI never sees raw exceptions. |
| **Offline-first for critical data** | Worker list cached locally. Shown immediately, refreshed in background. |

---

## 9. Success Metrics

### MVP Launch Metrics (First 30 Days)

| Metric | Target | How to Measure |
|---|---|---|
| Registered clients | 100+ | Supabase `users` table (role = client) |
| Registered workers (approved) | 50+ | Supabase `workers` table (approved = true) |
| Total bookings | 50+ | Supabase `bookings` table |
| Completed bookings | 30+ | `bookings` where status = completed |
| Payment success rate | > 90% | Razorpay dashboard |
| Average booking time | < 60 seconds | Analytics (time from app open to booking created) |
| Client retention (7-day) | > 30% | Clients who book again within 7 days |
| Worker acceptance rate | > 70% | Accepted / Total job requests |
| App crash rate | < 1% | Firebase Crashlytics |
| Average rating | > 4.0 | `reviews` table average |

### North Star Metric

> **Number of completed bookings per week.**
> This is the ONLY metric that matters. Everything else is vanity.

---

## 10. Glossary

| Term | Definition |
|---|---|
| **Client** | A person who books a worker for a home service. |
| **Worker** | A skilled blue-collar professional who provides services. |
| **Booking** | A service request created by a client for a specific worker. |
| **Booking Fee** | Flat ₹20 convenience fee paid by client at booking time. |
| **Commission** | 10% of job value deducted from worker's earnings by the platform. |
| **Job Value** | The total amount the client pays for the service (excluding booking fee). |
| **Payout** | Transfer of worker's earnings to their UPI/bank account. |
| **Aadhar Verification** | Visual verification of worker's Aadhar card photo by admin. |
| **RLS** | Row Level Security — Supabase feature that restricts database access per user. |
| **Edge Function** | Server-side function running on Supabase (Deno). Handles payment logic. |
| **Cloudflare Proxy** | Reverse proxy that routes Supabase requests through a custom domain to bypass ISP blocks. |
| **OTP** | One-Time Password sent via SMS for authentication. |
| **UPI** | Unified Payments Interface — India's digital payment system. |

---

## Appendix: MVP Screen List

### Client Screens (12 screens)

| # | Screen | Purpose |
|---|---|---|
| 1 | Splash | App loading + session check |
| 2 | Onboarding | 3-slide intro carousel |
| 3 | Login (Phone OTP) | Phone number + OTP verification |
| 4 | Role Selection | "I need a worker" or "I am a worker" |
| 5 | Home | Categories + nearby workers |
| 6 | Worker List | Search results for a category |
| 7 | Worker Profile | Full worker details + "Book Now" |
| 8 | Booking | Single-screen booking form |
| 9 | Payment | Razorpay checkout (₹20 fee) |
| 10 | My Bookings | Booking list with status |
| 11 | Chat | Real-time text chat with worker |
| 12 | Rate & Review | Post-completion rating |

### Worker Screens (8 screens)

| # | Screen | Purpose |
|---|---|---|
| 1 | Worker Registration (3 steps) | Phone → Details → Aadhar |
| 2 | Profile Under Review | Waiting for admin approval |
| 3 | Worker Dashboard | Availability toggle + stats |
| 4 | Job Requests | Incoming bookings list |
| 5 | Job Detail | Single booking detail + accept/decline |
| 6 | Active Job | Status update buttons |
| 7 | Earnings | Total + history |
| 8 | Payment Setup | UPI/bank one-time setup |

### Shared Screens (2 screens)

| # | Screen | Purpose |
|---|---|---|
| 1 | Settings | Profile, language, logout |
| 2 | Notifications | Push notification history |

**Total MVP screens: 22** (vs. v1's 35+ screens — 40% reduction)

---

*This PRD is the single source of truth for KaamWala v2 MVP. Any feature not listed here is NOT being built. Period.*

