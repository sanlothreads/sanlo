/// Centralized route path and name constants for the app's `GoRouter`.
///
/// Paths are used to configure `GoRoute.path` / `initialLocation`; names are
/// used by screens when navigating via `context.goNamed` / `context.pushNamed`.
/// Keeping both in one place avoids stringly-typed drift between the router
/// configuration and the navigation call sites.
abstract final class Routes {
  // --- Splash ---------------------------------------------------------------
  static const String splashPath = '/';
  static const String splashName = 'splash';

  // --- Auth -----------------------------------------------------------------
  static const String signInPath = '/signin';
  static const String signInName = 'signIn';

  static const String signUpPath = '/signup';
  static const String signUpName = 'signUp';

  // --- Bottom-nav shell tabs ------------------------------------------------
  static const String homePath = '/home';
  static const String homeName = 'home';

  static const String ordersPath = '/orders';
  static const String ordersName = 'myOrders';

  static const String profilePath = '/profile';
  static const String profileName = 'profile';

  // --- Catalog --------------------------------------------------------------
  static const String productDetailsPath = '/product/:id';
  static const String productDetailsName = 'productDetails';

  // --- Order sub-flow (single PlaceOrderBloc across these three steps) ------
  static const String orderDetailsPath = '/order/details';
  static const String orderDetailsName = 'orderDetails';

  static const String orderMeasurementsPath = '/order/measurements';
  static const String orderMeasurementsName = 'orderMeasurements';

  static const String orderReviewPath = '/order/review';
  static const String orderReviewName = 'orderReview';

  // --- Order outcome --------------------------------------------------------
  static const String orderPlacedPath = '/order/placed';
  static const String orderPlacedName = 'orderPlaced';

  static const String orderTrackingPath = '/order/tracking/:id';
  static const String orderTrackingName = 'orderTracking';

  // --- Access denied (authorization gate target) ----------------------------
  static const String accessDeniedPath = '/access-denied';
  static const String accessDeniedName = 'accessDenied';

  // --- Admin shell tabs -----------------------------------------------------
  static const String adminDashboardPath = '/admin/dashboard';
  static const String adminDashboardName = 'adminDashboard';

  static const String adminOrdersPath = '/admin/orders';
  static const String adminOrdersName = 'adminOrders';

  static const String adminProductsPath = '/admin/products';
  static const String adminProductsName = 'adminProducts';

  static const String adminCustomersPath = '/admin/customers';
  static const String adminCustomersName = 'adminCustomers';

  // --- Admin product form (add / edit) --------------------------------------
  static const String adminProductNewPath = '/admin/products/new';
  static const String adminProductNewName = 'adminProductNew';

  static const String adminProductEditPath = '/admin/products/:id/edit';
  static const String adminProductEditName = 'adminProductEdit';
}
