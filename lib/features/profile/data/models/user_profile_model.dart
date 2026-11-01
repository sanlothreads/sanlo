import '../../../../core/entities/gender.dart';
import '../../domain/entities/user_profile.dart';

/// Data-layer DTO for [UserProfile]. Serialises [Gender] as its enum name.
class UserProfileModel {
  const UserProfileModel({
    required this.firstName,
    required this.lastName,
    required this.mobile,
    this.email,
    this.gender,
    this.totalOrders = 0,
    this.inProgress = 0,
    this.ready = 0,
  });

  final String firstName;
  final String lastName;
  final String mobile;
  final String? email;
  final String? gender;
  final int totalOrders;
  final int inProgress;
  final int ready;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      totalOrders: json['totalOrders'] as int? ?? 0,
      inProgress: json['inProgress'] as int? ?? 0,
      ready: json['ready'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'email': email,
      'gender': gender,
      'totalOrders': totalOrders,
      'inProgress': inProgress,
      'ready': ready,
    };
  }

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      firstName: entity.firstName,
      lastName: entity.lastName,
      mobile: entity.mobile,
      email: entity.email,
      gender: entity.gender?.name,
      totalOrders: entity.totalOrders,
      inProgress: entity.inProgress,
      ready: entity.ready,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      firstName: firstName,
      lastName: lastName,
      mobile: mobile,
      email: email,
      gender: gender == null ? null : Gender.values.byName(gender!),
      totalOrders: totalOrders,
      inProgress: inProgress,
      ready: ready,
    );
  }
}
