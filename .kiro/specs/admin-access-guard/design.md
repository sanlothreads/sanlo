# Design Document

## Overview

The Admin Access Guard adds an authorization gate in front of the entire `/admin/...` subtree. It enforces `AdminAccessRepository.isAdmin(mobile)` at the point of navigation — on every entry (deep link, refresh, direct, in-app) — rather than only once at splash time.

The central design tension is that go_router's `redirect` callback is **synchronous** and cannot `await` `AdminAccessRepository.isAdmin` (a `Future`-returning Firebase Realtime Database lookup). The codebase already solved an analogous async/stateful gating problem with the in-tree `_OrderGuard` widget in `lib/core/router/app_router.dart`, which evaluates a condition and schedules a post-frame `context.goNamed(...)` while rendering a placeholder. We follow that precedent: a stateful `_AdminGuard` widget that runs the async check in `initState`, shows a loading indicator while unresolved, renders the admin shell on success, and schedules a post-frame redirect to `/access-denied` on any deny outcome.

This is purely an authorization/route-guarding change. It does not modify authentication, admin screens, or the admin data layer. Splash-time routing stays exactly as-is; the guard simply re-verifies after the splash has routed (Requirement 7).

### Scope of changes

| File | Change |
| --- | --- |
| `lib/core/router/app_routes.dart` | Add `accessDeniedPath` / `accessDeniedName` constants (Req 6.1). |
| `lib/core/router/app_router.dart` | Add `_AdminGuard` stateful widget; wrap `AdminShellHost` with it inside the admin `StatefulShellRoute.indexedStack` builder; add a top-level `/access-denied` `GoRoute` (Req 1, 2, 3, 4, 5, 6.1). |
| `lib/features/admin/presentation/screens/access_denied_screen.dart` | New `AccessDeniedScreen` widget (Req 6.2–6.4). |

No production edits to `splash_screen.dart`, `admin_shell_host.dart`, the auth flow, or any admin screen (Req 7.2).

## Architecture

### Where the guard attaches (single wrapper covers everything)

The admin area is one `StatefulShellRoute.indexedStack` whose `builder` returns `AdminShellHost(navigationShell: ...)`. All four admin tabs and the nested product-form routes (`new`, `:id/edit`) live inside that shell's branches. Wrapping the **builder's returned host** — not each branch — means a single guard instance gates every admin route and tab, including the nested product form routes (Req 1.2).

```dart
// Admin 4-tab shell (app_router.dart) — builder only; branches unchanged.
StatefulShellRoute.indexedStack(
  builder: (BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) =>
      _AdminGuard(
        child: AdminShellHost(navigationShell: navigationShell),
      ),
  branches: <StatefulShellBranch>[ /* unchanged dashboard/orders/products/customers */ ],
),
```

Because the shell builder runs for any location in the subtree, the guard's `initState` fires on first activation of the admin area regardless of entry mechanism — deep link, hot reload/refresh, direct navigation, or in-app navigation (Req 1.3–1.5). Navigating between admin tabs reuses the same shell (and the same guard State), so the check runs once per admin-area activation, matching the `_OrderGuard` precedent.

### Why a widget, not `redirect`

`redirect` is synchronous and would have to resolve `isAdmin` without awaiting — impossible for a `Future`. A redirect also has no way to render the loading indicator required by Requirement 2. The in-tree widget approach is the established pattern (`_OrderGuard`) for exactly this reason, and it is the only approach that satisfies Req 2.1 (loading state) together with Req 1 (async check before content).

### Obtaining the repository and auth state

Both the `AdminAccessRepository` and the `AuthBloc` are provided **above** the router in `app.dart`:

- `RepositoryProvider<AdminAccessRepository>.value(...)` (in `MultiRepositoryProvider`)
- `BlocProvider<AuthBloc>(...)`

They are therefore ancestors of every route the router builds. `splash_screen.dart` already resolves the repository this way (`context.read<AdminAccessRepository>()`), and `admin_shell_host.dart` already reads both (`context.read<AdminAccessRepository>()` and `context.read<AuthBloc>().state.user?.mobile`). The guard reads them identically inside `initState`:

```dart
final AuthState auth = context.read<AuthBloc>().state;
final AdminAccessRepository access = context.read<AdminAccessRepository>();
```

This confirms availability and keeps the guard consistent with existing call sites — no new provider wiring is required.

## Components and Interfaces

### `_AdminGuard` (private `StatefulWidget` in `app_router.dart`)

Mirrors `_OrderGuard`'s role but is stateful because it holds the resolution of an async check and must avoid re-running it on rebuild.

```dart
/// Authorization gate for the entire /admin/... subtree.
///
/// `redirect` is synchronous and cannot await AdminAccessRepository.isAdmin,
/// and it cannot render a loading indicator. So — mirroring _OrderGuard — the
/// gate lives in the widget tree. On first build it short-circuits
/// unauthenticated/guest users, otherwise kicks off the async admin check in
/// initState. While unresolved it shows a spinner; on "admin" it renders the
/// admin shell child; on not-admin / error / unauthenticated / guest it
/// schedules a post-frame redirect to /access-denied. Fails closed on error.
class _AdminGuard extends StatefulWidget {
  const _AdminGuard({required this.child});
  final Widget child; // AdminShellHost(navigationShell: ...)
  @override
  State<_AdminGuard> createState() => _AdminGuardState();
}

/// Tri-state resolution of the admin check.
enum _AdminAccess { pending, granted, denied }

class _AdminGuardState extends State<_AdminGuard> {
  _AdminAccess _access = _AdminAccess.pending;

  @override
  void initState() {
    super.initState();
    final AuthState auth = context.read<AuthBloc>().state;

    // Short-circuit: unauthenticated or guest → deny without a Firebase lookup.
    // isAuthenticated is false for guests and no-session users (Req 4.1, 4.2).
    if (!auth.isAuthenticated) {
      _access = _AdminAccess.denied;
      return; // build() will schedule the redirect
    }

    _resolve(auth.user?.mobile); // async; updates _access via setState
  }

  Future<void> _resolve(String? mobile) async {
    try {
      final AdminAccessRepository access =
          context.read<AdminAccessRepository>();
      final bool isAdmin = await access.isAdmin(mobile);
      if (!mounted) return;
      setState(() => _access =
          isAdmin ? _AdminAccess.granted : _AdminAccess.denied); // Req 3.1, 2.3
    } catch (_) {
      if (!mounted) return;
      setState(() => _access = _AdminAccess.denied); // Fail closed (Req 5.1)
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_access) {
      case _AdminAccess.granted:
        return widget.child; // Req 2.3
      case _AdminAccess.pending:
        return const _AdminGuardLoading(); // Req 2.1, 2.2
      case _AdminAccess.denied:
        // Schedule the redirect after this frame — never navigate during build
        // (mirrors _OrderGuard). Withhold admin content meanwhile.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.goNamed(Routes.accessDeniedName);
          }
        });
        return const _AdminGuardLoading(); // Req 3.2, 4.3, 5.2 (content withheld)
    }
  }
}
```

Key safety points, all taken from the `_OrderGuard` precedent:

- **No navigation during build.** The redirect is deferred with `addPostFrameCallback`.
- **`mounted` / `context.mounted` checks** guard both the `setState` after the async gap and the post-frame navigation, so a guard torn down mid-check never calls `setState` or navigates on a dead element.
- **Fail closed.** Any thrown error in the lookup is caught and treated as `denied` (Req 5.1/5.2).
- **Content is withheld in every non-granted state** — the guard returns the loading view, never `widget.child`, until the check resolves to admin (Req 2.2, 3.2, 4.3, 5.2).

### `_AdminGuardLoading` (private helper)

A minimal full-screen loading view shown while the check is unresolved and during the one-frame window before a scheduled redirect takes effect.

```dart
class _AdminGuardLoading extends StatelessWidget {
  const _AdminGuardLoading();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
```

The `CircularProgressIndicator` picks up the app's primary color from `AppTheme.light`, so no explicit color is needed (Req 2.1).

### `AccessDeniedScreen` (new screen)

**Location:** `lib/features/admin/presentation/screens/access_denied_screen.dart`.

**Justification for the location.** The screen exists solely because of the admin authorization feature and is only ever reached by the admin guard. Placing it alongside the other admin presentation screens keeps the feature cohesive and matches the clean-architecture `features/<feature>/presentation/screens/` convention used throughout the repo. It depends only on core widgets/theme (`PrimaryButton`, `AppColors`, `AppSpacing`) and `Routes`, so it carries no admin-domain coupling despite its folder. A core/global location was considered but rejected: the page is feature-specific, not a shared primitive like `PrimaryButton`.

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';

/// Shown when a user is blocked from the admin area.
///
/// Presents the fixed access-denied message and a single "Go to Home" action
/// that routes to the Home tab. Per the recorded tradeoff in the requirements,
/// the action is non-context-aware: unauthenticated/guest users also land on
/// Home rather than Sign in.
class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.lock_outline,
                    size: 56, color: AppColors.primary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  // Exact message required by Req 6.2.
                  "Access Denied — you don't have permission to access this page",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Go to Home', // Req 6.3 — single action
                  onPressed: () =>
                      context.goNamed(Routes.homeName), // Req 6.4
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

Reuses `PrimaryButton`, `AppColors`, and `AppSpacing` for consistency with the rest of the app (Req 6.3).

### Route constants (`app_routes.dart`)

```dart
// --- Access denied (authorization gate target) ----------------------------
static const String accessDeniedPath = '/access-denied';
static const String accessDeniedName = 'accessDenied';
```

### Top-level route (`app_router.dart`)

Registered as a sibling of the other top-level routes (e.g. next to Product details / Order outcome), so it is reachable from anywhere and never nested under the admin shell it guards (Req 6.1):

```dart
GoRoute(
  path: Routes.accessDeniedPath,
  name: Routes.accessDeniedName,
  builder: (BuildContext context, GoRouterState state) =>
      const AccessDeniedScreen(),
),
```

## Data Models

No new data models. The guard consumes existing types only:

- `AuthState` — `isAuthenticated` (false for guests and no-session users) and `user?.mobile`.
- `AdminAccessRepository.isAdmin(String? mobile) -> Future<bool>` — normalizes the mobile and fails closed; returns `false` for null/empty/non-admin.

The internal `_AdminAccess { pending, granted, denied }` enum is private UI state in `_AdminGuardState`, not a domain model.

## Error Handling

| Condition | Guard behavior | Requirement |
| --- | --- | --- |
| Unauthenticated user | Deny without Firebase lookup; post-frame redirect to `/access-denied` | 4.1, 4.3 |
| Guest user (`isAuthenticated == false`) | Deny without Firebase lookup; redirect | 4.2, 4.3 |
| Authenticated non-admin (`isAdmin == false`) | Deny; redirect | 3.1, 3.2 |
| `isAdmin` throws / future errors | Catch → treat as `denied`; redirect (fail closed) | 5.1, 5.2 |
| Guard disposed mid-check | `mounted` / `context.mounted` guards skip `setState` and navigation | — |
| Admin (`isAdmin == true`) | Render admin shell child | 2.3, 7.1 |

In every deny or pending state, `widget.child` (the admin shell) is never built, so admin content cannot flash before the decision (Req 2.2, 3.2, 4.3, 5.2).

## No regression to splash-time routing (Requirement 7)

`splash_screen.dart` is unchanged. It still awaits its own `AdminAccessRepository.isAdmin(...)` and routes admins to `adminDashboard` and everyone else to Home. When splash routes an admin into the admin shell, the newly-mounted `_AdminGuard` independently re-runs the check and resolves to `granted`, showing the admin shell (Req 7.1). The guard adds a verification step on top of splash routing without altering the authentication flow or any admin screen (Req 7.2). The redundant second lookup is intentional and cheap: it is what closes the deep-link / refresh / direct-navigation gaps that splash-only routing left open.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — a formal statement about what the system should do. Properties bridge human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Admin content shown iff authenticated admin

*For any* combination of authentication state and admin-check outcome, the `_AdminGuard` displays the admin shell child **if and only if** the user is authenticated (non-guest) **and** the admin check resolves to admin; in every other case — unresolved (pending), unauthenticated, guest, not-admin, or lookup error — the guard withholds the admin shell child and shows the loading view instead.

**Validates: Requirements 1.1, 2.2, 2.3, 3.2, 4.3, 5.2**

### Property 2: Every deny outcome routes to Access Denied

*For any* deny outcome — authenticated non-admin, unauthenticated, guest, or lookup error — the `_AdminGuard` schedules a post-frame navigation to the `accessDenied` route and never to any other destination.

**Validates: Requirements 3.1, 4.1, 4.2, 5.1**

## Testing Strategy

Tests use the existing `MockAdminAccessRepository` (seeded admin numbers) and the repo's established `flutter_test` + `bloc_test` + `mocktail` dependencies (already in `pubspec.yaml`). The widget-test harness mirrors `test/features/orders/order_flow_test.dart`: build a minimal `GoRouter` whose admin location wraps a **sentinel child** in `_AdminGuard`, provide `AdminAccessRepository` via `RepositoryProvider.value` and an `AuthBloc` (or a `MockAuthBloc` via `mocktail`/`bloc_test`) above `MaterialApp.router`, then drive navigation and `pumpAndSettle`.

> Note: `_AdminGuard` is private to `app_router.dart`. Tests exercise it through the real `appRouter` by navigating to an admin route, so the private class needs no visibility change.

### Property tests

Both correctness properties are decision invariants over a small, enumerable input space (auth state × check outcome), so they are realized as parameterized widget tests that cover each state rather than randomized generators — consistent with the prework classification.

- **Property 1** — parameterize over `{pending, admin, non-admin, unauthenticated, guest, error}`. For each, assert the sentinel admin child is present **iff** the case is `admin` after resolution; otherwise assert it is absent and a `CircularProgressIndicator` is shown.
  - Tag: **Feature: admin-access-guard, Property 1: Admin content shown iff authenticated admin**
- **Property 2** — parameterize over the four deny cases `{non-admin, unauthenticated, guest, error}`; after `pumpAndSettle`, assert the router's current location is `Routes.accessDeniedPath`.
  - Tag: **Feature: admin-access-guard, Property 2: Every deny outcome routes to Access Denied**

### Unit / widget tests (examples and edge cases)

1. **Admin resolves → shell shown.** Signed-in admin mobile; `pumpAndSettle`; expect the admin shell/sentinel child present. (Req 2.3, 7.1)
2. **Loading before resolution.** Inject a repository whose `isAdmin` future never completes (a `mocktail` stub returning a non-completing `Completer().future`); `pump` one frame; expect `CircularProgressIndicator` and no admin child. (Req 2.1, 2.2)
3. **Non-admin → redirect.** Authenticated non-admin mobile; expect navigation to `accessDenied` and no admin child. (Req 3.1, 3.2)
4. **Guest → redirect, no lookup.** Guest `AuthState`; assert redirect to `accessDenied` and that `isAdmin` was **never** called (`verifyNever`, confirming the short-circuit). (Req 4.2, 4.3)
5. **Unauthenticated → redirect, no lookup.** No-session `AuthState`; same assertions as guest. (Req 4.1, 4.3)
6. **Error → redirect (fail closed).** `mocktail` stub makes `isAdmin` throw; expect redirect to `accessDenied` and no admin child. (Req 5.1, 5.2)
7. **Deep-link entry gated.** Router `initialLocation` set to `adminDashboardPath` with a non-admin user; expect redirect to `accessDenied` (covers Req 1.3; direct/refresh entries 1.4/1.5 share the same `initState` path).
8. **All admin routes covered by one wrapper.** Navigate to `adminProductNewPath` (nested form route) with a non-admin user; expect redirect — demonstrating the single wrapper over `AdminShellHost` gates nested routes too. (Req 1.2)
9. **AccessDeniedScreen content.** Pump `AccessDeniedScreen`; expect the exact message text and exactly one `PrimaryButton` labelled "Go to Home". (Req 6.2, 6.3)
10. **Go to Home navigation.** Tap "Go to Home"; assert current location is `Routes.homePath`. (Req 6.4)

### No-regression check (Req 7.2)

Re-run the existing splash routing tests unchanged to confirm admins are still routed to `adminDashboard` and non-admins to Home, and confirm no production edits were made to the auth flow or admin screens.

Follow the repo convention of ≥100 iterations only where randomized generators are used; the enumerable parameterized cases above run each case once, which fully covers the finite input space.
