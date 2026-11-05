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
    this.lastOrderDate,
    this.email,
    this.registeredDate,
    this.lastLogin,
  });

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String gender;
  final String type;
  final String? registeredDate;
  final String? lastLogin;
  final int orderCount;
  final DateTime? lastOrderDate;

  AdminCustomer toEntity() {
    return AdminCustomer(
      id: id,
      name: name,
      mobile: mobile,
      email: email,
      gender: Gender.values.byName(gender),
      type: CustomerType.registered,
      registeredDate: registeredDate,
      lastLogin: lastLogin,
      orderCount: orderCount,
      lastOrderDate: lastOrderDate,
    );
  }
}
