import '../models/api_models.dart';
import 'api_client.dart';

class WellnessRepository {
  const WellnessRepository._();

  static Future<List<ApiCounsellingSession>> getCounsellingSessions(
    int userId,
  ) async {
    final list =
        await ApiClient.get('/users/$userId/wellness/counselling')
            as List<dynamic>;
    return list
        .map((j) => ApiCounsellingSession.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<ApiCounsellingSession> bookSession(
    int userId, {
    required String counsellorName,
    required String topic,
    required DateTime scheduledAt,
    DateTime? endsAt,
    String? meetingUrl,
  }) async {
    final json =
        await ApiClient.post('/users/$userId/wellness/counselling', {
              'counsellor_name': counsellorName,
              'topic': topic,
              'scheduled_at': scheduledAt.toIso8601String(),
              'ends_at': endsAt?.toIso8601String(),
              'meeting_url': meetingUrl,
            })
            as Map<String, dynamic>;
    return ApiCounsellingSession.fromJson(json);
  }

  static Future<List<ApiCounsellingSlot>> getAvailableSlots(int userId) async {
    final list =
        await ApiClient.get('/users/$userId/wellness/counselling/availability')
            as List<dynamic>;
    return list
        .map((j) => ApiCounsellingSlot.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ApiCounsellingSlot>> getMentorSlots(int mentorId) async {
    final list =
        await ApiClient.get(
              '/users/$mentorId/wellness/counselling/mentor-slots',
            )
            as List<dynamic>;
    return list
        .map((j) => ApiCounsellingSlot.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ApiCounsellingSession>> getMentorSessions(
    int mentorId,
  ) async {
    final list =
        await ApiClient.get(
              '/users/$mentorId/wellness/counselling/mentor-sessions',
            )
            as List<dynamic>;
    return list
        .map((j) => ApiCounsellingSession.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<ApiCounsellingSlot> createAvailabilitySlot(
    int mentorId, {
    required DateTime startsAt,
    required DateTime endsAt,
    String? topic,
    int capacity = 1,
    String? meetingUrl,
  }) async {
    final json =
        await ApiClient.post(
              '/users/$mentorId/wellness/counselling/availability',
              {
                'starts_at': startsAt.toIso8601String(),
                'ends_at': endsAt.toIso8601String(),
                'topic': topic,
                'capacity': capacity,
                'meeting_url': meetingUrl,
              },
            )
            as Map<String, dynamic>;
    return ApiCounsellingSlot.fromJson(json);
  }

  static Future<void> deleteAvailabilitySlot(int mentorId, int slotId) async {
    await ApiClient.delete(
        '/users/$mentorId/wellness/counselling/availability/$slotId');
  }

  static Future<ApiCounsellingSlot> updateAvailabilitySlot(
    int mentorId,
    int slotId, {
    String? topic,
    DateTime? startsAt,
    DateTime? endsAt,
    int? capacity,
    String? meetingUrl,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (topic != null) body['topic'] = topic;
    if (startsAt != null) body['starts_at'] = startsAt.toIso8601String();
    if (endsAt != null) body['ends_at'] = endsAt.toIso8601String();
    if (capacity != null) body['capacity'] = capacity;
    if (meetingUrl != null) body['meeting_url'] = meetingUrl;
    if (isActive != null) body['is_active'] = isActive;
    final json = await ApiClient.patch(
            '/users/$mentorId/wellness/counselling/availability/$slotId', body)
        as Map<String, dynamic>;
    return ApiCounsellingSlot.fromJson(json);
  }

  static Future<ApiCounsellingSession> bookAvailabilitySlot(
    int userId, {
    required int slotId,
    required String topic,
  }) async {
    final json =
        await ApiClient.post(
              '/users/$userId/wellness/counselling/availability/$slotId/book',
              {'topic': topic},
            )
            as Map<String, dynamic>;
    return ApiCounsellingSession.fromJson(json);
  }
}
