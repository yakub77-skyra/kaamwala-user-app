# KaamWala — Google Play Console Submission Pack

Everything below is pre-filled from the codebase. Replace [BRACKETED] items.

---

## 1. App identity
| Field | Value |
|---|---|
| App name | KaamWala - Book Local Workers |
| Package | com.kaamwala.kaamwala |
| Category | **House & Home** (alt: Productivity) |
| Tags | home services, plumber, electrician, painter, carpenter, Pune |

## 2. Listing copy

**Short description (≤80 chars):**
```
Find verified plumbers, electricians, painters & carpenters in Pune in 30 sec
```

**Full description (≤4000 chars):**
```
KaamWala connects you with VERIFIED local workers for home repairs and
improvements — plumbers, electricians, painters and carpenters — at fair,
transparent prices.

FOR CUSTOMERS
• Browse verified workers with real ratings and price ranges
• Book in 30 seconds: describe the job, pick date + time slot
• Pay just ₹20 booking fee by UPI/cards via Razorpay secure checkout
• Full automatic refund if you cancel before a worker accepts
• Track your booking live: accepted → on the way → arrived → work done
• Chat directly with your worker inside the app

FOR WORKERS
• Free registration with simple Aadhaar verification
• Get paid job requests near you — accept only what fits your schedule
• Keep 90% of every job. Earnings dashboard shows today/week/month
• Payouts straight to your bank/UPI after job completion

WHY KAAMWALA?
✔ Every worker is identity-verified before they appear in the app
✔ Transparent pricing agreed BEFORE the worker travels to you
✔ Hindi-friendly interface for workers, simple English for customers
✔ Secure payments handled by Razorpay — we never see your card details

Download now and get that leaking tap fixed today.
Support: [SUPPORT-EMAIL]
```

## 3. Data safety form (answer sheet)

**Data collected?** YES

| Question | Answer |
|---|---|
| Phone number → collected, shared, optional? | Collected; NOT shared; required (app functionality — account auth) |
| Name → | Collected; shared with counterparty users; required |
| Physical address (booking) → | Collected; shared with the booked worker only; required |
| Photo (profile/portfolio/KYC) → | Collected; profile+portfolio public within app, KYC private; user-provided |
| Payment info → | NOT collected by us (Razorpay processes); we store transaction references only |
| Device or other IDs (push token) → | Collected; not shared; app functionality |
| App interactions / crash logs (Firebase Analytics/Crashlytics) → | Collected; shared with Google as processor; analytics + stability |

**Security practices:** data encrypted in transit ✓ · users can request deletion ✓ ([REQUEST-EMAIL]) · committed to Play Families Policy? NO (not children-directed)

## 4. Content rating questionnaire guidance
Answer: no violence/gambling/alcohol/drugs/user-generated sharing beyond
service chat/no purchases outside app/in-app digital goods = NO (₹20 fee is a
physical-service facilitation fee). Expected outcome: **Everyone / 3+**.

## 5. Financial features declaration
"Financial features": NO loan/personal-loan features. Worker payouts are
marketplace settlement — declare "no financial features" unless Play flags it.

## 6. Ads declaration
Contains ads: **NO**

## 7. Target audience
Age 18+ (workers sign contracts; customers book services). Do NOT select
children audiences.

## 8. Government apps / regulated financial services declarations
NO.

## 9. Release naming
- versionName 1.0.0, versionCode 1 (from pubspec)
- Internal testing track first → closed test (Pune workers/clients) → prod

## 10. Assets checklist (you must capture)
- [ ] Feature graphic 1024×500 PNG/JPEG (no text-heavy design)
- [ ] Phone screenshots min 2, recommended 8 (320–3840px, 16:9/9:16):
      home list, worker profile, booking form, payment, booking status
      timeline, chat, worker dashboard, earnings
- [ ] Icon 512×512 (export from assets/app_icon.png)
- [ ] Privacy policy URL (host store/privacy_policy.md → GitHub Pages)
- [ ] Support email (must be verified in console)

## 11. Post-upload
- Upload AAB → Play may warn about API level target — Flutter current targetSdk is compliant.
- Upload `build/app/outputs/mapping/release/mapping.txt` under
  "App bundle explorer → Downloads → Deobfuscation files" (helps ANR decoding).
- Enroll in **Play App Signing** when prompted (recommended; makes upload-key
  loss recoverable).
