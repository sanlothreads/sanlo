import '../../domain/entities/customer_details.dart';

/// Data-layer DTO for [CustomerDetails].
class CustomerDetailsModel {
  const CustomerDetailsModel({
    required this.fullName,
    required this.mobile,
    this.email,
    this.address,
  });

  final String fullName;
  final String mobile;
  final String? email;
  final String? address;

  factory CustomerDetailsModel.fromJson(Map<String, dynamic> json) {
    return CustomerDetailsModel(
      fullName: json['fullName'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      'address': address,
    };
  }

  factory CustomerDetailsModel.fromEntity(CustomerDetails entity) {
    return CustomerDetailsModel(
      fullName: entity.fullName,
      mobile: entity.mobile,
      email: entity.email,
      address: entity.address,
    );
  }

  CustomerDetails toEntity() {
    return CustomerDetails(
      fullName: fullName,
      mobile: mobile,
      email: email,
      address: address,
    );
  }
}
