import '../../features/admin/data/repositories/firebase_admin_access_repository.dart';
import '../../features/admin/data/repositories/firebase_admin_repository.dart';
import '../../features/admin/domain/repositories/admin_access_repository.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/catalog/data/repositories/firebase_product_repository.dart';
import '../../features/catalog/domain/repositories/product_repository.dart';
import '../../features/orders/data/repositories/firebase_order_repository.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/profile/data/repositories/mock_profile_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';

/// Composition root for the app.
class ServiceLocator {
  /// Wires each repository to its domain interface.
  ServiceLocator({
    AuthRepository? authRepository,
    AdminAccessRepository? adminAccessRepository,
    ProductRepository? productRepository,
    AdminRepository? adminRepository,
    OrderRepository? orderRepository,
  }) : authRepository = authRepository ?? FirebaseAuthRepository(),
       adminAccessRepository =
           adminAccessRepository ?? FirebaseAdminAccessRepository(),
       productRepository = productRepository ?? FirebaseProductRepository(),
       adminRepository = adminRepository ?? FirebaseAdminRepository(),
       orderRepository = orderRepository ?? FirebaseOrderRepository(),
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

  /// Admin: dashboard summary, orders, products, and customers (mock-seeded).
  final AdminRepository adminRepository;

  /// Admin access gate: checks a signed-in mobile against the Firebase
  /// `admin` node. Firebase-backed by default; override for tests.
  final AdminAccessRepository adminAccessRepository;
}
