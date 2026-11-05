import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/admin/data/repositories/firebase_admin_access_repository.dart';
import '../../features/admin/data/repositories/mock_admin_repository.dart';
import '../../features/admin/domain/repositories/admin_access_repository.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/catalog/data/repositories/mock_product_repository.dart';
import '../../features/catalog/domain/repositories/product_repository.dart';
import '../../features/orders/data/repositories/mock_order_repository.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/profile/data/repositories/mock_profile_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';

/// Composition root for the app.
///
/// Constructed once (near the top of the widget tree) and holds the four
/// repositories as their domain *interfaces*. Presentation code is handed
/// these interfaces via `RepositoryProvider`, so it never references the
/// concrete `Mock*` classes (Requirement 8.1).
///
/// Each repository is a single shared instance kept alive for the lifetime of
/// this locator. In particular [orderRepository] must not be reconstructed
/// per-use: a placed order is stored in the mock's in-memory list, so sharing
/// one instance is what makes a newly placed order visible to the
/// tracking / "My orders" screens within the same session.
///
/// Swapping the mocks for real API-backed implementations is a one-line change
/// per repository here (e.g. `MockAuthRepository()` -> `ApiAuthRepository(...)`);
/// no presentation or domain code needs to change because it depends only on
/// the interfaces exposed below.
class ServiceLocator {
  /// Wires each repository to its domain interface.
  ///
  /// Authentication defaults to the Firebase-backed [FirebaseAuthRepository];
  /// pass [authRepository] (e.g. a [MockAuthRepository]) to override it, which
  /// is how widget tests run without a live Firebase. The catalog, orders, and
  /// profile repositories remain in-memory mocks for now.
  ServiceLocator({
    AuthRepository? authRepository,
    AdminAccessRepository? adminAccessRepository,
  }) : authRepository = authRepository ?? FirebaseAuthRepository(),
       adminAccessRepository =
           adminAccessRepository ?? FirebaseAdminAccessRepository(),
      productRepository = MockProductRepository(),
      orderRepository = MockOrderRepository(),
      profileRepository = MockProfileRepository(),
      adminRepository = MockAdminRepository();

  /// Authentication: OTP sign-in, account creation, guest sessions.
  final AuthRepository authRepository;

  /// Catalog: categories and tailoring styles.
  final ProductRepository productRepository;

  /// Orders: listing, placing, and tracking. Shared instance so placed orders
  /// persist for the session.
  final OrderRepository orderRepository;

  /// Profile: the signed-in customer's details and order stats.
  final ProfileRepository profileRepository;

  /// Admin: dashboard summary, orders, products, and customers (mock-seeded).
  final AdminRepository adminRepository;

  /// Admin access gate: checks a signed-in mobile against the Firebase
  /// `admin` node. Firebase-backed by default; override for tests.
  final AdminAccessRepository adminAccessRepository;
}
