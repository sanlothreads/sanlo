# Requirements Document

## Introduction

This feature adds an authorization gate in front of the admin area of the app. Today the admin section is reachable through the admin `StatefulShellRoute` in `lib/core/router/app_router.dart`, and admin identity is decided at splash time only. That leaves every admin route exposed to deep links, hot reload/refresh, and direct navigation by users who are not admins.

The Admin Access Guard enforces an admin check on the entire `/admin/...` subtree at the point of navigation, not just once at startup. The check uses `AdminAccessRepository.isAdmin(mobile)` (a Firebase Realtime Database lookup that normalizes the mobile number and fails closed) against the signed-in user's mobile from `AuthState.user?.mobile`. While the asynchronous check resolves, a loading indicator is shown so admin content never flashes. Users who are not admins, and users who are unauthenticated or guests, are sent to a new dedicated top-level `/access-denied` route. Any error in the lookup is treated as "not admin".

The scope is strictly authorization and route guarding. This feature does not redesign authentication, the admin screens, or the admin data layer. The existing splash-time admin routing must continue to work unchanged.

**Recorded tradeoff:** The Access Denied page offers a single, non-context-aware "Go to Home" action. A user who was blocked because they are unauthenticated or a guest therefore also lands on Home rather than on Sign in. This is an accepted simplification for this feature.

## Glossary

- **Admin_Guard**: The authorization component that evaluates admin access before an admin route is displayed and performs the redirect or loading behavior described in these requirements.
- **Admin_Route**: Any route in the `/admin/...` subtree, comprising `adminDashboard` (`/admin/dashboard`), `adminOrders` (`/admin/orders`), `adminProducts` (`/admin/products`), `adminCustomers` (`/admin/customers`), and the nested `adminProductNew` (`/admin/products/new`) and `adminProductEdit` (`/admin/products/:id/edit`).
- **Admin_Entry**: Any way an Admin_Route becomes active, including deep links, hot reload or refresh, direct navigation, and in-app navigation.
- **Admin_Check**: The asynchronous evaluation `AdminAccessRepository.isAdmin(mobile)`, a Firebase Realtime Database lookup that normalizes the mobile number and fails closed.
- **Access_Denied_Page**: The screen shown at the `/access-denied` route (`Routes.accessDeniedName = 'accessDenied'`).
- **Authenticated_User**: A signed-in, non-guest user, as defined by `AuthState.isAuthenticated` being true.
- **Guest_User**: A signed-in user whose `isGuest` property is true.
- **Unauthenticated_User**: A user for whom `AuthState.isAuthenticated` is false, including guests and users with no signed-in session.
- **Home_Route**: The existing route named `home` (`/home`).

## Requirements

### Requirement 1: Enforce admin check on every admin route and entry point

**User Story:** As a shop owner, I want admin access enforced on every admin route and entry point, so that only admins can view admin screens regardless of how the route is reached.

#### Acceptance Criteria

1. WHEN an Admin_Entry activates any Admin_Route, THE Admin_Guard SHALL evaluate the Admin_Check before the requested Admin_Route content is displayed.
2. THE Admin_Guard SHALL apply the evaluation in Requirement 1.1 to `adminDashboard`, `adminOrders`, `adminProducts`, `adminCustomers`, `adminProductNew`, and `adminProductEdit`.
3. WHEN an Admin_Route is activated by a deep link, THE Admin_Guard SHALL evaluate the Admin_Check before the requested Admin_Route content is displayed.
4. WHEN an Admin_Route is activated by a hot reload or refresh, THE Admin_Guard SHALL evaluate the Admin_Check before the requested Admin_Route content is displayed.
5. WHEN an Admin_Route is activated by direct navigation, THE Admin_Guard SHALL evaluate the Admin_Check before the requested Admin_Route content is displayed.

### Requirement 2: Loading state during the async admin check

**User Story:** As an admin, I want a loading indicator while my admin access is being verified, so that admin content is never shown before the check completes.

#### Acceptance Criteria

1. WHILE the Admin_Check for an activated Admin_Route is unresolved, THE Admin_Guard SHALL display a loading indicator.
2. WHILE the Admin_Check for an activated Admin_Route is unresolved, THE Admin_Guard SHALL withhold the requested Admin_Route content from display.
3. WHEN the Admin_Check resolves to admin, THE Admin_Guard SHALL display the requested Admin_Route content.

### Requirement 3: Redirect non-admin users to Access Denied

**User Story:** As a shop owner, I want non-admin signed-in users redirected away from admin routes, so that regular customers cannot reach the admin area.

#### Acceptance Criteria

1. WHEN an Authenticated_User activates an Admin_Route and the Admin_Check resolves to not admin, THE Admin_Guard SHALL redirect the Authenticated_User to the `/access-denied` route.
2. WHEN the Admin_Guard redirects an Authenticated_User to the `/access-denied` route, THE Admin_Guard SHALL withhold the requested Admin_Route content from display.

### Requirement 4: Redirect unauthenticated and guest users to Access Denied

**User Story:** As a shop owner, I want unauthenticated and guest users blocked from admin routes, so that only signed-in admins reach the admin area.

#### Acceptance Criteria

1. WHEN an Unauthenticated_User activates an Admin_Route, THE Admin_Guard SHALL redirect the Unauthenticated_User to the `/access-denied` route.
2. WHEN a Guest_User activates an Admin_Route, THE Admin_Guard SHALL redirect the Guest_User to the `/access-denied` route.
3. WHEN the Admin_Guard redirects an Unauthenticated_User or a Guest_User to the `/access-denied` route, THE Admin_Guard SHALL withhold the requested Admin_Route content from display.

### Requirement 5: Fail closed on admin lookup error

**User Story:** As a shop owner, I want the admin check to fail closed on error, so that a lookup failure never grants admin access.

#### Acceptance Criteria

1. IF the Admin_Check for an activated Admin_Route completes with an error, THEN THE Admin_Guard SHALL redirect the requesting user to the `/access-denied` route.
2. IF the Admin_Check for an activated Admin_Route completes with an error, THEN THE Admin_Guard SHALL withhold the requested Admin_Route content from display.

### Requirement 6: Access Denied page content and Go to Home action

**User Story:** As a blocked user, I want a clear Access Denied page with a way back to a known screen, so that I understand I lack permission and can continue using the app.

#### Acceptance Criteria

1. THE Access_Denied_Page SHALL be registered as a top-level route with path `/access-denied` and name `accessDenied`.
2. WHEN the Access_Denied_Page is displayed, THE Access_Denied_Page SHALL present the message "Access Denied — you don't have permission to access this page".
3. WHEN the Access_Denied_Page is displayed, THE Access_Denied_Page SHALL present a single action labelled "Go to Home".
4. WHEN the user selects the "Go to Home" action, THE Access_Denied_Page SHALL navigate to the Home_Route via `context.goNamed(homeName)`.

### Requirement 7: Preserve existing splash-time admin routing (no regression)

**User Story:** As a maintainer, I want the existing splash-time admin routing preserved, so that adding the guard introduces no regression to the current startup flow.

#### Acceptance Criteria

1. WHEN an admin signs in and the splash-time routing directs the admin to an Admin_Route, THE Admin_Guard SHALL display the requested Admin_Route content after the Admin_Check resolves to admin.
2. THE Admin_Guard SHALL preserve the existing splash-time admin routing behavior for non-admin and admin users without modifying the authentication flow or the admin screens.
