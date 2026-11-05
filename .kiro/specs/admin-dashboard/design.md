# Design Document: Admin Dashboard

## Overview

The Admin Dashboard is a new feature module added alongside the existing customer-facing features in the Sanlo Flutter app. It follows the same architecture already used across the codebase: a feature-first folder under `lib/features/admin/` split into `domain/`, `data/`, and `presentation/` layers, with `cubit`-based state management, `go_router` navigation, and in-memory mock repositories behind domain interfaces.

This iteration delivers **UI only**. All screens render from seeded mock data. Interactions that would normally persist (advancing an order's stage, adding/editing a product, searching) mutate in-memory cubit state so the screens are fully interactive and visually complete, but nothing is written to Firebase yet. The data layer is isolated behind an `AdminRepository` interface so a `FirebaseAdminRepository` can later replace `MockAdminRepository` without touching presentation or domain code.

Two responsive layouts are supported from a single set of screens, driven by a width breakpoint:

- **Wide layout** (tablet/desktop/web): a persistent left sidebar hosts navigation; screens use multi-column tables and a master–detail panel for Orders.
- **Narrow layout** (phone): a bottom navigation bar hosts navigation; the dashboard condenses to stat tiles plus an "Orders to update" action list, and tables collapse to stacked cards.

### Goals

- Add the admin area without disturbing the existing customer shell or `OrderStatus` enum.
- Reuse existing theme tokens and shared widgets (`AppColors`, `AppSpacing`, `StatusBadge`, `FilterChips`, `SectionCard`, `PrimaryButton`).
- Keep all data behind `AdminRepository` so Firebase wiring is a later, localized change.

### Non-Goals

- Firebase reads/writes, real-time listeners, or persistence.
- Authentication changes beyond the routing gate that already distinguishes admin numbers.
- Reporting/analytics beyond the summary counts shown in the designs.

## Architecture

### Module layout

```
lib/features/admin/
  domain/
    entities/
      admin_order.dart          # order with 6-stage lifecycle + customer/measurement info
      order_stage.dart          # enum: ordered, measurementDone, stitchingStarted,
                                 #       stitchingFinished, finalTouchUp, allSet
      admin_product.dart        # catalog row: name, category, price, stitchDays,
                                 #              rating, photoCount, visibility, description
      admin_customer.dart       # directory row: name, mobile, email?, gender, type,
                                 #                orderCount, lastOrderDate
      dashboard_summary.dart    # totals + per-stage counts + recent orders
    repositories/
      admin_repository.dart     # interface: orders, products, customers, summary
  data/
    models/                     # *_model.dart mirrors of the entities (toEntity())
    repositories/
      mock_admin_repository.dart # seeded in-memory implementation
  presentation/
    cubit/
      admin_dashboard_cubit.dart / _state.dart
      admin_orders_cubit.dart   / _state.dart   # filter + advance-stage
      admin_products_cubit.dart / _state.dart   # search + add/edit
      admin_customers_cubit.dart/ _state.dart   # search
    screens/
      admin_shell_screen.dart        # responsive sidebar / bottom-nav container
      admin_dashboard_screen.dart
      admin_orders_screen.dart       # master-detail (wide) / list (narrow)
      admin_products_screen.dart
      admin_product_form_screen.dart # add + edit
      admin_customers_screen.dart
    widgets/
      admin_sidebar.dart
      admin_summary_card.dart
      stage_count_card.dart
      recent_orders_table.dart
      admin_order_list_tile.dart
      admin_order_detail_panel.dart
      stage_stepper.dart
      product_table.dart
      customer_table.dart
```

### Navigation

A new `StatefulShellRoute.indexedStack` for the admin area, parallel to the existing customer shell, hosts the four destinations as branches so each keeps its own stack:

- `/admin/dashboard` → `AdminDashboardScreen`
- `/admin/orders` → `AdminOrdersScreen`
- `/admin/products` → `AdminProductsScreen`
- `/admin/customers` → `AdminCustomersScreen`

Non-branch admin routes:

- `/admin/products/new` → `AdminProductFormScreen` (add)
- `/admin/products/:id/edit` → `AdminProductFormScreen` (edit, product via `extra`)

New route constants are added to `app_routes.dart` (e.g. `adminDashboardPath/Name`, etc.). The `AdminShellScreen` renders `AdminSidebar` as a `Row` leading child in the wide layout and an `AppBottomNav`-style bar in the narrow layout, deciding via `LayoutBuilder` / `MediaQuery` against a breakpoint constant (reuse/extend `ResponsiveCenter` conventions; breakpoint ~900 dp).

#### Admin gate

Routing to the admin area keys off the signed-in user's mobile number being in an admin allow-list. For this UI-only iteration the allow-list is resolved from the existing auth state / a mock source; the real Realtime Database lookup is wired later. The redirect logic lives alongside the existing router redirect so that, when auth resolves to an admin user, the initial authenticated location is `/admin/dashboard` rather than `/home`. The gate is additive and leaves the existing customer redirect path unchanged for non-admin users.

### State management

Each screen is backed by a `Cubit` that loads from `AdminRepository` and holds view state. Cubits are provided at the admin shell level (or per-screen via `BlocProvider`) following the existing `HomeCubit`/`OrdersCubit` pattern. States use `Equatable` and a status enum (`initial`, `loading`, `loaded`, `failure`) consistent with existing `*_state.dart` files.

- `AdminDashboardCubit`: loads `DashboardSummary`; exposes `advanceStage(orderId)` used by the narrow "Orders to update" list.
- `AdminOrdersCubit`: holds all orders, the active `Stage_Filter`, and the selected order id; exposes `selectFilter`, `selectOrder`, `advanceSelected`. Derives filtered list and per-stage counts.
- `AdminProductsCubit`: holds all products and the search query; exposes `search`, `upsertProduct`. Derives the filtered list.
- `AdminCustomersCubit`: holds all customers and the search query; exposes `search`. Derives the filtered list.

## Components and Interfaces

### Domain: `OrderStage`

```dart
enum OrderStage {
  ordered,
  measurementDone,
  stitchingStarted,
  stitchingFinished,
  finalTouchUp,
  allSet,
}
```

Extension helpers provide: `label` (display string), `next` (the following stage or null when `allSet`), `advanceActionLabel` (e.g. `Mark as "Measurement done"`), and `color`/`bgColor` (mapped to `AppColors` status conventions — crimson for in-flight stages, green for `allSet`). This enum is admin-specific and intentionally separate from the customer-facing `OrderStatus` enum so the existing customer flow is untouched.

### Domain: `AdminRepository`

```dart
abstract interface class AdminRepository {
  Future<DashboardSummary> loadDashboard();
  Future<List<AdminOrder>> loadOrders();
  Future<List<AdminProduct>> loadProducts();
  Future<List<AdminCustomer>> loadCustomers();
}
```

`MockAdminRepository` returns futures that resolve from seeded in-memory lists built to match the sample data in the designs (orders #SN-1036…#SN-1048, the 10 products, the 8 customers). Mutations for this iteration are held in cubit state rather than pushed back through the repository; repository write methods will be added when Firebase is wired.

### Key entities

- `AdminOrder`: `id`, `item` (name), `customerName`, `customerPhone`, `customerAddress`, `placedDate`, `dueDate`, `amountAtShopInr`, `stage` (`OrderStage`), `measurementState` (enum `entered` / `notSure`), `measurementNote`.
- `AdminProduct`: `id`, `name`, `category` (reuse `CategoryKind`), `priceInr`, `stitchDays`, `rating`, `photoCount`, `visibility` (enum `live` / `hidden`), `description`.
- `AdminCustomer`: `id`, `name`, `mobile`, `email` (nullable), `gender` (reuse `Gender`), `type` (enum `guest` / `registered`), `orderCount`, `lastOrderDate`.
- `DashboardSummary`: `totalOrders`, `newToday`, `newTodayNote`, `inProgress`, `inProgressNote`, `readyToCollect`, `readyNote`, `stageCounts` (`Map<OrderStage,int>`), `recentOrders` (`List<AdminOrder>`).

### Presentation widgets

- `AdminSidebar`: brand mark + "ADMIN" badge, destination list with active highlight and optional "new" badge on Orders, "Sign out" pinned to the bottom.
- `AdminSummaryCard`: label, large value, caption; used in the wide top row and the narrow 2×2 grid.
- `StageCountCard`: stage name, count, and a top progress bar tinted by the stage color.
- `RecentOrdersTable` / `ProductTable` / `CustomerTable`: `DataTable`-based (or `Table`) wide views that collapse to stacked `SectionCard` tiles in the narrow layout.
- `AdminOrderListTile`: `#SN-xxxx · Item`, customer · due, trailing `StatusBadge` (reused) tinted by stage.
- `AdminOrderDetailPanel`: order header, price line, customer card, measurements note, and `StageStepper`.
- `StageStepper`: vertical list of the six stages with the current one marked, plus the advance `PrimaryButton` (hidden at `allSet`).

### Reuse of existing shared widgets

- `StatusBadge` for stage labels and Live/Hidden/Guest/Registered badges (extended with the needed color variants).
- `FilterChips` for the Orders stage filter (labels include counts).
- `SectionCard` for grouped panels and narrow-layout table rows.
- `PrimaryButton` for advance-stage and form Save actions.
- `AppColors` / `AppSpacing` for all styling; no new hard-coded colors.

## Data Models

Mock seed data mirrors the designs:

- **Orders** (6 in the Orders list, more referenced on the dashboard): e.g. `#SN-1047` Formal Shirt, Rahul Verma, due 30 Oct, ₹550 at shop, stage `ordered`, measurement `notSure` with the shop note; `#SN-1045` Salwar Suit, stage `measurementDone`; `#SN-1041` Kurta Pajama, stage `stitchingStarted`; etc.
- **Stage counts** for the dashboard: Ordered 5, Measurement done 4, Stitching started 7, Stitching finished 3, Final touch-up 2, All set 6.
- **Summary**: Total 27, New today 3, In progress 12, Ready to collect 6.
- **Products**: the 10 rows from the Products table (Designer Blouse … Kids Kurta Set) with category, price, stitch time, rating, photo count, and visibility (Sherwani = Hidden).
- **Customers**: the 8 rows from the Customers table with mobile, email (some `—`), gender, type, order count, and last-order date.

## Error Handling

- Cubits emit a `failure` state with a message if a repository future throws; screens render an inline error with a retry affordance (consistent with existing cubits). With mock data this path is effectively unreachable but is implemented for parity.
- The Add/Edit Product form validates locally: empty name or non-positive price produces an inline message and blocks save (Requirement 4.8). Numeric fields guard against non-numeric input.
- Advancing a stage at `allSet` is not offered; `OrderStage.next` returning null drives the hidden button (Requirements 3.8, 3.6).
- Empty filtered results (e.g. a stage with zero orders, or a search with no matches) render an empty-state message rather than a blank panel.

## Testing Strategy

- **Unit tests** for `OrderStage` helpers (`next`, `label`, `advanceActionLabel`, `color`) covering every stage including `allSet.next == null`.
- **Cubit tests** (`bloc_test`) for:
  - `AdminOrdersCubit`: filtering by each stage, selecting an order, advancing a stage updates stage + recomputes counts, advance is a no-op at `allSet`.
  - `AdminProductsCubit`: case-insensitive search, upsert adds a new product and updates an existing one.
  - `AdminCustomersCubit`: case-insensitive name/mobile search.
  - `AdminDashboardCubit`: loads summary; `advanceStage` updates the relevant order.
- **Greeting logic**: a pure function `greetingFor(DateTime)` unit-tested at the four boundaries (05:00, 12:00, 17:00, 21:00) per Requirement 2.2.
- **Widget smoke tests** (optional) verifying each screen builds in both wide and narrow constraints without overflow.
- Property-based tests (`glados`) optional for the greeting function (any time maps to exactly one greeting) and for filter invariants (filtered count equals the chip count).

## Correctness Properties

These properties hold for any seed data and any sequence of in-memory interactions.

### Property 1: Greeting totality and exclusivity
For every `DateTime`, `greetingFor` returns exactly one of the four Greeting strings, with boundaries at 05:00, 12:00, 17:00, and 21:00.

**Validates: Requirements 2.2**

### Property 2: Stage monotonicity
`advanceSelected`/`advanceStage` moves an order's stage strictly forward through `OrderStage` order and never past `allSet`; it is a no-op when the order is already `allSet`.

**Validates: Requirements 3.7, 3.8**

### Property 3: Filter soundness
Every order shown under a non-"All" Stage_Filter has `stage == selectedFilter`; under "All" the shown set equals the full order set.

**Validates: Requirements 3.2, 3.3**

### Property 4: Count consistency
Each Stage_Filter chip's count equals the number of orders with that stage, and the sum of per-stage counts equals the total order count.

**Validates: Requirements 3.1**

### Property 5: Search soundness
Every row shown for a non-empty product or customer query contains the query (case-insensitive) in the searched field(s); an empty query shows all rows.

**Validates: Requirements 4.2, 4.3, 5.4, 5.5**

### Property 6: Upsert integrity
After `upsertProduct(p)`, the product list contains exactly one product with `p.id` whose values equal `p`; existing products with other ids are unchanged, and list length changes by at most one.

**Validates: Requirements 4.9**

### Property 7: Default selection
On a Wide_Layout with a non-empty filtered list and no explicit selection, the first order in the filtered list is selected.

**Validates: Requirements 3.9**

### Property 8: Badge mapping
A product renders a "Live"/"Hidden" badge iff its visibility is `live`/`hidden`; a customer renders "Guest"/"Registered" iff its type is `guest`/`registered`.

**Validates: Requirements 4.4, 5.3**
