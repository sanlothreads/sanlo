import '../../../../core/entities/gender.dart';
import '../../domain/entities/auth_user.dart';

/// Data-layer DTO for [AuthUser].
///
/// Holds the same fields as the entity, serialising [Gender] as its enum name.
/// Exists so the future API layer can deserialise responses exactly as the
/// mock repository builds them.
class AuthUserModel {
  const AuthUserModel({
    this.id,
    this.isGuest = false,
    this.mobile,
    this.firstName,
    this.lastName,
    this.email,
    this.gender,
    this.address,
  });

  final String? id;
  final bool isGuest;
  final String? mobile;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? gender;
  final String? address;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String?,
      isGuest: json['isGuest'] as bool? ?? false,
      mobile: json['mobile'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isGuest': isGuest,
      'mobile': mobile,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'gender': gender,
      'address': address,
    };
  }

  factory AuthUserModel.fromEntity(AuthUser entity) {
    return AuthUserModel(
      id: entity.id,
      isGuest: entity.isGuest,
      mobile: entity.mobile,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      gender: entity.gender?.name,
      address: entity.address,
    );
  }

  AuthUser toEntity() {
    return AuthUser(
      id: id,
      isGuest: isGuest,
      mobile: mobile,
      firstName: firstName,
      lastName: lastName,
      email: email,
      gender: gender == null ? null : Gender.values.byName(gender!),
      address: address,
    );
  }
}
