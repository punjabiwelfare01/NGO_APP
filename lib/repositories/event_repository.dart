import '../models/event_models.dart';
import 'api_client.dart';

class EventRepository {
  const EventRepository._();

  static Future<List<EventModel>> getEvents({
    String? status,
    String? eventType,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (eventType != null) params['event_type'] = eventType;

    final queryString = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final list = await ApiClient.get('/events/$queryString') as List<dynamic>;
    return list
        .map((j) => EventModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<EventModel> getEvent(int id) async {
    final json = await ApiClient.get('/events/$id') as Map<String, dynamic>;
    return EventModel.fromJson(json);
  }

  static Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final json =
        await ApiClient.post('/events/create', data) as Map<String, dynamic>;
    return EventModel.fromJson(json);
  }

  static Future<EventModel> updateEvent(
    int id,
    Map<String, dynamic> data,
  ) async {
    final json =
        await ApiClient.patch('/events/$id', data) as Map<String, dynamic>;
    return EventModel.fromJson(json);
  }

  static Future<void> deleteEvent(int id) async {
    await ApiClient.delete('/events/$id');
  }

  static Future<EventModel> publishEvent(int id) async {
    final json =
        await ApiClient.post('/events/$id/publish', {}) as Map<String, dynamic>;
    return EventModel.fromJson(json);
  }

  static Future<EventModel> advanceStatus(int id, String newStatus) async {
    final json =
        await ApiClient.post('/events/$id/status', {'new_status': newStatus})
            as Map<String, dynamic>;
    return EventModel.fromJson(json);
  }

  static Future<void> registerForEvent(
    int id, {
    Map<String, dynamic>? formData,
  }) async {
    await ApiClient.post('/events/$id/register', formData ?? {});
  }

  static Future<void> bookSlot(int id, {int? slotId}) async {
    await ApiClient.post('/events/$id/book-slot', {'slot_id': slotId});
  }

  static Future<List<EventSlotModel>> getSlots(int id) async {
    final list = await ApiClient.get('/events/$id/slots') as List<dynamic>;
    return list
        .map((j) => EventSlotModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<EventSlotModel> createSlot(
    int id, {
    required String title,
    required DateTime startsAt,
    DateTime? endsAt,
    required int capacity,
  }) async {
    final json =
        await ApiClient.post('/events/$id/slots', {
              'title': title,
              'starts_at': startsAt.toIso8601String(),
              'ends_at': endsAt?.toIso8601String(),
              'capacity': capacity,
            })
            as Map<String, dynamic>;
    return EventSlotModel.fromJson(json);
  }

  static Future<void> attachQuiz(int id, String title, {int? quizId}) async {
    await ApiClient.post('/events/$id/quizzes', {
      'quiz_title': title,
      'quiz_id': quizId,
      'is_primary': true,
    });
    if (quizId != null) {
      await ApiClient.post('/quiz-manager/link-event', {
        'event_id': id,
        'quiz_id': quizId,
      });
    }
  }

  static Future<void> runSelection(
    int id, {
    List<int>? userIds,
    int? maxCount,
  }) async {
    await ApiClient.post('/events/$id/select', {
      'user_ids': userIds,
      'max_count': maxCount,
    });
  }

  static Future<int> assignCounselling(int id) async {
    final json =
        await ApiClient.post('/events/$id/counselling', {})
            as Map<String, dynamic>;
    return json['assigned_count'] as int? ?? 0;
  }

  static Future<List<Map<String, dynamic>>> getParticipants(int id) async {
    final list =
        await ApiClient.get('/events/$id/participants') as List<dynamic>;
    return list.map((j) => j as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>?> getMyRegistration(int id) async {
    try {
      final res = await ApiClient.get('/events/$id/my-registration');
      return res as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
