import 'package:equatable/equatable.dart';

import '../../../../core/entities/gender.dart';

/// Sentinel used by [AuthUser.copyWith] to distinguish "leave unchanged" from
/// "set to null" for nullable fields (e.g. clearing an email or address).
const Object _unset = Object();

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

  /// Optional postal address the user can add/edit on their profile.
  final String? address;

  const AuthUser({
    this.id,
    this.isGuest = false,
    this.mobile,
    this.firstName,
    this.lastName,
    this.email,
    this.gender,
    this.address,
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
      gender = null,
      address = null;

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields ([email], [address], [gender]) use a sentinel so omitting
  /// an argument leaves the current value, while passing `null` explicitly
  /// clears it — needed when a user removes their email or address while
  /// editing their profile.
  AuthUser copyWith({
    String? id,
    bool? isGuest,
    String? mobile,
    String? firstName,
    String? lastName,
    Object? email = _unset,
    Object? gender = _unset,
    Object? address = _unset,
  }) {
    return AuthUser(
      id: id ?? this.id,
      isGuest: isGuest ?? this.isGuest,
      mobile: mobile ?? this.mobile,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: identical(email, _unset) ? this.email : email as String?,
      gender: identical(gender, _unset) ? this.gender : gender as Gender?,
      address: identical(address, _unset) ? this.address : address as String?,
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
    address,
  ];
}
