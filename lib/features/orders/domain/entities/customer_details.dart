import 'package:equatable/equatable.dart';

/// Customer-provided contact details captured in step 1 of the order flow.
class CustomerDetails extends Equatable {
  const CustomerDetails({
    required this.fullName,
    required this.mobile,
    this.email,
    this.address,
  });

  /// Customer's full name.
  final String fullName;

  /// Customer's mobile number (e.g. "+91...").
  final String mobile;

  /// Optional email address.
  final String? email;

  /// Optional delivery/contact address.
  final String? address;

  @override
  List<Object?> get props => [fullName, mobile, email, address];
}
