import 'api_client.dart';

class AdminSettingsRepository {
  const AdminSettingsRepository._();
  static Future<Map<String, dynamic>> ngoProfile() async =>
      await ApiClient.get('/admin/settings/ngo-profile')
          as Map<String, dynamic>;
  static Future<Map<String, dynamic>> updateNgoProfile(
    Map<String, dynamic> body,
  ) async =>
      await ApiClient.patch('/admin/settings/ngo-profile', body)
          as Map<String, dynamic>;
  static Future<Map<String, dynamic>> bank() async =>
      await ApiClient.get('/admin/settings/bank') as Map<String, dynamic>;
  static Future<Map<String, dynamic>> updateBank(
    Map<String, dynamic> body,
  ) async =>
      await ApiClient.patch('/admin/settings/bank', {
            ...body,
            'confirmation': 'CONFIRM',
          })
          as Map<String, dynamic>;
  static Future<List<dynamic>> roles() async =>
      await ApiClient.get('/admin/roles') as List<dynamic>;
  static Future<Map<String, dynamic>> updatePermissions(
    String role,
    List<String> permissions,
  ) async =>
      await ApiClient.patch('/admin/roles/$role/permissions', {
            'permissions': permissions,
          })
          as Map<String, dynamic>;
  static Future<List<dynamic>> auditLogs() async =>
      await ApiClient.get('/admin/audit-logs') as List<dynamic>;
  static Future<List<dynamic>> announcements() async =>
      await ApiClient.get('/admin/announcements') as List<dynamic>;
  static Future<void> createAnnouncement(
    String title,
    String message,
    String? role,
  ) async => ApiClient.post('/admin/announcements', {
    'title': title,
    'message': message,
    'audience_role': ?role,
  });
  static Future<void> deleteAnnouncement(int id) =>
      ApiClient.delete('/admin/announcements/$id');
  static Future<Map<String, dynamic>> appSettings() async =>
      await ApiClient.get('/admin/app-settings') as Map<String, dynamic>;
  static Future<Map<String, dynamic>> updateAppSettings(
    Map<String, dynamic> values,
  ) async =>
      await ApiClient.patch('/admin/app-settings', {'values': values})
          as Map<String, dynamic>;
}
