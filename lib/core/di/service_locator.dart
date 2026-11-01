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
  /// Wires each concrete mock repository to its domain interface.
  ServiceLocator()
      : authRepository = MockAuthRepository(),
        productRepository = MockProductRepository(),
        orderRepository = MockOrderRepository(),
        profileRepository = MockProfileRepository();

  /// Authentication: OTP sign-in, account creation, guest sessions.
  final AuthRepository authRepository;

  /// Catalog: categories and tailoring styles.
  final ProductRepository productRepository;

  /// Orders: listing, placing, and tracking. Shared instance so placed orders
  /// persist for the session.
  final OrderRepository orderRepository;

  /// Profile: the signed-in customer's details and order stats.
  final ProfileRepository profileRepository;
}
