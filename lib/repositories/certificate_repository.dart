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

  static String adminDownloadUrl(Certificate certificate) {
    final token = Uri.encodeQueryComponent(AppState.token ?? '');
    return ApiClient.resolveUrl(
      '/certificates/${certificate.id}/download?token=$token',
    );
  }

  static String verificationUrl(Certificate certificate) =>
      ApiClient.resolveUrl(
        '/public/certificates/verify/${certificate.qrToken}',
      );

  // ── Admin endpoints ─────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getReadyToGenerate() async {
    final data =
        await ApiClient.get('/admin/certificates/ready') as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Certificate> generateCertificate({
    required int assignmentId,
    String? signatoryName,
    String? signatoryTitle,
  }) async {
    final body = <String, dynamic>{'assignment_id': assignmentId};
    if (signatoryName != null) body['signatory_name'] = signatoryName;
    if (signatoryTitle != null) body['signatory_title'] = signatoryTitle;
    final data = await ApiClient.post('/admin/certificates/generate', body);
    return Certificate.fromJson(data as Map<String, dynamic>);
  }

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
    String? studentIdNumber,
    String? studentRole,
    String? eventName,
    String? programName,
    String? workDescription,
    double? serviceHours,
    String? startDate,
    String? endDate,
    String? signatoryName,
    String? signatoryTitle,
    String? signatureUrl,
    String? remarks,
    String? impactStorySummary,
    String? issueDate,
    int? eventId,
    int? activityId,
  }) async {
    final body = <String, dynamic>{
      'student_id': studentId,
      'certificate_type': certificateType,
      'activity_name': activityName,
    };
    if (duration != null) body['duration'] = duration;
    if (studentIdNumber != null) body['student_id_number'] = studentIdNumber;
    if (studentRole != null) body['student_role'] = studentRole;
    if (eventName != null) body['event_name'] = eventName;
    if (programName != null) body['program_name'] = programName;
    if (workDescription != null) body['work_description'] = workDescription;
    if (serviceHours != null) body['service_hours'] = serviceHours;
    if (startDate != null) body['start_date'] = startDate;
    if (endDate != null) body['end_date'] = endDate;
    if (signatoryName != null) body['signatory_name'] = signatoryName;
    if (signatoryTitle != null) body['signatory_title'] = signatoryTitle;
    if (signatureUrl != null) body['signature_url'] = signatureUrl;
    if (remarks != null) body['remarks'] = remarks;
    if (impactStorySummary != null) body['impact_story_summary'] = impactStorySummary;
    if (issueDate != null) body['issue_date'] = issueDate;
    if (eventId != null) body['event_id'] = eventId;
    if (activityId != null) body['activity_id'] = activityId;
    final data = await ApiClient.post('/certificates', body);
    return Certificate.fromJson(data as Map<String, dynamic>);
  }

  static Future<Certificate> updateCertificate(
    int certId, {
    String? certificateType,
    String? activityName,
    String? duration,
    String? studentIdNumber,
    String? studentRole,
    String? eventName,
    String? programName,
    String? workDescription,
    double? serviceHours,
    String? startDate,
    String? endDate,
    String? signatoryName,
    String? signatoryTitle,
    String? signatureUrl,
    String? remarks,
    String? impactStorySummary,
    String? issueDate,
  }) async {
    final body = <String, dynamic>{};
    if (certificateType != null) body['certificate_type'] = certificateType;
    if (activityName != null) body['activity_name'] = activityName;
    if (duration != null) body['duration'] = duration;
    if (studentIdNumber != null) body['student_id_number'] = studentIdNumber;
    if (studentRole != null) body['student_role'] = studentRole;
    if (eventName != null) body['event_name'] = eventName;
    if (programName != null) body['program_name'] = programName;
    if (workDescription != null) body['work_description'] = workDescription;
    if (serviceHours != null) body['service_hours'] = serviceHours;
    if (startDate != null) body['start_date'] = startDate;
    if (endDate != null) body['end_date'] = endDate;
    if (signatoryName != null) body['signatory_name'] = signatoryName;
    if (signatoryTitle != null) body['signatory_title'] = signatoryTitle;
    if (signatureUrl != null) body['signature_url'] = signatureUrl;
    if (remarks != null) body['remarks'] = remarks;
    if (impactStorySummary != null) body['impact_story_summary'] = impactStorySummary;
    if (issueDate != null) body['issue_date'] = issueDate;
    final data = await ApiClient.put('/certificates/$certId', body);
    return Certificate.fromJson(data as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> createImpactStory(
    int certId, {
    String? overrideSummary,
    String? overrideTitle,
  }) async {
    final body = <String, dynamic>{};
    if (overrideSummary != null) body['override_summary'] = overrideSummary;
    if (overrideTitle != null) body['override_title'] = overrideTitle;
    return await ApiClient.post('/certificates/$certId/impact-story', body) as Map<String, dynamic>;
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
