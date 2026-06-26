// ignore_for_file: prefer_null_aware_elements
import '../models/certificate_models.dart';
import '../app_state.dart';
import 'api_client.dart';

class CertificateRepository {
  const CertificateRepository._();

  // ── Student endpoints ───────────────────────────────────────────────────

  static Future<List<Certificate>> getMyCertificates() async {
    final data = await ApiClient.get('/student/certificates') as List<dynamic>;
    return data
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Certificate> requestCertificate({
    required String certificateType,
    required String activityName,
    int? eventId,
    String? duration,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'certificate_type': certificateType,
      'activity_name': activityName,
    };
    if (eventId != null) body['event_id'] = eventId;
    if (duration != null) body['duration'] = duration;
    if (notes != null) body['notes'] = notes;
    final data = await ApiClient.post('/student/certificates/request', body);
    return Certificate.fromJson(data as Map<String, dynamic>);
  }

  static Future<Certificate> markGenerated(int certId) async {
    final data = await ApiClient.patch(
      '/student/certificates/$certId/mark-generated',
      {},
    );
    return Certificate.fromJson(data as Map<String, dynamic>);
  }

  static String downloadUrl(Certificate certificate) {
    final token = Uri.encodeQueryComponent(AppState.token ?? '');
    return ApiClient.resolveUrl(
      '/student/certificates/${certificate.id}/download?token=$token',
    );
  }

  static String verificationUrl(Certificate certificate) =>
      ApiClient.resolveUrl(
        '/public/certificates/verify/${certificate.qrToken}',
      );

  // ── Admin endpoints ─────────────────────────────────────────────────────

  static Future<List<Certificate>> getAllCertificates() async {
    final data = await ApiClient.get('/certificates') as List<dynamic>;
    return data
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Certificate>> getPendingCertificates() async {
    final data =
        await ApiClient.get('/admin/certificates/pending') as List<dynamic>;
    return data
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Certificate> approveCertificate(
    int certId, {
    String? signatoryName,
    String? signatoryTitle,
  }) async {
    final body = <String, dynamic>{};
    if (signatoryName != null) body['signatory_name'] = signatoryName;
    if (signatoryTitle != null) body['signatory_title'] = signatoryTitle;
    final data = await ApiClient.post(
      '/admin/certificates/$certId/approve',
      body,
    );
    return Certificate.fromJson(data as Map<String, dynamic>);
  }

  static Future<Certificate> rejectCertificate(
    int certId,
    String reason,
  ) async {
    final data = await ApiClient.post(
      '/admin/certificates/$certId/reject',
      {'reason': reason},
    );
    return Certificate.fromJson(data as Map<String, dynamic>);
  }

  static Future<Certificate> revokeCertificate(
    int certId,
    String reason,
  ) async {
    final data = await ApiClient.patch(
      '/admin/certificates/$certId/revoke',
      {'reason': reason},
    );
    return Certificate.fromJson(data as Map<String, dynamic>);
  }

  static Future<Certificate> createCertificate({
    required int studentId,
    required String certificateType,
    required String activityName,
    String? duration,
    String? signatoryName,
    String? signatoryTitle,
    String? issueDate,
  }) async {
    final body = <String, dynamic>{
      'student_id': studentId,
      'certificate_type': certificateType,
      'activity_name': activityName,
    };
    if (duration != null) body['duration'] = duration;
    if (signatoryName != null) body['signatory_name'] = signatoryName;
    if (signatoryTitle != null) body['signatory_title'] = signatoryTitle;
    if (issueDate != null) body['issue_date'] = issueDate;
    final data = await ApiClient.post('/certificates', body);
    return Certificate.fromJson(data as Map<String, dynamic>);
  }

  // ── Public verification ─────────────────────────────────────────────────

  static Future<Certificate?> verifyCertificate(String token) async {
    try {
      final data =
          await ApiClient.get('/public/certificates/verify/$token');
      return Certificate.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
