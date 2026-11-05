import '../../../../core/entities/gender.dart';
import '../../domain/entities/admin_customer.dart';

/// Data-layer DTO for [AdminCustomer].
class AdminCustomerModel {
  const AdminCustomerModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.gender,
    required this.type,
    required this.orderCount,
    required this.lastOrderDate,
    this.email,
  });

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String gender;
  final String type;
  final int orderCount;
  final DateTime lastOrderDate;

  AdminCustomer toEntity() {
    return AdminCustomer(
      id: id,
      name: name,
      mobile: mobile,
      email: email,
      gender: Gender.values.byName(gender),
      type: CustomerType.values.byName(type),
      orderCount: orderCount,
      lastOrderDate: lastOrderDate,
    );
  }
}
