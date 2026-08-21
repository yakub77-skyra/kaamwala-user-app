```markdown
# KaamWala v2 — Phase 3: Design

> **Document Type:** Design Specification (Wireframes + User Flows + ERD + System Architecture)
> **Version:** 2.0.0
> **Date:** 2026
> **Author:** yakubpasha123
> **Previous Docs:** Phase 1 (Validation) ✅ → Phase 2 (PRD) ✅
> **Tool Note:** All diagrams below are ASCII so they live inside this .md file. To make them visual, trace them in **Excalidraw** (free) or **draw.io** (free) — a reproduction guide is included at the end.

---

## Table of Contents

1. [Design System (Tokens)](#1-design-system-tokens)
2. [Wireframes — Client Screens](#2-wireframes--client-screens)
3. [Wireframes — Worker Screens](#3-wireframes--worker-screens)
4. [Wireframes — Shared Screens](#4-wireframes--shared-screens)
5. [User Flow Diagrams](#5-user-flow-diagrams)
6. [Navigation Architecture (go_router)](#6-navigation-architecture-go_router)
7. [Database Schema + ERD](#7-database-schema--erd)
8. [System Architecture Diagram](#8-system-architecture-diagram)
9. [Payment & Payout Sequence Diagram](#9-payment--payout-sequence-diagram)
10. [Excalidraw / draw.io Reproduction Guide](#10-excalidraw--drawio-reproduction-guide)

---

## 1. Design System (Tokens)

### 1.1 Brand Colors (carried from v1 — brand stays the same)

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#FF6B35` | Buttons, active tabs, highlights (brand orange) |
| `primaryDark` | `#FF4500` | Pressed states |
| `primaryLight` | `#FFF0E8` | Selected chips, soft backgrounds |
| `background` | `#FFF8F2` | Page background (warm cream) |
| `surface` | `#FFFFFF` | Cards, sheets |
| `dark` | `#1A1A2E` | Primary text |
| `muted` | `#7A7A9D` | Secondary text |
| `green` | `#22C55E` | Success, available, verified |
| `gold` | `#F59E0B` | Pending, in-progress |
| `red` | `#EF4444` | Error, danger, cancelled |
| `blue` | `#3B82F6` | Info, links |

### 1.2 Typography

| Element | Font | Weight | Size |
|---|---|---|---|
| App font (Latin) | Plus Jakarta Sans | 400–800 | — |
| App font (Hindi fallback) | Noto Sans Devanagari | 400–700 | — |
| Screen title | Plus Jakarta Sans | 700 | 22 |
| Card title | Plus Jakarta Sans | 600 | 16 |
| Body | Plus Jakarta Sans | 400 | 14 |
| Caption / meta | Plus Jakarta Sans | 400 | 12 |
| Big number (earnings) | Plus Jakarta Sans | 800 | 32 |
| Button label | Plus Jakarta Sans | 700 | 16 |

### 1.3 Shape & Spacing

| Token | Value |
|---|---|
| Card radius | 16 |
| Button radius | 12 |
| Chip radius | full (pill) |
| Card shadow | `0 2 8 rgba(26,26,46,0.08)` |
| Min touch target | 48 × 48 dp (critical for worker users) |
| Spacing scale | 4 / 8 / 12 / 16 / 24 / 32 |
| Bottom nav height | 64 |
| Primary button height | 52 |

### 1.4 UI Rules (learned from v1 mistakes)

| Rule | Detail |
|---|---|
| Icons > text | Worker UI uses icons + short Hindi words |
| One primary action per screen | One big orange button. No competing CTAs |
| No blank screens | Every list has skeleton + empty state with emoji |
| Errors in human language | "Payment failed. Try again." Never technical codes |
| Status color coding | green = good, gold = waiting, red = problem |

---

## 2. Wireframes — Client Screens

### C1 — Splash

```
┌───────────────────────────────┐
│                               │
│                               │
│             🔧                │
│          KaamWala             │
│        "काम वाला"             │
│                               │
│       ▓▓▓▓▓▓░░░░  (load)      │
│                               │
│                               │
└───────────────────────────────┘
Notes:
- Max 2s. Checks session token.
- Session valid  → jump to Home (client) or Dashboard (worker).
- No session    → Onboarding (first run) or Login.
```

### C2 — Onboarding (3 slides, skippable)

```
┌───────────────────────────────┐
│                        Skip   │
│                               │
│        [ illustration ]       │
│                               │
│   Find Verified Workers       │
│   Aadhar-checked plumbers &   │
│   electricians near you.      │
│                               │
│          ●  ○  ○              │
│                               │
│  ┌─────────────────────────┐  │
│  │          Next →         │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘
Slides:
 1. "Find Verified Workers"   (trust)
 2. "Book in 3 Taps"          (speed)
 3. "Pay Safely with UPI"     (fair pay)
```

### C3 — Login (Phone OTP)

```
┌───────────────────────────────┐
│  🔧 KaamWala                  │
│  Find verified workers        │
│                               │
│  Phone Number                 │
│  ┌────┬────────────────────┐  │
│  │ +91│ 98765 43210        │  │
│  └────┴────────────────────┘  │
│                               │
│  ┌─────────────────────────┐  │
│  │        Send OTP         │  │
│  └─────────────────────────┘  │
│                               │
│  ───────── OR ─────────       │
│                               │
│   I am a Worker → (sign up)   │
└───────────────────────────────┘

        │ after Send OTP
        ▼

┌───────────────────────────────┐
│  ←  Enter OTP                 │
│  Sent to +91 98765 43210      │
│                               │
│   ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐
│   │  │ │  │ │  │ │  │ │  │ │  │
│   └──┘ └──┘ └──┘ └──┘ └──┘ └──┘
│                               │
│  Resend in 00:30   (3 tries)  │
│  ┌─────────────────────────┐  │
│  │    Verify & Continue    │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘
Notes:
- OTP expires in 5 min. Max 3 resends/hour.
- No email / Google login in MVP.
```

### C4 — Role Selection (one-time, locked)

```
┌───────────────────────────────┐
│  Welcome! 🙏                  │
│  How will you use KaamWala?   │
│                               │
│  ┌─────────────────────────┐  │
│  │  🏠  I need a worker    │  │
│  │  Book plumbers,         │  │
│  │  electricians & more    │  │
│  └─────────────────────────┘  │
│                               │
│  ┌─────────────────────────┐  │
│  │  🔧  I am a worker      │  │
│  │  Get jobs near you &    │  │
│  │  earn money daily       │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘
Notes:
- Choice is FINAL in MVP. No role toggle anywhere.
- "I am a worker" → Worker Registration flow.
```

### C5 — Home

```
┌───────────────────────────────┐
│ 📍 Kharadi, Pune        🔔(2) │
│ Namaste, Rohit 👋             │
│ ┌───────────────────────────┐ │
│ │ 🔍 Search "electrician"   │ │
│ └───────────────────────────┘ │
│                               │
│ SERVICES                      │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
│  │ 🔧 │ │ ⚡ │ │ 🎨 │ │  │  │
│  │Plum│ │Elec│ │Pain│ │Carp│  │
│  └────┘ └────┘ └────┘ └────┘  │
│                               │
│ TOP RATED NEAR YOU   See all ›│
│ ┌───────────────────────────┐ │
│ │(👤) Ramesh Kumar   ⭐ 4.8  │ │
│ │  Electrician • 1.2 km    │ │
│ │ ✅ Verified   ₹300+       │ │
│ └───────────────────────────┘ │
│ ┌───────────────────────────┐ │
│ │(👤) Suresh Yadav   ⭐ 4.6  │ │
│ └───────────────────────────┘ │
│ ───────────────────────────── │
│  [🏠 Home] [🔍] [📋] []     │
└───────────────────────────────┘
Notes:
- Only 4 categories at launch.
- Worker cards show: photo, name, rating, distance, verified badge, price-from.
- Bottom nav: Home / Search / My Bookings / Profile.
```

### C6 — Worker List (Search Results)

```
┌───────────────────────────────┐
│ ←  Electricians • Pune    ⚙   │
│ ┌───────────────────────────┐ │
│ │ 🔍 Search by name         │ │
│ └───────────────────────────┘ │
│ Sort: [ Top Rated ▾ ]         │
│                               │
│ ┌───────────────────────────┐ │
│ │(👤) Ramesh Kumar    ⭐4.8  │ │
│ │ ✅ Verified   (120)       │ │
│ │ ⚡ 1.2 km • ₹300+    [Book]│ │
│ └───────────────────────────┘ │
│ ┌───────────────────────────┐ │
│ │(👤) Anil Verma     ⭐4.5   │ │
│ └───────────────────────────┘ │
│        (scroll = load more)   │
└───────────────────────────────┘
Notes:
- Default sort: rating desc. v2.1 adds filters.
- Pagination 10/page. Skeleton while loading.
- Offline → cached list + "offline" banner.
```

### C7 — Worker Profile

```
┌───────────────────────────────┐
│ ←                        ⤴    │
│          ( 👤 photo )         │
│        Ramesh Kumar           │
│     ⚡ Electrician • Pune     │
│     ⭐ 4.8  (120 reviews)     │
│     ✅ Aadhar Verified        │
│ ───────────────────────────── │
│  ₹300–₹800      🟢 Available  │
│ ───────────────────────────── │
│ WORK PHOTOS                   │
│  [img][img][img][img][img] ›  │
│                               │
│ ABOUT                         │
│  10 yrs experience. Fan,      │
│  wiring, MCB, inverter...     │
│ SKILLS                        │
│  [Wiring] [Fans] [MCB]        │
│                               │
│ REVIEWS (120)        See all ›│
│  "Very neat work."  ⭐⭐⭐⭐⭐   │
│ ┌───────────────────────────┐ │
│ │         Book Now          │ │
│ └───────────────────────────┘ │
└───────────────────────────────┘
Notes:
- Portfolio max 5 photos (MVP).
- No follow / favorite in MVP.
- Sticky "Book Now" CTA at bottom.
```

### C8 — Booking (single screen, 3 taps)

```
┌───────────────────────────────┐
│ ←  Book Ramesh Kumar          │
│ ───────────────────────────── │
│ What work do you need?        │
│ ┌───────────────────────────┐ │
│ │ Fan is not working...     │ │
│ │                           │ │
│ └───────────────────────────┘ │
│ When?                         │
│  [ Today ▾ ]   [ 10–12 ▾ ]    │
│ Where?                        │
│ ┌───────────────────────────┐ │
│ │ A-402, Kharadi...      📍 │ │
│ └───────────────────────────┘ │
│ ───────────────────────────── │
│  Job estimate      ₹300–₹800  │
│  Booking fee            ₹20   │
│ ┌───────────────────────────┐ │
│ │      Pay ₹20 & Book       │ │
│ └───────────────────────────┘ │
└───────────────────────────────┘
Notes:
- ONE screen. No wizard. No fee tiers.
- 📍 uses current GPS, editable text.
- Booking ref auto-generated: KW-2026-XXXX.
```

### C9 — Payment (Razorpay)

```
┌───────────────────────────────┐
│ ←  Payment                    │
│                               │
│   ┌───────────────────────┐   │
│   │  Booking #KW-2026-0148│   │
│   │  Booking Fee     ₹20  │   │
│   └───────────────────────┘   │
│                               │
│   Pay with                    │
│   [GPay] [PhonePe] [Paytm]    │
│   [ Other UPI ]               │
│   [ Card / NetBanking ]       │
│                               │
│   ┌───────────────────────┐   │
│   │        Pay ₹20        │   │
│   └───────────────────────┘   │
│                               │
│   Status: ◌ Creating order…   │
└───────────────────────────────┘
Notes:
- Tap opens native Razorpay checkout modal.
- Status line: Creating → Checkout → Processing → ✅ Success.
- UPI only highlighted; cards allowed via Razorpay.
```

### C10 — My Bookings + Booking Detail (Track)

```
┌───────────────────────────────┐
│ My Bookings                   │
│ [ Active ] [ Done ] [ All ]   │
│ ┌───────────────────────────┐ │
│ │ Ramesh Kumar   ⚡  🟡      │ │
│ │ #KW-0148 • Today 10 AM    │ │
│ │ Accepted                  │ │
│ │ [ 💬 Chat ]  [ Track › ]  │ │
│ └───────────────────────────┘ │
│ ┌───────────────────────────┐ │
│ │ Suresh Yadav   ✅ Done    │ │
│ │ [ ⭐ Rate & Review ]      │ │
│ └───────────────────────────┘ │
└───────────────────────────────┘
        │ tap "Track"
        ▼
┌───────────────────────────────┐
│ ←  #KW-2026-0148        💬    │
│  (👤) Ramesh Kumar  ⭐4.8     │
│ ───────────────────────────── │
│  ✅ Booking accepted          │
│  🟡 Started travel            │
│  ◌ Arrived                    │
│  ◌ Work in progress           │
│  ◌ Completed                  │
│ ───────────────────────────── │
│  Address: A-402, Kharadi      │
│  Work: Fan is not working     │
│ ┌───────────────────────────┐ │
│ │   Cancel (only if pending)│ │
│ └───────────────────────────┘ │
└───────────────────────────────┘
Notes:
- Status timeline updates via Realtime.
- Cancel visible ONLY while status = pending.
- After completed → "Rate & Review" button appears.
```

### C11 — Chat (text only in MVP)

```
┌───────────────────────────────┐
│ ←  Ramesh Kumar   🟢 online   │
│ ───────────────────────────── │
│                  Namaste sir, │
│                  I will come  │
│                  at 10 AM  ✓✓ │
│  Ok, please bring    ✓        │
│  tools                      │
│                               │
│                               │
│ ┌───────────────────────┬───┐ │
│ │ Type a message…       │ ➤ │ │
│ └───────────────────────┴───┘ │
└───────────────────────────────┘
Notes:
- Text only in MVP (no image/location/bill).
- ✓ sent, ✓✓ delivered.
- Realtime via Supabase channel on booking_id.
```

### C12 — Rate & Review

```
┌───────────────────────────────┐
│ ←  Rate your worker           │
│        ( 👤 ) Ramesh          │
│                               │
│      ☆   ☆   ☆   ☆   ☆        │
│     (tap stars to rate)       │
│                               │
│ ┌───────────────────────────┐ │
│ │ How was the work?         │ │
│ │                           │ │
│ └───────────────────────────┘ │
│  [On time] [Polite] [Neat]    │
│                               │
│ ┌───────────────────────────┐ │
│ │       Submit Review       │ │
│ └───────────────────────────┘ │
───────────────────────────────
Notes:
- 1 review per booking. Rating updates worker avg server-side.
- No photo upload in MVP (v2.1).
```

---

## 3. Wireframes — Worker Screens

> Worker UI is **Hindi-first**, big buttons, icons over text.

### W1 — Worker Registration (3 steps)

```
STEP 1/3                      STEP 2/3
┌───────────────────────────┐ ┌───────────────────────────┐
│ Worker Signup    ●○○      │ │ Worker Signup    ○●○      │
│ ───────────────────────── │ │ ───────────────────────── │
│ Your name                 │ │ What work do you do?      │
│ ┌───────────────────────┐ │ │                           │
│ │ Ramesh Kumar          │ │ │  [🔧 Plumber ] [⚡ Electric]│
│ └───────────────────────┘ │ │  [🎨 Painter ] [🪚 Carpentr]│
│ Your city                 │ │                           │
│  [ Pune ▾ ]  [Kharadi ▾]  │ │ Your starting price/day   │
│ ┌───────────────────────┐ │ │  [ ₹ 300 ]                │
│ │        Next →         │ │ │ ┌───────────────────────┐ │
│ └───────────────────────┘ │ │ │        Next →         │ │
└───────────────────────────┘ │ └───────────────────────┘ │
                              │ └───────────────────────────┘

STEP 3/3
┌───────────────────────────┐
│ Worker Signup    ○○●      │
│ ───────────────────────── │
│ Aadhar card photo         │
│ ┌──────────┬──────────┐   │
│ │ 📷 Front │ 📷 Back  │   │
│ └────────────────────┘   │
│ 🔒 Only our team sees this│
│ ┌───────────────────────┐ │
│ │  Submit for Approval  │ │
│ └───────────────────────┘ │
└───────────────────────────┘
Notes:
- Total time target < 3 minutes.
- Aadhar stored in PRIVATE bucket, admin-only.
```

### W2 — Profile Under Review

```
┌───────────────────────────────┐
│                               │
│             ⏳                │
│                               │
│     आपकी प्रोफ़ाइल जांच        │
│       के अधीन है              │
│   (Profile under review)      │
│                               │
│   We verify your Aadhar       │
│   within 24 hours.            │
│   You'll get a message when   │
│   approved. ✅                │
│                               │
└───────────────────────────────┘
Notes:
- Worker CANNOT see jobs until approved.
- Push notification on approval unlocks dashboard.
```

### W3 — Worker Dashboard (Hindi-first)

```
┌───────────────────────────────┐
│ नमस्ते, Ramesh 🙏        🔔(3) │
│ ┌───────────────────────────┐ │
│ │  काम के लिए उपलब्ध?        │ │
│ │  (Available for jobs)     │ │
│ │  [═══════ON        ] 🟢   │ │
│ └───────────────────────────┘ │
│ ┌───────────┐ ┌───────────┐   │
│ │ आज के काम │ │ आज की कमाई│   │
│ │    2      │ │   ₹900    │   │
│ └───────────┘ └───────────┘   │
│                               │
│ नए काम (2)                    │
│ ┌───────────────────────────┐ │
│ │ 🌀 Fan repair • 1.2 km    │ │
│ │ Today 10 AM  • ~₹300      │ │
│ │ [ Decline ]   [ ✅ Accept ]│ │
│ └───────────────────────────┘ │
│ ───────────────────────────── │
│  [🏠 Home] [💰] [👤]          │
└───────────────────────────────┘
Notes:
- Availability toggle = master switch. OFF hides worker from search.
- Accept/Decline directly on card (1 tap).
```

### W4 — Job Requests List

```
┌───────────────────────────────┐
│ ←  नए काम (New Jobs)     (3)  │
│ ┌───────────────────────────┐ │
│ │ 🌀 Fan repair             │ │
│ │ Rohit • Kharadi • 1.2 km  │ │
│ │ Today 10 AM   ~₹300       │ │
│ │ [ Decline ]   [ Accept ]  │ │
│ └───────────────────────────┘ │
│ ┌───────────────────────────┐ │
│ │ 💡 Wiring check           │ │
│ │ Priya • Viman Nagar 3 km  │ │
│ │ Tomorrow 2 PM ~₹500       │ │
│ │ [ Decline ]   [ Accept ]  │ │
│ └───────────────────────────┘ │
└───────────────────────────────┘
Notes:
- Only shows jobs where status = pending and worker = me.
- New job → push notification with amount in title.
```

### W5 — Job Detail

```
┌───────────────────────────────┐
│ ←  Job Detail                 │
│ ───────────────────────────── │
│  Client   Rohit Sharma        │
│  Work     Fan is not working  │
│  📍 A-402, Kharadi  (1.2 km)  │
│  📅 Today   🕙 10 AM – 12 PM  │
│ ───────────────────────────── │
│  Estimate        ₹300 – ₹800  │
│  You earn (90%)  ₹270 – ₹720  │
│ ───────────────────────────── │
│ ┌──────────────┬────────────┐ │
│ │   Decline    │ ✅ Accept  │ │
│ └──────────────┴────────────┘ │
└───────────────────────────────┘
Notes:
- "You earn" line builds trust (shows 10% cut transparently).
```

### W6 — Active Job (status updates)

```
┌───────────────────────────────┐
│ ←  Active Job           💬    │
│  (👤) Rohit Sharma            │
│  🌀 Fan is not working        │
│ ───────────────────────────── │
│   ✅  Started travel          │
│   🟡  Arrived                 │
│   ◌   Working                 │
│   ◌   Completed               │
│ ───────────────────────────── │
│ ┌───────────────────────────┐ │
│ │     ✅ I have Arrived     │ │
│ └───────────────────────────┘ │
└───────────────────────────────┘
Notes:
- One big button shows the NEXT status only.
- Sequence: traveling → arrived → in_progress → completed.
- "completed" triggers client confirmation prompt.
```

### W7 — Earnings

```
┌───────────────────────────────┐
│ कमाई (Earnings)               │
│ ┌───────────────────────────┐ │
│ │  इस महीने (This Month)    │ │
│ │        ₹12,400            │ │
│ │  This Week ₹3,200         │ │
│ └───────────────────────────┘ │
│ 💰 Paid to ramesh@ybl  ✅     │
│ ───────────────────────────── │
│ HISTORY                       │
│  🌀 Fan repair   +₹270  ✅    │
│  💡 Wiring       +₹720  ✅    │
│  🎨 Painting     +₹1,800 🟡   │
│ ───────────────────────────── │
│  [🏠] [💰 Earnings] [👤]      │
└───────────────────────────────┘
Notes:
- ✅ = paid to UPI, 🟡 = pending client confirmation.
- NO wallet. Money goes straight to UPI/bank.
```

### W8 — Payment Setup (one-time)

```
┌───────────────────────────────┐
│ ←  Payment Setup              │
│  Money will come here 👇      │
│                               │
│   (•) UPI      ( ) Bank       │
│                               │
│  UPI ID                       │
│  ┌─────────────────────────┐  │
│  │ ramesh@ybl              │  │
│  └─────────────────────────┘  │
│  ✅ UPI ID looks valid        │
│                               │
│  ┌─────────────────────────┐  │
│  │          Save           │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘
Notes:
- UPI regex: ^[a-zA-Z0-9._-]+@[a-zA-Z]{2,}$
- Bank mode shows: Account No + IFSC (validated) + Holder name.
```

---

## 4. Wireframes — Shared Screens

### S1 — Notifications

```
┌───────────────────────────────┐
│ ←  Notifications   [Mark all]│
│ ┌───────────────────────────┐ │
│ │ 🔔 New job! Fan repair    │ │
│ │    Kharadi • ₹300  • 2m   │ │
│ └───────────────────────────┘ │
│ ┌───────────────────────────┐ │
│ │ 💰 ₹270 sent to UPI  • 1h │ │
│ └───────────────────────────┘ │
└───────────────────────────────┘
```

### S2 — Settings / Profile

```
┌───────────────────────────────┐
│ ←  Profile & Settings         │
│  (👤) Rohit Sharma            │
│  +91 98765 43210              │
│ ───────────────────────────── │
│  🌐 Language   [ Hinglish ▾ ] │
│  🔔 Notifications      [ON ]  │
│  📍 My city      Kharadi, Pune│
│  🛟 Help & Support            │
│  📄 Privacy Policy            │
│  🚪 Sign Out                  │
│  v2.0.0                       │
└───────────────────────────────┘
Notes:
- NO role switch. NO wallet settings here for clients.
```

---

## 5. User Flow Diagrams

### 5.1 Client Happy Path

```
[Splash]
   │
   ├─(first run)─▶ [Onboarding 3 slides] ─▶ [Login: Phone]
   │                                            │
   └─(returning, session)──────────┐            ▼
                                   │        [OTP Verify]
                                   │            │
                                   │            ▼
                                   │      [Role Select] ──▶ "I need a worker"
                                   │            │
                                   ▼            ▼
                                 [ HOME ] ◀──────────────┐
                                   │                     │
                 ┌─────────────────┼──────────────┐      │
                 ▼                 ▼              ▼      │
            (category)         (search)      (bell)      │
                 │                 │              │      │
                 ▼                 ▼              ▼      │
            [Worker List] ◀────────┘        [Notifs]     │
                 │                                       │
                 ▼                                       │
           [Worker Profile]                              │
                 │ Book Now                              │
                 ▼                                       │
            [Booking Form]                               │
                 │ Pay ₹20                               │
                 ▼                                       │
        [Razorpay Checkout] ──fail──▶ retry              │
                 │ success                               │
                 ▼                                       │
          [Booking Success] ─────────────────────────────┤
                 │                                       │
                 ▼                                       │
            [My Bookings] ─▶ [Track Detail]              │
                 │                 │                     │
                 │                 ▼                     │
                 │              [Chat] ◀─ realtime ──┐   │
                 │                                   │   │
                 ▼ (status = completed)              │   │
           [Rate & Review] ──────────────────────────┴───┘
```

### 5.2 Worker Happy Path

```
[Splash] ▶ [Login] ▶ [Role Select] ──▶ "I am a worker"
                                          │
                                          ▼
                              [Reg Step 1: name/city]
                                          │
                                          ▼
                              [Reg Step 2: category/price]
                                          │
                                          ▼
                              [Reg Step 3: Aadhar photos]
                                          │ submit
                                          ▼
                              [Under Review ⏳] ─(admin approves + push)──┐
                                                                          ▼
                              ┌──────────────────────────── [Dashboard] ◀─┘
                              │                            (toggle ON)
                              │ new job push                    │
                              ▼                                 │
                         [Job Requests] ◀───────────────────────┤
                              │ tap job                         │
                              ▼                                 │
                         [Job Detail]                           │
                         ┌────┴─────┐                           │
                     decline      accept                        │
                         │          │                           │
                         ▼          ▼                           │
                   (back to    [Active Job]                     │
                    list)      traveling→arrived→working→done   │
                                          │ completed           │
                                          ▼                     │
                                 (client confirms)              │
                                          │                     │
                                          ▼                     │
                              [Payout → UPI] ─▶ [Earnings ✅] ──┘
```

### 5.3 Worker Approval Flow (Admin)

```
Worker submits Aadhar
        │
        ▼
 workers.approval_status = 'pending'
        │
        ▼
 Admin (Supabase Studio / admin trigger)
   ├─ Approve → status='approved' → push "🎉 Approved!" → Dashboard unlocks
   └─ Reject  → status='rejected' + reason → push "❌ + reason" → worker can re-upload
```

---

## 6. Navigation Architecture (go_router)

```
/                     → Splash (redirect logic)
/onboarding           → Onboarding
/login                → Phone entry
/login/otp            → OTP verify
/role                 → Role selection

CLIENT (shell with bottom nav)
/home                 → C5 Home            (tab 1)
/search               → C6 Worker List     (tab 2)
/bookings             → C10 My Bookings    (tab 3)
/profile              → S2 Settings        (tab 4)
/worker/:id           → C7 Worker Profile
/book/:workerId       → C8 Booking
/payment/:bookingId   → C9 Payment
/booking/:id          → C10b Track Detail
/chat/:bookingId      → C11 Chat
/rate/:bookingId      → C12 Rate & Review
/notifications        → S1 Notifications

WORKER (shell with bottom nav)
/w/home               → W3 Dashboard       (tab 1)
/w/earnings           → W7 Earnings        (tab 2)
/w/profile            → S2 Settings        (tab 3)
/w/register           → W1 Registration (3 steps)
/w/review             → W2 Under Review
/w/jobs               → W4 Job Requests
/w/job/:id            → W5 Job Detail
/w/active/:id         → W6 Active Job
/w/payment-setup      → W8 Payment Setup
/w/notifications      → S1 Notifications
```

Guards:
- `/w/*` requires role = worker AND (approved OR on `/w/register`, `/w/review`).
- `/home`, `/book*` require role = client.
- Unauthenticated → `/login`.

---

## 7. Database Schema + ERD

### 7.1 Tables (MVP — 11 tables, down from v1's 30+)

#### users

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | = auth.uid() |
| phone | text UNIQUE NOT NULL | login identifier |
| name | text | |
| role | text | 'client' \| 'worker' (locked) |
| city | text | |
| photo_url | text | |
| created_at | timestamptz | default now() |

#### workers

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK→users UNIQUE | |
| category | text | one of 4 at launch |
| city / area | text | |
| bio | text | |
| skills | text[] | |
| price_min / price_max | numeric | |
| rating_avg | numeric default 0 | updated by trigger on review insert |
| rating_count | int default 0 | |
| is_available | bool default false | master toggle |
| approval_status | text default 'pending' | pending / approved / rejected |
| rejection_reason | text | |
| aadhar_front_url | text | PRIVATE bucket path |
| aadhar_back_url | text | PRIVATE bucket path |
| portfolio_urls | text[] | max 5 in MVP |
| created_at | timestamptz | |

#### bookings

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| ref | text UNIQUE | KW-2026-XXXX |
| client_id | uuid FK→users | |
| worker_id | uuid FK→workers | |
| category | text | |
| description | text | max 500 chars |
| service_date | date | |
| time_slot | text | e.g. "10-12" |
| address | text | |
| status | text | pending / accepted / traveling / arrived / in_progress / completed / cancelled / declined |
| estimate_min / estimate_max | numeric | |
| booking_fee | numeric default 20 | flat |
| commission_rate | numeric default 0.10 | |
| commission_amount | numeric | computed server-side |
| worker_earning | numeric | computed server-side |
| client_confirmed | bool default false | gates payout |
| created_at / completed_at | timestamptz | |

#### orders

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| booking_id | uuid FK→bookings UNIQUE | |
| razorpay_order_id | text | |
| razorpay_payment_id | text | |
| amount | numeric | = booking_fee (₹20) |
| status | text | CREATED / PAID / FAILED / REFUNDED |
| created_at / paid_at | timestamptz | |

#### reviews

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| booking_id | uuid FK→bookings UNIQUE | 1 review per booking |
| worker_id | uuid FK→workers | |
| client_id | uuid FK→users | |
| rating | int CHECK 1..5 | |
| text | text | max 500 |
| tags | text[] | quick tags |
| created_at | timestamptz | |

#### chat_messages

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| booking_id | uuid FK→bookings | |
| sender_id | uuid FK→users | |
| message_type | text default 'text' | text only in MVP |
| content | text | |
| is_read | bool default false | |
| created_at | timestamptz | |

#### payouts

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| booking_id | uuid FK→bookings UNIQUE | 1 payout per booking |
| worker_id | uuid FK→workers | |
| amount | numeric | = worker_earning |
| status | text | PENDING / PROCESSING / SUCCESS / FAILED |
| razorpay_payout_id | text | |
| created_at / processed_at | timestamptz | |

#### worker_payment_info

| Column | Type | Notes |
|---|---|---|
| user_id | uuid PK FK→users | |
| payout_method | text | 'upi' \| 'bank' |
| upi_id | text | |
| bank_account / ifsc / account_holder | text | |
| updated_at | timestamptz | |

#### notifications

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK→users | |
| type | text | booking / payment / system |
| title / body | text | |
| is_read | bool default false | |
| created_at | timestamptz | |

#### push_tokens

| Column | Type | Notes |
|---|---|---|
| user_id | uuid PK FK→users | |
| token | text | FCM token |
| platform | text | android |
| updated_at | timestamptz | |

#### platform_config

| Column | Type | Notes |
|---|---|---|
| key | text PK | e.g. 'booking_fee', 'commission_rate' |
| value | jsonb | |

### 7.2 Indexes

```
bookings(worker_id, status)
bookings(client_id, created_at DESC)
workers(category, city, approval_status, is_available)
workers(rating_avg DESC)
reviews(worker_id, created_at DESC)
chat_messages(booking_id, created_at)
notifications(user_id, is_read)
```

### 7.3 ERD (Relationships)

```
                        ┌───────────────┐
                        │     users     │
                        └───┬───┬───┬───┘
                 1:1        │   │1:*    1:*        1:1
        ┌───────────────────┘   │      └──────────────────┐
        ▼                       ▼                         ▼
┌───────────────┐        ┌─────────────┐          ┌───────────────┐
│    workers    │        │  bookings   │          │ notifications │
└───┬───────┬───┘        └──┬───┬───┬──┘          └───────────────┘
    │1:*    │               │   │   │
    │       │   ┌───────────┘   │   └───────────┐
    │       │   │1:1            │1:*            │1:1
    │       │   ▼               ▼               ▼
    │       │ ┌────────┐ ┌──────────────┐ ┌───────────┐
    │       │ │ orders │ │ chat_messages│ │  payouts  │
    │       │ └────────┘ └──────────────┘ └─────┬─────┘
    │       │                                  │
    │       │        ┌─────────────────────────┘ (worker_id *:1)
    │       │        │
    │       └────────┼──────────────┐
    │1:*             │              │
    ▼               ▼              │
┌───────────┐  (reviews also      │
│  reviews  │◀─ booking_id 1:1)   │
└───────────┘                     │
                                  │
users 1:1 worker_payment_info     │
users 1:1 push_tokens             │
workers 1:* payouts ◀─────────────┘
workers 1:* reviews
```

Simplified relationship list (source of truth):

```
users        1 ── 1  workers                 (workers.user_id)
users        1 ── *  bookings                (bookings.client_id)
workers      1 ── *  bookings                (bookings.worker_id)
bookings     1 ── 1  orders                  (orders.booking_id)
bookings     1 ── 1  reviews                 (reviews.booking_id)
workers      1 ── *  reviews                 (reviews.worker_id)
bookings     1 ── *  chat_messages           (chat_messages.booking_id)
bookings     1 ── 1  payouts                 (payouts.booking_id)
workers      1 ── *  payouts                 (payouts.worker_id)
users        1 ── 1  worker_payment_info     (worker_payment_info.user_id)
users        1 ── *  notifications           (notifications.user_id)
users        1 ── 1  push_tokens             (push_tokens.user_id)
(singleton)      platform_config
```

### 7.4 RLS Policy Summary

| Table | SELECT | INSERT | UPDATE |
|---|---|---|---|
| users | self | self (on signup) | self |
| workers | any authenticated | self | self (EXCEPT approval_status, rating_avg, rating_count → admin/trigger only) |
| bookings | client OR worker of row | any client | client (cancel) / worker (status) per status rules |
| orders | client of booking | edge fn only (service role) | edge fn only |
| reviews | any authenticated | client of booking (once) | never (immutable) |
| chat_messages | participants of booking | participants | never |
| payouts | worker of row | edge fn only | edge fn only |
| worker_payment_info | self | self | self |
| notifications | self | edge fn / trigger | self (mark read) |
| push_tokens | self | self | self |
| platform_config | any authenticated | admin | admin |

### 7.5 DB Triggers (fix v1 atomicity bug)

```
on_review_insert → recompute workers.rating_avg & rating_count (atomic)
on_booking_completed → insert notification row for client
on_payout_success → insert notification row for worker
```

---

## 8. System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          MOBILE (Flutter/Dart)                   │
│  ┌──────────────────────────┐   ┌──────────────────────────┐    │
│  │  KaamWala — Client UI    │   │  KaamWala — Worker UI    │    │
│  │  (Hinglish)              │   │  (Hindi-first)           │    │
│  ├──────────────────────────┤   ├──────────────────────────┤    │
│  │ Riverpod state • go_router • Material 3 • FCM listener │    │
│  ├──────────────────────────┴───┴──────────────────────────┤    │
│  │  DATA LAYER: Repositories (typed models, no raw maps)   │    │
│  └───────────────┬──────────────────────────┬──────────────┘    │
└──────────────────┼──────────────────────────┼───────────────────┘
                   │ HTTPS (REST + Realtime WS)│
                   ▼                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              CLOUDFLARE WORKERS (reverse proxy)                  │
│  custom domain → bypasses Jio/Airtel DNS blocks • CORS • cache   │
└──────────────────────────────┬──────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                            SUPABASE                              │
│  ┌──────────┐ ┌────────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │   Auth   │ │ PostgreSQL │ │ Storage  │ │     Realtime     │   │
│  │ Phone OTP│ │  + RLS +   │ │ profiles │ │ chat_messages    │   │
│  │ (SMS)    │ │  triggers  │ │ portfolios│ │ bookings status  │   │
│  │          │ │            │ │ aadhar🔒 │ │ orders status    │   │
│  └──────────┘ └────────────┘ └──────────┘ └──────────────────┘   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              EDGE FUNCTIONS (Deno • secrets live HERE)     │ │
│  │  create-order • verify-payment • release-payout            │ │
│  │  approve-worker • send-push                                │ │
│  └───────────────┬──────────────────────────┬─────────────────┘ │
└──────────────────┼──────────────────────────┼───────────────────┘
                   │ server-side only         │
                   ▼                          ▼
        ┌────────────────────┐     ┌────────────────────┐
        │      RAZORPAY      │     │  FCM (push) + SMS  │
        │ Orders API         │     │  (OTP & push via   │
        │ Native Checkout    │     │   provider)        │
        │ Webhooks (HMAC)    │     └────────────────────┘
        │ Razorpay X Payouts │
        └────────────────────┘

RULES:
 • Mobile app NEVER holds Razorpay secret / Supabase service key.
 • All money math happens in Edge Functions.
 • App ↔ Supabase ONLY via Cloudflare proxy domain.
 • Realtime used for: chat, booking status, order status.
 • FCM used for: cross-user push notifications.
```

---

## 9. Payment & Payout Sequence Diagram

```
Client App           Edge Functions            Razorpay             Worker App
    │                     │                      │                     │
    │── create-order ────▶│                      │                     │
    │                     │── POST /orders ─────▶│                     │
    │                     │◀── order_id ─────────│                     │
    │◀─ {order_id,key_id}─│  (save orders row)   │                     │
    │                     │                      │                     │
    │── open native checkout ───────────────────▶│                     │
    │◀── payment_id + signature ─────────────────│                     │
    │                     │◀─ webhook payment.captured (HMAC verify)   │
    │                     │  orders→PAID         │                     │
    │                     │  bookings→paid       │                     │
    │                     │── push "🔔 New Job" ──────────────────────▶│
    │                     │                      │                     │
    │                     │      ... worker accepts → does job → completes ...
    │                     │                      │                     │
    │── confirm completion (client_confirmed=true)                     │
    │── release-payout ──▶│                      │                     │
    │                     │ check order PAID     │                     │
    │                     │ check not RELEASED   │                     │
    │                     │── POST payout (Razorpay X, UPI) ─▶│        │
    │                     │◀── payout processed ─│                     │
    │                     │  orders→RELEASED, payouts→SUCCESS          │
    │                     │── push "💰 ₹ received" ───────────────────▶│
    │◀── "Job done 🎉 rate now"                  │                     │
```

Refund path (MVP): cancel while `pending` → Edge Function calls Razorpay Refund API → orders→REFUNDED → client notified.

---

## 10. Excalidraw / draw.io Reproduction Guide

To turn the ASCII diagrams into visual files (free tools: excalidraw.com / draw.io):

**Architecture diagram — nodes:**
```
[Flutter Client App] [Flutter Worker App]
[Cloudflare Proxy]
[Supabase Auth] [Supabase Postgres] [Supabase Storage] [Supabase Realtime] [Edge Functions]
[Razorpay] [Razorpay X] [FCM/SMS]
```
**Edges:**
```
Client App → Cloudflare Proxy
Worker App → Cloudflare Proxy
Cloudflare Proxy → Supabase (Auth/Postgres/Storage/Realtime)
Client App → Razorpay (checkout only)
Edge Functions → Razorpay (orders + payouts)
Razorpay → Edge Functions (webhook)
Edge Functions → FCM/SMS
Edge Functions → Postgres
```

**ERD — one rectangle per table (11), connect with labeled lines per section 7.3.**

**User flows — copy the arrow chains from section 5 as-is into swimlanes (Client / Worker / Admin).**

---


```