import '../models/api_models.dart';
import '../models/counselling_models.dart';
import '../models/counsellor_models.dart';
import '../models/counsellor_session_models.dart';
import 'api_client.dart';

class CounsellingRepository {
  const CounsellingRepository._();

  static Future<List<MentorProfile>> getMentors({String? category}) async {
    final query = category != null
        ? '?category=${Uri.encodeComponent(category)}'
        : '';
    final list =
        await ApiClient.get('/counselling/mentors$query') as List<dynamic>;
    return list
        .map((j) => MentorProfile.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<MentorProfile> getMentor(int id) async {
    final json =
        await ApiClient.get('/counselling/mentors/$id') as Map<String, dynamic>;
    return MentorProfile.fromJson(json);
  }

  static Future<MentorProfile?> getMyMentorProfile() async {
    try {
      final json =
          await ApiClient.get('/counselling/mentors/me')
              as Map<String, dynamic>;
      return MentorProfile.fromJson(json);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<MentorProfile> updateMyMentorProfile(
    Map<String, dynamic> payload,
  ) async {
    final json =
        await ApiClient.patch('/counselling/mentors/me', payload)
            as Map<String, dynamic>;
    return MentorProfile.fromJson(json);
  }

  static Future<MentorProfile> createMentorProfile(
    Map<String, dynamic> payload,
  ) async {
    final json =
        await ApiClient.post('/counselling/mentors', payload)
            as Map<String, dynamic>;
    return MentorProfile.fromJson(json);
  }

  static Future<MentorProfile> updateMentorProfile(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final json =
        await ApiClient.patch('/counselling/mentors/$id', payload)
            as Map<String, dynamic>;
    return MentorProfile.fromJson(json);
  }

  /// Update by user id (what [CounsellorProfile.id] holds), not the
  /// mentor_profiles primary key used by [updateMentorProfile] above.
  static Future<void> updateCounsellorByUserId(
    int userId,
    Map<String, dynamic> payload,
  ) async {
    await ApiClient.patch('/counselling/mentors/by-user/$userId', payload);
  }

  static Future<List<ApiCounsellingSlot>> getSlots({String? category}) async {
    final query = category != null
        ? '?category=${Uri.encodeComponent(category)}'
        : '';
    final list =
        await ApiClient.get('/counselling/slots$query') as List<dynamic>;
    return list
        .map((j) => ApiCounsellingSlot.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ApiCounsellingSlot>> getMentorSlots(int userId) async {
    final list =
        await ApiClient.get('/counselling/slots/mentor/$userId')
            as List<dynamic>;
    return list
        .map((j) => ApiCounsellingSlot.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<CounsellingAnalytics> getAnalytics() async {
    final json =
        await ApiClient.get('/counselling/analytics') as Map<String, dynamic>;
    return CounsellingAnalytics.fromJson(json);
  }

  static Future<List<CounsellorProfile>> getCounsellors() async {
    final list =
        await ApiClient.get('/counselling/mentors') as List<dynamic>;
    return list
        .map(
          (j) => CounsellorProfile.fromMentorJson(j as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> submitSchoolRequest(
    Map<String, dynamic> payload,
  ) async =>
      await ApiClient.post('/school/counsellor-requests', payload)
          as Map<String, dynamic>;

  static Future<List<SchoolBookingRequest>> getCounsellorRequests() async {
    final list = await ApiClient.get('/counsellor/requests') as List<dynamic>;
    return list
        .map(
          (json) => SchoolBookingRequest.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<List<SchoolBookingRequest>> getMySchoolRequests() async {
    final list =
        await ApiClient.get('/school/my-requests') as List<dynamic>;
    return list
        .map(
          (json) => SchoolBookingRequest.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<SchoolBookingRequest> getMySchoolRequest(int id) async {
    final json =
        await ApiClient.get('/school/my-requests/$id') as Map<String, dynamic>;
    return SchoolBookingRequest.fromJson(json);
  }

  static Future<SchoolBookingRequest> confirmSchoolRequestTime(int id) async {
    final json =
        await ApiClient.patch('/school/my-requests/$id/confirm-time', {})
            as Map<String, dynamic>;
    return SchoolBookingRequest.fromJson(json);
  }

  static Future<SchoolBookingRequest> cancelSchoolRequest(int id) async {
    final json =
        await ApiClient.patch('/school/my-requests/$id/cancel', {})
            as Map<String, dynamic>;
    return SchoolBookingRequest.fromJson(json);
  }

  static Future<List<AvailabilitySlot>> getMyAvailability() async {
    final list =
        await ApiClient.get('/counsellor/availability') as List<dynamic>;
    return list
        .map((json) => AvailabilitySlot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> acceptRequest(int id) async =>
      ApiClient.post('/counsellor/requests/$id/accept', const {});
  static Future<void> declineRequest(
    int id,
    String reason,
    String note,
  ) async => ApiClient.post('/counsellor/requests/$id/decline', {
    'reason': reason,
    'note': note,
  });
  static Future<void> rescheduleRequest(int id, DateTime value) async =>
      ApiClient.post('/counsellor/requests/$id/reschedule', {
        'suggested_at': value.toIso8601String(),
      });
  static Future<void> completeSession(int id) async =>
      ApiClient.post('/counsellor/sessions/$id/complete', const {});
  static Future<void> submitSessionReport(
    int id, {
    required String notes,
    double? rating,
    String? schoolFeedback,
    int? studentsCount,
  }) async => ApiClient.post('/counsellor/sessions/$id/report', {
    'counsellor_notes': notes,
    if (rating != null) 'rating': rating.round(),
    'school_feedback': ?schoolFeedback,
    'students_count': ?studentsCount,
  });
  static Future<void> createAvailability(AvailabilitySlot slot) async {
    final start = DateTime(
      slot.date.year,
      slot.date.month,
      slot.date.day,
      slot.startTime.hour,
      slot.startTime.minute,
    );
    final end = DateTime(
      slot.date.year,
      slot.date.month,
      slot.date.day,
      slot.endTime.hour,
      slot.endTime.minute,
    );
    await ApiClient.post('/counsellor/availability', {
      'starts_at': start.toIso8601String(),
      'ends_at': end.toIso8601String(),
      if (slot.mode == SessionMode.online) 'meeting_url': 'pending',
    });
  }

  static Future<void> setAvailabilityActive(int id, bool active) async =>
      ApiClient.patch('/counsellor/availability/$id', {'is_active': active});
}
