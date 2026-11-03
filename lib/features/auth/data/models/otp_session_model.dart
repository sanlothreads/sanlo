import '../../domain/entities/otp_session.dart';

/// Data-layer DTO for [OtpSession].
///
/// Serialises [expiresAt] as an ISO-8601 string.
class OtpSessionModel {
  const OtpSessionModel({
    required this.sessionId,
    required this.mobile,
    required this.expiresAt,
  });

  final String sessionId;
  final String mobile;
  final String expiresAt;

  factory OtpSessionModel.fromJson(Map<String, dynamic> json) {
    return OtpSessionModel(
      sessionId: json['sessionId'] as String,
      mobile: json['mobile'] as String,
      expiresAt: json['expiresAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'sessionId': sessionId, 'mobile': mobile, 'expiresAt': expiresAt};
  }

  factory OtpSessionModel.fromEntity(OtpSession entity) {
    return OtpSessionModel(
      sessionId: entity.sessionId,
      mobile: entity.mobile,
      expiresAt: entity.expiresAt.toIso8601String(),
    );
  }

  OtpSession toEntity() {
    return OtpSession(
      sessionId: sessionId,
      mobile: mobile,
      expiresAt: DateTime.parse(expiresAt),
    );
  }
}
