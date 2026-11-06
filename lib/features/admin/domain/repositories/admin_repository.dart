import '../entities/admin_customer.dart';
import '../entities/admin_order.dart';
import '../entities/admin_product.dart';
import '../entities/dashboard_summary.dart';
import '../entities/order_stage.dart';

/// Repository interface for the admin workspace.
abstract interface class AdminRepository {
  /// Loads the dashboard summary (totals, per-stage counts, recent orders).
  Future<DashboardSummary> loadDashboard();

  /// Loads all orders for the Orders screen.
  Future<List<AdminOrder>> loadOrders();

  /// Returns a realtime stream of all orders for the Orders screen.
  Stream<List<AdminOrder>> watchOrders();

  /// Updates the lifecycle stage of an order in the database.
  Future<void> updateOrderStage(String orderId, OrderStage nextStage);

  /// Loads all products for the Products screen.
  Future<List<AdminProduct>> loadProducts();

  /// Saves (creates or updates) [product] in the catalog.
  Future<AdminProduct> saveProduct(AdminProduct product);

  /// Deletes a product by [productId].
  Future<void> deleteProduct(String productId);

  /// Loads all customers for the Customers screen.
  Future<List<AdminCustomer>> loadCustomers();
}
