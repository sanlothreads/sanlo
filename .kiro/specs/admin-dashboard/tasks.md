# Implementation Plan: Admin Dashboard

## Overview

This plan builds the admin area bottom-up and UI-first, mirroring the existing feature structure: domain entities and the `AdminRepository` interface, a seeded `MockAdminRepository`, then cubits, then shared admin widgets, then the responsive screens, then router wiring and the admin gate, and finally tests. Every task ends by integrating its output so the app stays runnable. All screens render from mock data; no Firebase wiring is included. Tasks marked with `*` are optional test sub-tasks and are not auto-implemented.

## Tasks

- [x] 1. Admin domain layer
  - [x] 1.1 Order stage enum and helpers
    - Create `lib/features/admin/domain/entities/order_stage.dart` with the six-value `OrderStage` enum and an extension providing `label`, `next`, `advanceActionLabel`, `color`, and `bgColor` (mapped to `AppColors`)
    - _Requirements: 3.5, 3.6, 3.8, 6.4_

  - [x]* 1.2 Unit tests for OrderStage helpers
    - Cover `label`/`advanceActionLabel` for each stage and `allSet.next == null`
    - _Requirements: 3.6, 3.8_

  - [x] 1.3 Admin entities
    - Create `admin_order.dart`, `admin_product.dart`, `admin_customer.dart`, and `dashboard_summary.dart` under `domain/entities/` (Equatable), reusing `CategoryKind` and `Gender`; include measurement and visibility/type enums
    - _Requirements: 2.3, 2.4, 2.5, 4.1, 5.1, 6.3_

  - [x] 1.4 Repository interface
    - Create `lib/features/admin/domain/repositories/admin_repository.dart` with `loadDashboard`, `loadOrders`, `loadProducts`, `loadCustomers`
    - _Requirements: 6.2, 6.3_

- [x] 2. Admin data layer
  - [x] 2.1 Data models
    - Create `data/models/*_model.dart` mirrors with `toEntity()` for order, product, customer, and summary
    - _Requirements: 6.2, 6.3_

  - [x] 2.2 Seeded mock repository
    - Create `data/repositories/mock_admin_repository.dart` seeded with the sample orders (#SN-1036…#SN-1048), 10 products, 8 customers, and dashboard totals/stage counts from the designs
    - Register `AdminRepository` in `lib/core/di/service_locator.dart`
    - _Requirements: 6.2, 6.3_

- [x] 3. Greeting utility
  - [x] 3.1 Implement greetingFor
    - Add `greetingFor(DateTime)` (e.g. in `lib/core/utils/`) returning the four time-of-day greetings with boundaries at 05:00/12:00/17:00/21:00
    - _Requirements: 2.2_

  - [x]* 3.2 Property/unit tests for greeting
    - Test the four boundaries and totality (every time maps to exactly one greeting)
    - _Requirements: 2.2_

- [x] 4. Admin cubits
  - [x] 4.1 Dashboard cubit
    - Create `admin_dashboard_cubit.dart` / `_state.dart`: load `DashboardSummary`; `advanceStage(orderId)` for the narrow action list
    - _Requirements: 2.1, 2.3, 2.4, 2.5, 2.7_

  - [x] 4.2 Orders cubit
    - Create `admin_orders_cubit.dart` / `_state.dart`: hold orders, active filter, selected id; `selectFilter`, `selectOrder`, `advanceSelected`; derive filtered list and per-stage counts; default-select first on wide
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.7, 3.9_

  - [x] 4.3 Products cubit
    - Create `admin_products_cubit.dart` / `_state.dart`: hold products + query; `search`, `upsertProduct`; derive filtered list
    - _Requirements: 4.2, 4.3, 4.9_

  - [x] 4.4 Customers cubit
    - Create `admin_customers_cubit.dart` / `_state.dart`: hold customers + query; `search`; derive filtered list
    - _Requirements: 5.4, 5.5_

  - [x]* 4.5 Cubit tests
    - `bloc_test` for filtering, selection, advance (incl. no-op at `allSet`), count recompute, case-insensitive search, and upsert add/update
    - _Requirements: 3.2, 3.7, 4.2, 4.9, 5.4_

- [x] 5. Shared admin widgets
  - [x] 5.1 Navigation + summary widgets
    - Create `admin_sidebar.dart` (brand + ADMIN badge, destinations, Orders "new" badge, Sign out), `admin_summary_card.dart`, and `stage_count_card.dart` (progress bar tinted by stage)
    - Extend `StatusBadge` color variants as needed rather than duplicating
    - _Requirements: 1.3, 1.6, 2.3, 2.4, 6.1, 6.5_

  - [x] 5.2 Table and order widgets
    - Create `recent_orders_table.dart`, `product_table.dart`, `customer_table.dart` (wide) with narrow stacked-card fallbacks; `admin_order_list_tile.dart`, `admin_order_detail_panel.dart`, and `stage_stepper.dart` (hides advance button at `allSet`)
    - Reuse `SectionCard`, `FilterChips`, `PrimaryButton`
    - _Requirements: 2.5, 2.8, 3.4, 3.5, 3.6, 3.8, 4.1, 4.4, 5.1, 5.2, 5.3, 6.5_

- [x] 6. Admin screens
  - [x] 6.1 Responsive shell
    - Create `admin_shell_screen.dart` switching between sidebar (wide) and bottom nav (narrow) via a width breakpoint; wire destination selection and active state; "Sign out" resets auth and routes to Sign in
    - _Requirements: 1.3, 1.4, 1.5, 1.6, 1.7_

  - [x] 6.2 Dashboard screen
    - Create `admin_dashboard_screen.dart`: date + greeting, four summary cards, "Orders by stage", "Recent orders" table with "View all"; narrow 2×2 grid + "Orders to update" action list
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

  - [x] 6.3 Orders screen
    - Create `admin_orders_screen.dart`: stage filter chips with counts, order list, and master-detail panel (wide) / list + detail route (narrow); advance-stage action updates list, counts, and panel
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9_

  - [x] 6.4 Products screen
    - Create `admin_products_screen.dart`: searchable table with per-row Edit, Live/Hidden badges, and Add product button
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [x] 6.5 Add/Edit product form
    - Create `admin_product_form_screen.dart`: fields for name, category, price, stitch time, rating, photo count, visibility, description; inline validation (empty name / non-positive price); Save upserts via cubit; Cancel returns unchanged
    - _Requirements: 4.5, 4.6, 4.7, 4.8, 4.9, 4.10_

  - [x] 6.6 Customers screen
    - Create `admin_customers_screen.dart`: searchable (name or mobile) table with initials avatar, em-dash email fallback, and Guest/Registered badges
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 7. Routing and admin gate
  - [x] 7.1 Admin routes
    - Add admin route constants to `app_routes.dart` and a `StatefulShellRoute.indexedStack` for the four destinations plus `/admin/products/new` and `/admin/products/:id/edit` in `app_router.dart`, providing the admin cubits above the shell
    - _Requirements: 1.3, 1.4, 1.5, 4.5, 4.6_

  - [x] 7.2 Admin gate redirect
    - Extend the router redirect so an authenticated admin user (mobile in the allow-list, resolved from a mock source for now) lands at `/admin/dashboard`; non-admin users keep the existing customer path
    - _Requirements: 1.1, 1.2_

- [x] 8. Verification
  - Run `flutter analyze` and `flutter test`; build the app and confirm each admin screen renders in both wide and narrow constraints without overflow
  - _Requirements: 6.1, 6.2_

## Task Dependency Graph

```json
{
  "waves": [
    { "wave": 1, "tasks": ["1", "3"], "dependsOn": [] },
    { "wave": 2, "tasks": ["2"], "dependsOn": ["1"] },
    { "wave": 3, "tasks": ["4"], "dependsOn": ["1", "2"] },
    { "wave": 4, "tasks": ["5"], "dependsOn": ["1", "4"] },
    { "wave": 5, "tasks": ["6"], "dependsOn": ["3", "4", "5"] },
    { "wave": 6, "tasks": ["7"], "dependsOn": ["6"] },
    { "wave": 7, "tasks": ["8"], "dependsOn": ["7"] }
  ]
}
```

- Task 1 (domain) has no dependencies and comes first.
- Task 2 (data layer) depends on 1.
- Task 3 (greeting utility) is independent and can be done any time before Task 6.
- Task 4 (cubits) depends on 1 and 2.
- Task 5 (widgets) depends on 1 and the cubit-derived shapes from 4.
- Task 6 (screens) depends on 3, 4, and 5.
- Task 7 (routing + gate) depends on 6.
- Task 8 (verification) depends on all prior tasks.

## Notes

- UI-only iteration: no Firebase reads/writes. Mutations (advance stage, upsert product, search) live in cubit state; repository write methods and real-time listeners are added when Firebase is wired later.
- Reuse existing shared widgets and theme tokens (`AppColors`, `AppSpacing`, `StatusBadge`, `FilterChips`, `SectionCard`, `PrimaryButton`); extend rather than duplicate.
- The admin `OrderStage` enum is intentionally separate from the customer-facing `OrderStatus` enum so the existing customer flow is untouched.
- Tasks marked `*` are optional test sub-tasks and are not auto-run.
- The admin allow-list is resolved from a mock source in this iteration; the Firebase Realtime Database lookup is a later change isolated to the gate.
