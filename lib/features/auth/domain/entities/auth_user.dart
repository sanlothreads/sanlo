import 'package:equatable/equatable.dart';

import '../../../../core/entities/gender.dart';

/// The currently signed-in user.
///
/// A [null] [id] denotes a guest: use the [AuthUser.guest] factory to create a
/// guest session where [isGuest] is `true` and all other fields are `null`.
class AuthUser extends Equatable {
  /// Backend identifier. `null` means this is a guest session.
  final String? id;

  /// Whether this user is a guest (no credentials).
  final bool isGuest;

  /// Mobile number (e.g. "+91..."), if known.
  final String? mobile;

  final String? firstName;
  final String? lastName;
  final String? email;
  final Gender? gender;

  const AuthUser({
    this.id,
    this.isGuest = false,
    this.mobile,
    this.firstName,
    this.lastName,
    this.email,
    this.gender,
  });

  /// Creates a guest session: no id, [isGuest] is `true`, and no personal
  /// details.
  const AuthUser.guest()
      : id = null,
        isGuest = true,
        mobile = null,
        firstName = null,
        lastName = null,
        email = null,
        gender = null;

  AuthUser copyWith({
    String? id,
    bool? isGuest,
    String? mobile,
    String? firstName,
    String? lastName,
    String? email,
    Gender? gender,
  }) {
    return AuthUser(
      id: id ?? this.id,
      isGuest: isGuest ?? this.isGuest,
      mobile: mobile ?? this.mobile,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
    );
  }

  @override
  List<Object?> get props => [
        id,
        isGuest,
        mobile,
        firstName,
        lastName,
        email,
        gender,
      ];
}
