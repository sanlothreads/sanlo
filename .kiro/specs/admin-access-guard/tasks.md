# Implementation Plan: Admin Access Guard

## Overview

Add an authorization gate in front of the entire `/admin/...` subtree. The work is purely route-guarding: new route constants, a new `AccessDeniedScreen`, a top-level `/access-denied` route, and an in-tree stateful `_AdminGuard` that wraps `AdminShellHost` inside the admin `StatefulShellRoute.indexedStack` builder. The guard mirrors the existing `_OrderGuard` precedent — runs the async `AdminAccessRepository.isAdmin(mobile)` check in `initState`, shows a loading indicator while unresolved, renders the admin shell on success, and schedules a post-frame redirect to `/access-denied` on any deny outcome (fail closed). No production edits to the splash screen, auth flow, or admin screens. Tasks build incrementally: route constants → screen → top-level route → guard → wiring → tests → final verification.

## Tasks

- [x] 1. Add Access Denied route constants
  - In `lib/core/router/app_routes.dart`, add `static const String accessDeniedPath = '/access-denied';` and `static const String accessDeniedName = 'accessDenied';` to the `Routes` class, grouped with the other top-level route constants.
  - _Requirements: 6.1_
  - _Design: Route constants (`app_routes.dart`)_

- [x] 2. Create the AccessDeniedScreen
  - [x] 2.1 Implement `AccessDeniedScreen`
    - Create `lib/features/admin/presentation/screens/access_denied_screen.dart` as a `StatelessWidget`.
    - Render a `Scaffold` with `AppColors.scaffoldBackground`, a centered `Column` (mainAxisSize `min`) inside `SafeArea` + `Padding(AppSpacing.lg)`: a lock icon, the exact message text `"Access Denied — you don't have permission to access this page"` (centered, `titleMedium`), spacing, and a single `PrimaryButton` labelled `'Go to Home'` whose `onPressed` calls `context.goNamed(Routes.homeName)`.
    - Reuse `PrimaryButton`, `AppColors`, and `AppSpacing`; use the import paths shown in the design.
    - _Requirements: 6.2, 6.3, 6.4_
    - _Design: `AccessDeniedScreen` (new screen)_

  - [x] 2.2 Write widget tests for AccessDeniedScreen content and navigation
    - Pump `AccessDeniedScreen` and assert the exact message text is present and exactly one `PrimaryButton` labelled "Go to Home" exists. (Req 6.2, 6.3)
    - Drive a minimal router, tap "Go to Home", and assert the current location is `Routes.homePath`. (Req 6.4)
    - _Requirements: 6.2, 6.3, 6.4_
    - _Design: Testing Strategy — unit/widget tests 9, 10_

- [x] 3. Register the top-level /access-denied route
  - In `lib/core/router/app_router.dart`, add a `GoRoute` with `path: Routes.accessDeniedPath`, `name: Routes.accessDeniedName`, and `builder` returning `const AccessDeniedScreen()`, as a sibling of the other top-level routes (not nested under the admin shell). Add the import for `AccessDeniedScreen`.
  - _Requirements: 6.1_
  - _Design: Top-level route (`app_router.dart`)_

- [x] 4. Implement the _AdminGuard gate
  - [x] 4.1 Add `_AdminAccess` enum, `_AdminGuardLoading`, and `_AdminGuard` to app_router.dart
    - In `lib/core/router/app_router.dart`, add the private `enum _AdminAccess { pending, granted, denied }`.
    - Add the private `_AdminGuardLoading` `StatelessWidget` returning a `Scaffold` with a centered `CircularProgressIndicator`.
    - Add the private `_AdminGuard` `StatefulWidget` taking a required `Widget child`. In `initState`, read `AuthBloc` state via `context.read<AuthBloc>().state`; if `!auth.isAuthenticated`, set `_access = denied` and return (no Firebase lookup for unauthenticated/guest). Otherwise call `_resolve(auth.user?.mobile)`.
    - Implement `Future<void> _resolve(String? mobile)` that reads `AdminAccessRepository`, awaits `isAdmin(mobile)`, and — guarded by `mounted` — sets `_access` to `granted`/`denied`; on any caught error sets `_access = denied` (fail closed).
    - Implement `build`: `granted` → `widget.child`; `pending` → `_AdminGuardLoading`; `denied` → schedule `addPostFrameCallback` that calls `context.goNamed(Routes.accessDeniedName)` guarded by `context.mounted`, and return `_AdminGuardLoading` (withhold admin content).
    - Mirror the existing `_OrderGuard` precedent for structure and safety (no navigation during build, `mounted`/`context.mounted` guards).
    - _Requirements: 1.1, 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 4.2, 4.3, 5.1, 5.2_
    - _Design: `_AdminGuard`, `_AdminGuardLoading`; Error Handling table_

- [x] 5. Wrap AdminShellHost with the guard
  - [x] 5.1 Wire _AdminGuard into the admin StatefulShellRoute builder
    - In `lib/core/router/app_router.dart`, change the admin `StatefulShellRoute.indexedStack` `builder` so it returns `_AdminGuard(child: AdminShellHost(navigationShell: navigationShell))`. Leave all four branches (dashboard/orders/products/customers) and the nested product-form routes unchanged.
    - This single wrapper gates all admin tabs and nested product routes with one guard instance per admin-area activation.
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
    - _Design: Where the guard attaches (single wrapper covers everything)_

- [x] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Guard behavior tests
  - [x] 7.1 Set up the guard test harness
    - Create the widget-test harness mirroring `test/features/orders/order_flow_test.dart`: build the real `appRouter` (or a minimal `GoRouter` exercising the admin location through `_AdminGuard`), provide `AdminAccessRepository` via `RepositoryProvider.value` using `MockAdminAccessRepository`, and provide an `AuthBloc`/`MockAuthBloc` (via `bloc_test`/`mocktail`) above `MaterialApp.router`. Drive navigation with `pumpAndSettle`.
    - _Requirements: 1.1_
    - _Design: Testing Strategy — harness note_

  - [x] 7.2 Admin resolves → shell shown
    - Signed-in admin mobile; `pumpAndSettle`; assert the admin shell/sentinel child is present.
    - _Requirements: 2.3, 7.1_
    - _Design: Testing Strategy — unit/widget test 1_

  - [x] 7.3 Loading before resolution
    - Inject a repository whose `isAdmin` future never completes (non-completing `Completer().future`); `pump` one frame; assert a `CircularProgressIndicator` is shown and no admin child.
    - _Requirements: 2.1, 2.2_
    - _Design: Testing Strategy — unit/widget test 2_

  - [x] 7.4 Non-admin → redirect
    - Authenticated non-admin mobile; assert navigation to `accessDenied` and no admin child.
    - _Requirements: 3.1, 3.2_
    - _Design: Testing Strategy — unit/widget test 3_

  - [x] 7.5 Guest → redirect without lookup
    - Guest `AuthState`; assert redirect to `accessDenied` and that `isAdmin` was never called (`verifyNever`).
    - _Requirements: 4.2, 4.3_
    - _Design: Testing Strategy — unit/widget test 4_

  - [x] 7.6 Unauthenticated → redirect without lookup
    - No-session `AuthState`; assert redirect to `accessDenied` and that `isAdmin` was never called (`verifyNever`).
    - _Requirements: 4.1, 4.3_
    - _Design: Testing Strategy — unit/widget test 5_

  - [x] 7.7 Error → redirect (fail closed)
    - `mocktail` stub makes `isAdmin` throw; assert redirect to `accessDenied` and no admin child.
    - _Requirements: 5.1, 5.2_
    - _Design: Testing Strategy — unit/widget test 6_

  - [x] 7.8 Deep-link entry gated
    - Set router `initialLocation` to `adminDashboardPath` with a non-admin user; assert redirect to `accessDenied` (covers deep-link; direct/refresh entries share the same `initState` path).
    - _Requirements: 1.3, 1.4, 1.5_
    - _Design: Testing Strategy — unit/widget test 7_

  - [x] 7.9 Nested product-new route gated by single wrapper
    - Navigate to `adminProductNewPath` with a non-admin user; assert redirect to `accessDenied`, demonstrating the single wrapper gates nested routes too.
    - _Requirements: 1.2_
    - _Design: Testing Strategy — unit/widget test 8_

- [x] 8. Correctness property tests
  - [x] 8.1 Property 1 — Admin content shown iff authenticated admin
    - **Property 1: Admin content shown iff authenticated admin**
    - **Tag: Feature: admin-access-guard, Property 1: Admin content shown iff authenticated admin**
    - Parameterized widget test over `{pending, admin, non-admin, unauthenticated, guest, error}`. Assert the sentinel admin child is present iff the case is `admin` after resolution; otherwise assert it is absent and a `CircularProgressIndicator` is shown.
    - **Validates: Requirements 1.1, 2.2, 2.3, 3.2, 4.3, 5.2**
    - _Design: Correctness Properties — Property 1; Testing Strategy — Property tests_

  - [x] 8.2 Property 2 — Every deny outcome routes to Access Denied
    - **Property 2: Every deny outcome routes to Access Denied**
    - **Tag: Feature: admin-access-guard, Property 2: Every deny outcome routes to Access Denied**
    - Parameterized widget test over the four deny cases `{non-admin, unauthenticated, guest, error}`; after `pumpAndSettle`, assert the router's current location is `Routes.accessDeniedPath`.
    - **Validates: Requirements 3.1, 4.1, 4.2, 5.1**
    - _Design: Correctness Properties — Property 2; Testing Strategy — Property tests_

- [x] 9. No-regression check for splash-time routing
  - Re-run the existing splash routing tests unchanged to confirm admins are still routed to `adminDashboard` and non-admins to Home.
  - _Requirements: 7.1, 7.2_
  - _Design: No regression to splash-time routing (Requirement 7)_

- [x] 10. Final verification
  - Run `flutter analyze` and confirm 0 new errors.
  - Run `flutter test` and confirm all tests pass.
  - Confirm no production edits were made to `splash_screen.dart`, the auth flow, or any admin screen (only the three in-scope files were changed: `app_routes.dart`, `app_router.dart`, and the new `access_denied_screen.dart`).
  - _Requirements: 7.2_
  - _Design: Scope of changes_

## Notes

- Tasks marked with `*` are optional (tests and the final verification) and can be skipped for a faster MVP; core implementation tasks are never optional.
- Each task references specific requirement sub-clauses and the design section it satisfies for traceability.
- The checkpoint ensures incremental validation after the guard and wiring are in place.
- Property tests validate the two universal correctness properties; the enumerable parameterized cases cover the finite auth-state × check-outcome input space.
- The design uses a specific language (Dart/Flutter), so no implementation-language selection was required.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1", "2.1"] },
    { "id": 1, "tasks": ["2.2", "3", "4.1"] },
    { "id": 2, "tasks": ["5.1"] },
    { "id": 3, "tasks": ["7.1"] },
    { "id": 4, "tasks": ["7.2", "7.3", "7.4", "7.5", "7.6", "7.7", "7.8", "7.9", "8.1", "8.2", "9"] },
    { "id": 5, "tasks": ["10"] }
  ]
}
```
