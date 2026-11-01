import 'package:equatable/equatable.dart';

import 'package:sanlo/core/entities/gender.dart';

/// Sentinel used by [UserProfile.copyWith] to distinguish "leave unchanged"
/// from "set to null" for nullable fields.
const Object _unset = Object();

/// The signed-in customer's profile: personal details plus order stats shown
/// on the Profile screen.
class UserProfile extends Equatable {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.mobile,
    this.email,
    this.gender,
    this.totalOrders = 0,
    this.inProgress = 0,
    this.ready = 0,
  });

  /// Customer's first name.
  final String firstName;

  /// Customer's last name.
  final String lastName;

  /// Customer's mobile number (e.g. "+91...").
  final String mobile;

  /// Optional email address.
  final String? email;

  /// Optional gender.
  final Gender? gender;

  /// Total number of orders the customer has placed.
  final int totalOrders;

  /// Number of orders currently in progress.
  final int inProgress;

  /// Number of orders ready for pickup.
  final int ready;

  /// Returns a copy of this profile with the given fields replaced.
  ///
  /// Nullable fields ([email], [gender]) use a sentinel so that omitting an
  /// argument leaves the current value, while passing `null` explicitly clears
  /// it.
  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? mobile,
    Object? email = _unset,
    Object? gender = _unset,
    int? totalOrders,
    int? inProgress,
    int? ready,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobile: mobile ?? this.mobile,
      email: identical(email, _unset) ? this.email : email as String?,
      gender: identical(gender, _unset) ? this.gender : gender as Gender?,
      totalOrders: totalOrders ?? this.totalOrders,
      inProgress: inProgress ?? this.inProgress,
      ready: ready ?? this.ready,
    );
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        mobile,
        email,
        gender,
        totalOrders,
        inProgress,
        ready,
      ];
}
