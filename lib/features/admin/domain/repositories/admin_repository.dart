import '../entities/admin_customer.dart';
import '../entities/admin_order.dart';
import '../entities/admin_product.dart';
import '../entities/dashboard_summary.dart';

/// Read-side interface for the admin workspace.
///
/// The presentation layer depends only on this interface; the current
/// [MockAdminRepository] serves seeded in-memory data. When the Firebase
/// Realtime Database is wired, a `FirebaseAdminRepository` replaces the mock
/// in the composition root with no change to cubits or screens. Write
/// operations (advancing a stage, upserting a product) are held in cubit state
/// for this UI-only iteration and will be added here when persistence lands.
abstract interface class AdminRepository {
  /// Loads the dashboard summary (totals, per-stage counts, recent orders).
  Future<DashboardSummary> loadDashboard();

  /// Loads all orders for the Orders screen.
  Future<List<AdminOrder>> loadOrders();

  /// Loads all products for the Products screen.
  Future<List<AdminProduct>> loadProducts();

  /// Saves (creates or updates) [product] in the catalog.
  ///
  /// When [product] has an empty id a new document is created with a freshly
  /// generated unique id; otherwise the existing document with that id is
  /// updated. Returns the saved product carrying its final persisted id.
  Future<AdminProduct> saveProduct(AdminProduct product);

  /// Deletes a product by [productId].
  Future<void> deleteProduct(String productId);

  /// Loads all customers for the Customers screen.
  Future<List<AdminCustomer>> loadCustomers();
}
