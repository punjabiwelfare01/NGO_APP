import '../models/platform_models.dart';
import 'api_client.dart';

class PlatformRepository {
  const PlatformRepository._();

  static Future<List<AppNotification>> notifications() async {
    final data = await ApiClient.get('/notifications') as List<dynamic>;
    return data
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<AppNotification> markRead(int id) async =>
      AppNotification.fromJson(
        await ApiClient.post('/notifications/$id/read', const {})
            as Map<String, dynamic>,
      );
  static Future<void> markAllRead() async =>
      ApiClient.post('/notifications/read-all', const {});

  static Future<List<ProfileReport>> reports() async {
    final data = await ApiClient.get('/profile/reports') as List<dynamic>;
    return data
        .map((item) => ProfileReport.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<UserSettings> settings() async => UserSettings.fromJson(
    await ApiClient.get('/settings/me') as Map<String, dynamic>,
  );
  static Future<UserSettings> updateSettings(
    Map<String, dynamic> values,
  ) async => UserSettings.fromJson(
    await ApiClient.patch('/settings/me', values) as Map<String, dynamic>,
  );
}
