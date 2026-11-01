# Implementation Plan: Sanlo Tailoring App

## Overview

This plan builds the Sanlo Flutter app bottom-up: project setup and dependencies first, then the core theme / reusable widgets / utilities, then per-feature domain entities, repository interfaces and seeded mock implementations, then the composition root and `go_router` configuration, then per-feature blocs/cubits and screens in dependency order, and finally tests (unit + property-based) and a wiring/verification pass.

Each task builds only on prior tasks and ends by integrating its output into the running app. Tasks marked with `*` are optional test sub-tasks and are not auto-implemented.

## Tasks

- [x] 1. Project setup and dependencies
  - Add to `pubspec.yaml` `dependencies`: `flutter_bloc: ^8.1.6`, `go_router: ^14.2.0`, `equatable: ^2.0.5`, `url_launcher: ^6.3.0`
  - Add to `dev_dependencies`: `bloc_test: ^9.1.7`, `mocktail: ^1.0.4`, `glados: ^1.1.6`
  - Run `flutter pub get`
  - Create the feature-first folder skeleton under `lib/`: `core/{di,router,theme,widgets,utils}/` and `features/{auth,catalog,orders,profile,shell}/` with `domain/`, `data/`, `presentation/` subfolders as laid out in the design
  - _Requirements: 8.1, 8.5_

- [x] 2. Core theme and tokens
  - [x] 2.1 Implement color palette and spacing tokens
    - Create `lib/core/theme/app_colors.dart` (indigo primary, pastel card backgrounds, status colors for In progress / Ready / Completed)
    - Create `lib/core/theme/app_spacing.dart` (spacing + radius tokens)
    - _Requirements: 2.1_

  - [x] 2.2 Implement app ThemeData
    - Create `lib/core/theme/app_theme.dart` building `ThemeData` + text theme from the palette and tokens
    - _Requirements: 2.1_

- [x] 3. Core utilities
  - [x] 3.1 Implement validators
    - Create `lib/core/utils/validators.dart` with `isValidIndianMobile` (10-digit), OTP, email, and measurement validators
    - _Requirements: 1.2, 4.2_

  - [ ]* 3.2 Write unit tests for validators
    - Test valid/invalid 10-digit mobiles, email and OTP edge cases
    - _Requirements: 1.2_

  - [x] 3.3 Implement phone launcher
    - Create `lib/core/utils/phone_launcher.dart` wrapping `url_launcher` with a `tel:` call that no-ops when `canLaunchUrl` is false
    - _Requirements: 6.3, 6.4_

- [x] 4. Domain entities
  - [x] 4.1 Implement auth entities
    - Create `lib/features/auth/domain/entities/auth_user.dart` and `otp_session.dart` (Equatable; `AuthUser` with `isGuest`, nullable id/mobile/name/email/gender)
    - Create shared `Gender` enum (reused by profile)
    - _Requirements: 1.6, 1.8, 1.11_

  - [x] 4.2 Implement catalog entities
    - Create `lib/features/catalog/domain/entities/` `category.dart` (`CategoryKind` enum + `Category`), `product.dart`, `style_detail.dart` (all Equatable)
    - _Requirements: 2.1, 2.2, 3.2, 3.3, 3.4_

  - [x] 4.3 Implement order entities
    - Create `lib/features/orders/domain/entities/` `order_status.dart` (`OrderStatus`), `timeline_step.dart` (`TimelineStage`, `StepState`, `TimelineStep`), `customer_details.dart`, `measurement_set.dart`, `order.dart`, and `order_draft.dart`
    - Add `copyWith` to `OrderDraft` and `MeasurementSet`; add `OrderDraft.isReadyToPlace` getter (`details != null && measurements != null`)
    - _Requirements: 4.1, 4.3, 4.5, 4.9, 5.5, 6.1, 6.2_

  - [ ]* 4.4 Write unit tests for order entities
    - Test `OrderDraft.copyWith`, `isReadyToPlace` (incl. "Not sure" measurement set), and `MeasurementSet.copyWith`
    - **Property 12: "Not sure" is valid** (`knowsMeasurements == false`, all numeric fields null → still ready to place)
    - **Validates: Requirements 4.3**

  - [x] 4.5 Implement profile entity
    - Create `lib/features/profile/domain/entities/user_profile.dart` (Equatable; name, mobile, email, gender, stats totalOrders/inProgress/ready) with `copyWith`
    - _Requirements: 7.1, 7.3_

- [x] 5. Repository interfaces (domain)
  - Create `lib/features/auth/domain/repositories/auth_repository.dart` (`AuthRepository`)
  - Create `lib/features/catalog/domain/repositories/product_repository.dart` (`ProductRepository`)
  - Create `lib/features/orders/domain/repositories/order_repository.dart` (`OrderRepository` + `OrderBucket` enum)
  - Create `lib/features/profile/domain/repositories/profile_repository.dart` (`ProfileRepository`)
  - Define typed failures `NotFoundFailure` and `InvalidOtpFailure` in a shared `core/` location for repos to throw
  - _Requirements: 8.1_

- [x] 6. Mock repository implementations with seed data
  - [x] 6.1 Implement DTO models and mappers
    - Create `data/models/*` thin DTOs with `fromJson`/`toJson` and `toEntity()`/`fromEntity()` for auth, catalog, order, and profile entities
    - _Requirements: 8.1, 8.5_

  - [x] 6.2 Implement MockProductRepository with seeded catalog
    - Create `lib/features/catalog/data/repositories/mock_product_repository.dart` seeding the six products exactly: p_blouse (women, Designer Blouse, Blouse, 4.8, 5, ₹650), p_anarkali (women, Anarkali Kurti, Kurti, 4.7, 7, ₹900), p_shirt (men, Formal Shirt, Shirt, 4.6, 4, ₹550), p_kurta (men, Kurta Pajama, Kurta set, 4.8, 6, ₹1000), p_frock (kids, Kids Frock, Frock, 4.9, 3, ₹450), p_salwar (women, Salwar Suit, Suit, 4.7, 8, ₹1100)
    - Seed categories All/Women/Men/Kids; `getProducts(filter: all)` returns every product; `getProductDetail` throws `NotFoundFailure` for unknown ids
    - _Requirements: 8.2, 8.5, 2.1, 3.1, 3.6_

  - [ ]* 6.3 Write unit tests for MockProductRepository seed data
    - Assert six products with the listed ids/categories/types/ratings/days/prices, and `NotFoundFailure` for unknown id
    - _Requirements: 8.2_

  - [x] 6.4 Implement MockOrderRepository with seeded orders and timeline
    - Create `lib/features/orders/data/repositories/mock_order_repository.dart` seeding at least one active order including `#SN-1048` (Designer Blouse, In progress, next "Stitching started") and at least one completed order, each in the correct `OrderBucket`
    - Seed a six-stage timeline (Order placed→done, Measurement done→done, Stitching started→current, Stitching finished→pending, Final touch-up→pending, All set→pending) with timestamps on done/current only
    - Implement `placeOrder` assigning an id matching `#SN-####`; `getOrderById`/`getTimeline` throw `NotFoundFailure` for unknown ids
    - _Requirements: 8.3, 8.4, 8.5, 4.9, 5.2, 5.3, 6.1, 6.5_

  - [ ]* 6.5 Write unit tests for MockOrderRepository seed data and placeOrder
    - Assert active bucket contains `#SN-1048`, completed bucket non-empty, six-stage timeline present, and `placeOrder` returns id matching `#SN-####` with product equal to draft product
    - **Property 13: Placed order identity**
    - **Validates: Requirements 8.3, 8.4, 4.6**

  - [x] 6.6 Implement MockAuthRepository
    - Create `lib/features/auth/data/repositories/mock_auth_repository.dart` accepting any +91 mobile, returning an `OtpSession`, verifying only the fixed code `0000` (throw `InvalidOtpFailure` otherwise), plus `continueAsGuest` and `createAccount`
    - _Requirements: 8.6, 1.1, 1.3, 1.4, 1.6, 1.9_

  - [ ]* 6.7 Write unit tests for MockAuthRepository
    - Assert `0000` verifies successfully and any other code throws `InvalidOtpFailure`; guest session has `isGuest == true`
    - **Validates: Requirements 8.6, 1.4**

  - [x] 6.8 Implement MockProfileRepository
    - Create `lib/features/profile/data/repositories/mock_profile_repository.dart` seeding a profile with stats and personal details; `updateProfile` echoes the saved profile
    - _Requirements: 8.1, 7.1, 7.3_

- [x] 7. Core reusable widgets
  - [x] 7.1 Implement ImagePlaceholder and SectionCard
    - Create `lib/core/widgets/image_placeholder.dart` (icon + optional caption, no bundled assets) and `lib/core/widgets/section_card.dart` (rounded pastel container)
    - _Requirements: 8.5, 3.2_

  - [x] 7.2 Implement PrimaryButton, StatusBadge, StepIndicator
    - Create `lib/core/widgets/primary_button.dart` (full-width CTA, loading + disabled), `status_badge.dart` (maps `OrderStatus` → color/label), `step_indicator.dart` ("Step N of 3 · Label" with progress segments)
    - _Requirements: 4.1, 5.5_

  - [x] 7.3 Implement ProductCard, CategoryFilterChips, OrderTimeline
    - Create `lib/core/widgets/product_card.dart` (image placeholder + category + name + rating + days + price + onTap), `filter_chips.dart` (`CategoryFilterChips` scrollable selectable chips), `order_timeline.dart` (done/current/pending nodes + timestamps)
    - _Requirements: 2.1, 2.7, 6.1, 6.2_

  - [ ]* 7.4 Write widget tests for core widgets
    - Structural tests that `ProductCard`, `StatusBadge`, `StepIndicator`, and `OrderTimeline` render the expected text/labels
    - _Requirements: 2.1, 5.5, 6.2_

- [x] 8. Checkpoint - foundation
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Auth feature
  - [x] 9.1 Implement AuthBloc (events, state, logic)
    - Create `lib/features/auth/presentation/bloc/` `auth_event.dart`, `auth_state.dart` (`AuthPhase`), `auth_bloc.dart` handling `OtpRequested` (validate mobile → send), `OtpVerified` (no-op if `session == null`, else verify), `GuestRequested`, `AccountSubmitted`, `AuthReset`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.9, 1.11_

  - [ ]* 9.2 Write bloc tests for AuthBloc
    - Use `bloc_test` to assert state sequences for valid/invalid mobile, correct/incorrect OTP, verify-before-send, guest, and create account
    - **Property 5: No verify before send**, **Property 6: OTP correctness**, **Property 7: Guest is always authenticated-as-guest**, **Property 8: Terminal auth**
    - **Validates: Requirements 1.1, 1.2, 1.3**

  - [x] 9.3 Implement Sign in screen
    - Create `lib/features/auth/presentation/screens/sign_in_screen.dart`: mobile field + inline "Enter a valid 10-digit mobile" error, OTP entry with "Incorrect code" handling, "Continue as guest"/"Skip", and "Create an account" link
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6, 1.7_

  - [x] 9.4 Implement Sign up screen
    - Create `lib/features/auth/presentation/screens/sign_up_screen.dart`: first name, last name, mobile, email, gender fields; "Create account" submits `AccountSubmitted`; "Sign in" link back to sign in
    - _Requirements: 1.8, 1.9, 1.10_

- [x] 10. Catalog feature (Home + Product details)
  - [x] 10.1 Implement HomeCubit with derived visibleProducts
    - Create `lib/features/catalog/presentation/cubit/` `home_state.dart` (with pure `visibleProducts` getter: category filter then case-insensitive name-contains query) and `home_cubit.dart` (`load`, `applyFilter`, `search`)
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ]* 10.2 Write property tests for HomeCubit filtering/search
    - **Property 1: Filter soundness**, **Property 2: Filter completeness**, **Property 3: Search is a refinement**, **Property 4: Search case-insensitive membership**
    - **Validates: Requirements 2.2, 2.3**

  - [x] 10.3 Implement Home screen
    - Create `lib/features/catalog/presentation/screens/home_screen.dart`: greeting, search field, `CategoryFilterChips`, promo banner, product grid of `ProductCard`s; guest sign-in button in header; tapping a card navigates to `productDetails`
    - _Requirements: 2.1, 2.2, 2.3, 2.5, 2.6, 2.7_

  - [x] 10.4 Implement ProductDetailsCubit
    - Create `lib/features/catalog/presentation/cubit/` `product_details_state.dart` and `product_details_cubit.dart`: load `StyleDetail` by id, maintain `selectedPhotoIndex`/`selectedVariantIndex`, emit error ("Not found") when repo throws `NotFoundFailure`
    - _Requirements: 3.1, 3.5, 3.6_

  - [x] 10.5 Implement Product details screen
    - Create `lib/features/catalog/presentation/screens/product_details_screen.dart`: carousel placeholder, variant thumbnails (update selected variant on tap), category/type/rating, price/ready-in-days/payment chips, "About this style" + included checklist, "Not found" state with back action, and "Order now" CTA
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [x] 11. Orders feature (place-order flow)
  - [x] 11.1 Implement PlaceOrderBloc (events, state, state machine)
    - Create `lib/features/orders/presentation/bloc/` `place_order_event.dart`, `place_order_state.dart` (`OrderStep`), `place_order_bloc.dart` handling `OrderStarted`, `CustomerDetailsSubmitted` → measurements, `MeasurementsSubmitted` → review, `EditDetailsRequested`/`EditMeasurementsRequested` (preserve draft), `OrderPlaced` (require `isReadyToPlace` else "Complete all steps first"; placing → placed on success, back to review with "Could not place order, try again" on failure)
    - _Requirements: 4.1, 4.3, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10_

  - [ ]* 11.2 Write property/bloc tests for PlaceOrderBloc
    - **Property 9: Step monotonicity until review**, **Property 10: Draft preservation on edit**, **Property 11: Place requires completeness**, **Property 13: Placed order identity**
    - Also assert "Complete all steps first" and "Could not place order, try again" failure path via `bloc_test`
    - **Validates: Requirements 4.1, 4.4, 4.5, 4.6, 4.7, 4.8**

  - [x] 11.3 Implement Order step 1 (Your details) screen
    - Create `lib/features/orders/presentation/screens/order_details_step_screen.dart`: full name + mobile required, email + address optional; submit `CustomerDetailsSubmitted` and advance to measurements
    - _Requirements: 4.1, 4.2_

  - [x] 11.4 Implement Order step 2 (Measurements) screen
    - Create `lib/features/orders/presentation/screens/order_measurements_step_screen.dart`: "Not sure" path (knowsMeasurements=false, no fields) and "I know" path (in-inches fields + optional design notes); submit `MeasurementsSubmitted` and advance to review
    - _Requirements: 4.3, 4.4, 4.5_

  - [x] 11.5 Implement Order step 3 (Review) screen
    - Create `lib/features/orders/presentation/screens/order_review_step_screen.dart`: show captured details + measurements, edit actions returning to steps 1/2, "Place order" CTA, and error banner for incomplete/failed placement
    - _Requirements: 4.6, 4.7, 4.8, 4.10_

  - [x] 11.6 Implement Order placed screen
    - Create `lib/features/orders/presentation/screens/order_placed_screen.dart`: receives placed order id, offers "Track order" → tracking and "Back to home" → home
    - _Requirements: 4.12_

- [x] 12. Orders feature (My orders + tracking)
  - [x] 12.1 Implement OrdersCubit
    - Create `lib/features/orders/presentation/cubit/` `orders_state.dart` (with `visible` getter by bucket) and `orders_cubit.dart` (load active + completed, switch bucket)
    - _Requirements: 5.1, 5.2, 5.3_

  - [ ]* 12.2 Write unit tests for OrdersCubit
    - Assert `visible` returns active vs completed by bucket and bucket switching emits expected state
    - _Requirements: 5.2, 5.3_

  - [x] 12.3 Implement My orders screen
    - Create `lib/features/orders/presentation/screens/my_orders_screen.dart`: Active/Completed tabs, guest sign-in banner, each order card with status badge + progress + next step + amount at shop; tapping a card navigates to tracking
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [x] 12.4 Implement OrderTrackingCubit
    - Create `lib/features/orders/presentation/cubit/` `order_tracking_state.dart` and `order_tracking_cubit.dart`: load order header + timeline by id, emit "Not found" on `NotFoundFailure`
    - _Requirements: 6.1, 6.5_

  - [ ]* 12.5 Write property tests for order timeline invariants
    - **Property 14: Single current for non-completed orders**, **Property 15: Monotone timeline**, **Property 16: Timestamps match state**
    - **Validates: Requirements 6.2**

  - [x] 12.6 Implement Order tracking screen
    - Create `lib/features/orders/presentation/screens/order_tracking_screen.dart`: header card + six-stage `OrderTimeline`, "Call the shop" via `PhoneLauncher` (no-op when dialer unavailable), "Not found" state with back action
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 13. Profile feature
  - [x] 13.1 Implement ProfileCubit
    - Create `lib/features/profile/presentation/cubit/` `profile_state.dart` and `profile_cubit.dart`: load profile + stats; (optional editing) save edits via `updateProfile`
    - _Requirements: 7.1, 7.3_

  - [x] 13.2 Implement Profile screen
    - Create `lib/features/profile/presentation/screens/profile_screen.dart`: profile header, order stats (Total orders, In progress, Ready), personal details (name, mobile, email, gender), and sign-in action navigating to sign in
    - _Requirements: 7.1, 7.2_

- [x] 14. Navigation, shell, and composition root
  - [x] 14.1 Implement bottom-nav shell screen
    - Create `lib/features/shell/presentation/screens/main_shell_screen.dart` using `StatefulNavigationShell` + `AppBottomNav` for Home / My orders / Profile tabs
    - Create `lib/core/widgets/app_bottom_nav.dart`
    - _Requirements: 2.8, 2.9_

  - [x] 14.2 Implement route constants and GoRouter config
    - Create `lib/core/router/app_routes.dart` (path/name constants) and `lib/core/router/app_router.dart`: signIn/signUp routes, `StatefulShellRoute.indexedStack` for the 3 tabs, `productDetails`, the `/order` `ShellRoute` providing a single `PlaceOrderBloc`, `orderPlaced`, and `orderTracking`
    - Add redirect guards on `/order/measurements` and `/order/review` that send the user to Home when no `OrderDraft` with a product exists
    - _Requirements: 1.7, 1.10, 2.6, 2.7, 2.8, 2.9, 3.7, 4.1, 4.11, 4.12, 5.6, 6.1, 7.2_

  - [x] 14.3 Implement composition root
    - Create `lib/core/di/service_locator.dart` wiring `MockAuthRepository`/`MockProductRepository`/`MockOrderRepository`/`MockProfileRepository` to their interfaces
    - _Requirements: 8.1_

  - [x] 14.4 Wire app.dart and main.dart
    - Create `lib/app.dart` with `RepositoryProvider`s (from the composition root), global `AuthBloc`/screen cubits as needed, `MaterialApp.router` using the theme and `GoRouter`
    - Replace the default counter `lib/main.dart` to run `SanloApp`
    - _Requirements: 8.1, 2.1_

- [x] 15. Platform config for tel: launches
  - Add `LSApplicationQueriesSchemes` with `tel` to `ios/Runner/Info.plist`
  - Add a `<queries>` entry for the `tel` intent to `android/app/src/main/AndroidManifest.xml`
  - _Requirements: 6.3_

- [ ]* 16. Repository substitutability test
  - Add a fake alternative repository in a test and assert a Bloc/Cubit behaves identically to the mock, confirming no presentation/domain code references concrete `Mock*` classes
  - **Property 17: Interface substitutability**
  - **Validates: Requirements 8.1**

- [x] 17. Final checkpoint - wiring and verification
  - Run `flutter analyze` and fix any issues
  - Run the full test suite (`flutter test --run`) and ensure it passes
  - Smoke-check the navigation wiring end-to-end via tests (guest → Home → product → order steps → placed → tracking)
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP.
- Each task references specific requirement sub-clauses for traceability; property test tasks also reference the design's Correctness Properties (P1–P17).
- Checkpoints (tasks 8 and 17) ensure incremental validation.
- Property tests validate universal correctness properties; unit/widget tests validate specific examples and edge cases.
- All images are rendered via `ImagePlaceholder`; no bundled image assets are required.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.1", "3.1", "3.3"] },
    { "id": 1, "tasks": ["2.2", "3.2", "4.1", "4.2", "4.3", "4.5"] },
    { "id": 2, "tasks": ["4.4", "5.1", "7.1"] },
    { "id": 3, "tasks": ["6.1", "6.6", "6.8", "7.2"] },
    { "id": 4, "tasks": ["6.2", "6.4", "6.7", "7.3"] },
    { "id": 5, "tasks": ["6.3", "6.5", "7.4", "9.1", "10.1", "11.1", "12.1", "12.4", "13.1"] },
    { "id": 6, "tasks": ["9.2", "10.2", "10.4", "11.2", "12.2", "12.5"] },
    { "id": 7, "tasks": ["9.3", "9.4", "10.3", "10.5", "11.3", "11.4", "11.5", "11.6", "12.3", "12.6", "13.2", "14.1"] },
    { "id": 8, "tasks": ["14.2"] },
    { "id": 9, "tasks": ["14.3"] },
    { "id": 10, "tasks": ["14.4", "15"] },
    { "id": 11, "tasks": ["16"] }
  ]
}
```
