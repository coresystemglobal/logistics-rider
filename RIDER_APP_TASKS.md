# OPRIGHT Rider App — Implementation Todo List

Source of gaps: full review of `opright-rider` vs `opright-server`. Order = priority. Each task states the **what** and the **how** (files to touch).

Legend: 🔴 = blocks core rider experience · 🟠 = high value · 🟡 = cleanup/wiring · ⚪ = nice-to-have

---

## Phase 1 — Real-time job offers & notifications 🔴

> The original request: pop up new job details (fee, destination) with **Accept / Ignore** buttons, without changing the jobs screen.
>
> ✅ **Done (added):** post-accept hand-off. `request-delivery`'s package-backed flow already routes through `DispatchService` with `requestId = packageId`; we now also (a) include `packageId` in the offer payload, (b) emit a `delivery-assigned` socket event from `attemptAutoDispatch` after `assignRider`, and (c) auto-navigate the rider to `/delivery/:packageId` on that signal (with a 4s fallback if the socket event is missed). The dormant standalone `/matching/request-delivery` (no UI calls it) remains package-less by design.

- [x] **1.1 Backend: emit a `new-job-offer` socket event to riders**
  - What: When `DispatchService` offers a job to a courier (sequential + broadcast), push it in real time instead of only logging + polling Redis.
  - How: In `opright-server/src/matching/services/DispatchService.ts` (`offerToSingleCourier`, `broadcastToRemainingCouriers`) and `opright-server/src/websocket/websocket.service.ts`, add an `emitNewJobOffer(courierId, payload)` that emits to a per-rider room (e.g. `rider:{courierId}`). Payload: `{ requestId, packageId, fee, pickup_address, delivery_address, distance_km, package_type, expires_at, vehicle_type }`. Have riders `join` their own room on socket connect.

- [x] **1.2 Backend: fix socket chat contract**
  - What: Server reads `data.message` but both apps send `data.content` → socket chat silently fails.
  - How: In `websocket.service.ts` `send-message` handler, read `data.content ?? data.message`. Also broadcast `new-message` to the room for REST-sent messages so both parties get it live.

- [x] **1.3 Mobile: connect `RealTimeService` on auth**
  - What: `RealTimeService` is currently 100% dead code.
  - How: In `opright-rider/lib/providers/auth_provider.dart` (on authenticated state) call `RealTimeService.instance.connect()`, on logout `disconnect()`. Emit/join `rider:{userId}` room. Keep it a singleton; guard reconnects.

- [x] **1.4 Mobile: create a `job_offer_provider`**
  - What: Riverpod notifier that subscribes to the `new-job-offer` socket event, queues offers, tracks seen/ignored ids, exposes the current pending offer.
  - How: New file `lib/providers/job_offer_provider.dart`. Reuse `MatchingService.acceptOffer` / `rejectOffer` for accept/ignore. Fallback: poll `RiderService.getAvailableJobs()` on an interval and diff new ids (in case the socket event is absent).

- [x] **1.5 Mobile: build the `NewJobOfferOverlay` popup**
  - What: Floating card over any screen with fee (₦), destination, pickup, distance, package type, a countdown, and **Accept** / **Ignore** buttons.
  - How: New file `lib/core/widgets/new_job_offer_overlay.dart` (mirror the pulsing/vehicle-icon design language; animated slide-in). Accept → `acceptOffer` then `context.push('/job/{id}/accepted')`. Ignore → `rejectOffer` + dismiss.

- [x] **1.6 Mobile: mount the overlay in `RiderShell`**
  - What: Popup works on all four tabs without touching the Jobs screen.
  - How: In `opright-rider/lib/screens/rider/rider_shell.dart`, wrap `child` in a `Stack` with the overlay aligned bottom (above the tab bar).

---

## Phase 2 — Real earnings, transactions & payouts 🟠

- [ ] **2.1 Backend: auto-credit rider wallet on delivery**
  - What: Riders are never credited earnings — `WalletService.processPayment()` is dead code.
  - How: In `opright-server/src/package/package.service.ts` `confirmDelivery`, call `WalletService.processPayment(...)` (creates `TRIP_EARNING` transaction). Also record a commission row (see `opright-server/src/commission`). Verify the rider's kept share = `delivery_fee × (1 − riderCommissionRate)`.

- [ ] **2.2 Mobile: wire `TransactionsScreen` to real data**
  - What: Currently hardcoded fake list.
  - How: Call `WalletService.getTransactions()` in `opright-rider/lib/screens/rider/transactions_screen.dart`; render grouped-by-date from the API response. Remove `_groups` mock.

- [ ] **2.3 Mobile: real data in `EarningsScreen`**
  - What: Chart, totals, stats, and recent transactions are hardcoded.
  - How: Add backend endpoint `GET /wallet/earnings?period=today|week|month` (aggregate `TRIP_EARNING` by day) or reuse commissions summary `GET /commissions/driver/:id/summary`. Wire chart bars + stats to it; keep balance live from `/wallet/balance`.

- [ ] **2.4 Mobile: persist payout frequency**
  - What: Daily/Weekly/Instant choice is silently dropped.
  - How: Add `payout_frequency` to the backend wallet bank-account model/validator and to `PUT /wallet/bank-account`; send it from `payout_settings_screen.dart` `_save()`.

- [ ] **2.5 Mobile: honest "Added to wallet" on delivery complete**
  - What: `delivery_complete_screen.dart` hardcodes the claim; earnings come from a URL param.
  - How: After delivery, fetch `WalletService.getBalance()` + the latest `TRIP_EARNING` transaction and render the actual credited amount. Fall back gracefully if none exists yet.

---

## Phase 3 — Jobs list & job detail 🟠

- [ ] **3.1 Backend: enrich `GET /riders/jobs`**
  - What: Job cards/countdown need real fields.
  - How: In `opright-server/src/rider/rider.service.ts` `getAvailableJobs`, include `expires_at` (now + `DISPATCH_TIMEOUT`), and pickup/dropoff lat/lng when available.

- [ ] **3.2 Mobile: fix `JobsScreen` filters & id fallback**
  - What: "Expiring Soon" filter is a no-op; `sorted[i]['id'] ?? i` can use the list index as jobId.
  - How: In `opright-rider/lib/screens/rider/jobs_screen.dart`, implement the `expiring` sort by `expires_at`, and fall back to `package_id`/`request_id` before the index.

- [ ] **3.3 Mobile: real job detail (no re-fetch of whole list, real map)**
  - What: `job_detail_screen.dart` re-downloads all jobs to find one (empty offer if gone) and shows a painted placeholder map.
  - How: Add `GET /matching/offers/:courierId/:requestId` (or pass the full job through navigation state). Render a real `FlutterMap` with pickup/dropoff pins + route; use `expires_at` for the real countdown instead of hardcoded 30s.

- [ ] **3.4 Mobile: fix `JobAcceptedScreen` navigation**
  - What: Uses `jobId` as package id and auto-navigates even on load failure.
  - How: Pass the real `packageId` (from the accepted offer) into `/delivery/:packageId`; only auto-advance after `getPackageById` succeeds.

---

## Phase 4 — Documents & KYC 🔴

- [ ] **4.1 Backend: rider documents storage & endpoints**
  - What: No way to list/upload/expiry-track vehicle documents per rider.
  - How: Verify `opright-server/src/rider/rider.model.ts` fields (license, plate, doc URLs, expiry). Add `GET /riders/documents` and `POST /riders/documents` (reusing `/upload/vehicle`, `/upload/document`, `/upload/profile` in `src/storage/upload.routes.ts`).

- [ ] **4.2 Mobile: send KYC data during registration**
  - What: Step 2 collects license/plate/doc files but never sends them.
  - How: In `opright-rider/lib/screens/auth/register_screen.dart`, upload selected files via `ApiClient.postFormData('/upload/document')` first, then include `license_number`, `vehicle_plate`, and doc URLs in the `registerRider` payload.

- [ ] **4.3 Mobile: real `VehicleDocumentsScreen`**
  - What: Docs, plate, rider ID, expiry dates are all fake; "Upload" just toggles a bool.
  - How: Create `lib/services/vehicle_documents_service.dart` calling the 4.1 endpoints; render statuses (Valid/Expiring/Expired/Not uploaded) from real data; implement actual upload via `postFormData`.

- [ ] **4.4 Mobile: `PendingApprovalScreen` polls real status**
  - What: Static "1–2 business days" placeholder.
  - How: Poll `RiderService.getProfile()`; when `verification_status == 'VERIFIED'`, auto-redirect to `/home`. Update the checklist from real status.

---

## Phase 5 — Real GPS & presence 🟠

- [ ] **5.1 Mobile: use Geolocator when going online**
  - What: Home uploads fixed Lagos coords.
  - How: In `opright-rider/lib/screens/rider/home_screen.dart`, request location permission, get `Geolocator.getCurrentPosition()`, and send real lat/lng to `updateCourierLocation`.

- [ ] **5.2 Mobile: remove hardcoded rider position**
  - What: `active_delivery_screen.dart` defaults to `LatLng(6.5244, 3.3792)`.
  - How: Start with `null` and center/zoom only when GPS resolves (stream already exists); keep 10s location upload.

- [ ] **5.3 Mobile: location permission UX**
  - How: Use `permission_handler` to request `locationAlways` on first go-online; surface a friendly "enable location" state instead of silently sending fallback coords.

---

## Phase 6 — Active delivery polish 🟠

- [ ] **6.1 Mobile: wire the call buttons**
  - What: `onPressed: () {}` in `active_delivery_screen.dart` and `package_chat_screen.dart`.
  - How: Use `url_launcher` `tel:` to the sender/recipient phone (from package data) — pickup phase → sender, delivery phase → recipient.

- [ ] **6.2 Mobile: real pickup photo**
  - What: "Take photo of package" only flips a bool.
  - How: Use `image_picker` camera, then upload via `postFormData('/upload/document')` or a new package-proof endpoint; only allow pickup confirm once uploaded.

- [ ] **6.3 Mobile: collect pickup PIN from sender**
  - What: Pickup PIN is displayed to the rider instead of entered by the sender.
  - How: Add a 4-digit PIN entry (like delivery code) the rider enters from the sender; compare against `package.pickup_pin`.

- [ ] **6.4 Mobile: guard delivery-complete navigation**
  - How: Only push `/delivery/:packageId/complete` after `confirmDelivery` succeeds; pass the credited earnings from 2.5.

---

## Phase 7 — Dead code & wiring cleanup 🟡

- [ ] **7.1 Mobile: unread badge on home bell**
  - What: `NotificationService.getUnreadCount` never called.
  - How: Watch a periodic/unread-count provider in `home_screen.dart`; show a red badge on the bell icon.

- [ ] **7.2 Mobile: make notification filter chips functional**
  - What: All/Deliveries/Wallet/Promotions only highlight.
  - How: In `notifications_screen.dart`, filter the loaded list by notification type.

- [ ] **7.3 Mobile: fix chat for the rider**
  - What: Says "Your Rider"/"En route"; "Track" pushes an unregistered `/customer/track` route; polling-only.
  - How: Show the customer/sender name as counterpart; change Track to an existing route or remove; join `package:{id}` via `RealTimeService` and listen for `new-message`; render real timestamps.

- [ ] **7.4 Mobile: implement forgot-password**
  - What: Dead button in `login_screen.dart:123`.
  - How: Add reset screens (request + confirm) calling `AuthService.requestPasswordReset`/`resetPassword`; route to them.

- [ ] **7.5 Mobile: wire Terms & Privacy row**
  - How: In `rider_profile_screen.dart`, open legal content (in-app screen or web view) using `ApiEndpoints.terms` / `commissionPolicy`.

- [ ] **7.6 Mobile: remove/repurpose dead code**
  - What: `AddressService`, `package_provider.dart`, unused models (`promotion_model`, `invoice_model`, `pricing_model`, `address_model`), unused `ApiEndpoints` constants, unused service methods.
  - How: Grep each; either wire them into a real screen or delete. Move hardcoded paths in `package_service.dart` into `ApiEndpoints`.

---

## Phase 8 — Backend features the rider app depends on 🟠

- [ ] **8.1 Backend: performance metrics endpoints**
  - What: No acceptance/on-time/completion data exists.
  - How: New `GET /riders/performance` computing completion rate, avg rating, on-time %, acceptance rate (Redis `CourierState.acceptanceRate` + delivered/confirmed timestamps). Wire `performance_screen.dart` to it.

- [ ] **8.2 Backend: dispatch via real push + REST**
  - How: Finish 1.1 so `acceptOffer`/`rejectOffer` are event-driven, and clean up the Redis poll loop in `DispatchService.waitForCourierResponse`.

- [ ] **8.3 Backend: referral reward on first delivery**
  - What: ₦1000 bonus only fires via admin commission endpoint.
  - How: In `confirmDelivery`, if first completed delivery and a referral was applied, credit both wallets (`REFERRAL_BONUS`) and mark rewarded.

- [ ] **8.4 Backend: scheduling decision**
  - How: Either implement `/scheduling/schedule` + `process-pending` or remove the rider app's `scheduleDelivery` call so it stops erroring with 503.

- [ ] **8.5 Backend: vehicle-type consistency**
  - What: VAN exists in dispatch config but riders can't register it.
  - How: Add `VAN`/`CAR` to the rider model enum + validators, or remove the VAN dispatch profile. Keep BICYCLE/MOTORCYCLE icons in the mobile apps aligned.

---

## Phase 9 — Nice-to-haves ⚪

- [ ] **9.1 Referral UI**
  - How: New `ReferralScreen` (code, share via `share_plus`, stats via `ReferralService.getStats`); entry point from Profile.

- [ ] **9.2 Performance screen wired (after 8.1)**
  - How: Replace hardcoded `score = 94` with the endpoint; add a load/error state.

- [ ] **9.3 Make Ratings reachable**
  - How: Add "My Ratings" row in Profile → `/ratings/{riderId}`; fix mocked reviewer name in `ratings_screen.dart`.

- [ ] **9.4 Notification preferences screen**
  - How: New screen wired to `GET/PUT /notifications/preferences`; entry from Profile.

- [ ] **9.5 Rider-side vehicle icon on map (like opright-mobile)**
  - How: Reuse the vehicle-marker pattern already added to `opright-mobile` (`rider_vehicle_marker.dart`) for the rider's own marker in `active_delivery_screen.dart` based on `RiderModel.vehicleType`.

---

## Suggested execution order
1. Phase 1 (1.1–1.6) — real-time job-offer popups (your original request).
2. Phase 4 (4.1–4.4) — documents/KYC so new riders can onboard properly.
3. Phase 5 (5.1–5.3) — real GPS so dispatch matching works.
4. Phase 2 (2.1–2.5) — real money movement.
5. Phases 3, 6, 7, 8, 9.
