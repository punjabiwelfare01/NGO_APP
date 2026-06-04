import '../models/calendar_item.dart';
import 'api_client.dart';

class CalendarRepository {
  const CalendarRepository._();

  static Future<List<CalendarItem>> getMyCalendar() async {
    final list = await ApiClient.get('/calendar/me') as List<dynamic>;
    return list
        .map((json) => CalendarItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<CalendarReminder> createReminder({
    required String title,
    required DateTime scheduledAt,
  }) async {
    final json =
        await ApiClient.post('/calendar/reminders', {
              'title': title,
              'scheduled_at': scheduledAt.toIso8601String(),
            })
            as Map<String, dynamic>;
    return CalendarReminder.fromJson(json);
  }

  static Future<CalendarReminder> updateReminder(
    int reminderId, {
    String? title,
    DateTime? scheduledAt,
    bool? isDone,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (scheduledAt != null) {
      body['scheduled_at'] = scheduledAt.toIso8601String();
    }
    if (isDone != null) body['is_done'] = isDone;
    if (isActive != null) body['is_active'] = isActive;
    final json =
        await ApiClient.patch('/calendar/reminders/$reminderId', body)
            as Map<String, dynamic>;
    return CalendarReminder.fromJson(json);
  }
}
