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
}
