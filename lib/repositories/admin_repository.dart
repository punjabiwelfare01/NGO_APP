import '../models/api_models.dart';
import 'api_client.dart';

class AdminRepository {
  const AdminRepository._();

  // ── User statistics ───────────────────────────────────────────────────────

  static Future<AdminStats> getStats() async {
    final json = await ApiClient.get('/admin/stats') as Map<String, dynamic>;
    return AdminStats.fromJson(json);
  }

  // ── All users ─────────────────────────────────────────────────────────────

  /// GET /admin/users — returns all users with optional filters.
  static Future<List<AdminUserItem>> getAllUsers({
    String? search,
    String? role,
    String? status,
  }) async {
    final params = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final list = await ApiClient.get('/admin/users$query') as List<dynamic>;
    return list
        .map((e) => AdminUserItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /admin/users/{id}/block
  static Future<void> blockUser(int userId, {String? reason}) async {
    await ApiClient.patch('/admin/users/$userId/block', {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  /// PATCH /admin/users/{id}/unblock
  static Future<void> unblockUser(int userId) async {
    await ApiClient.patch('/admin/users/$userId/unblock', {});
  }

  /// DELETE /admin/users/{id}
  static Future<void> deleteUser(int userId) async {
    await ApiClient.delete('/admin/users/$userId');
  }

  // ── Pending approvals ─────────────────────────────────────────────────────

  static Future<List<PendingUserItem>> getPendingUsers() async {
    final list = await ApiClient.get('/admin/users/pending') as List<dynamic>;
    return list
        .map((e) => PendingUserItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /admin/users/{id}/assign-role
  /// Only admin/super_admin may call this.
  /// role must be one of: student, mentor, content_creator.
  /// Only super_admin may assign the 'admin' role.
  static Future<Map<String, dynamic>> assignRole({
    required int userId,
    required String role,
    String accessStatus = 'approved',
    String? verificationNote,
  }) async {
    return await ApiClient.patch('/admin/users/$userId/assign-role', {
          'role': role,
          'access_status': accessStatus,
          if (verificationNote != null && verificationNote.isNotEmpty)
            'verification_note': verificationNote,
        })
        as Map<String, dynamic>;
  }

  /// POST /admin/users/{id}/roles — grants `role` in addition to any roles
  /// the account already holds (does not replace/clear other roles).
  static Future<Map<String, dynamic>> grantRole({
    required int userId,
    required String role,
  }) async {
    return await ApiClient.post('/admin/users/$userId/roles', {'role': role})
        as Map<String, dynamic>;
  }

  /// DELETE /admin/users/{id}/roles/{role} — revokes a previously granted
  /// role. The account's primary role cannot be revoked this way.
  static Future<void> revokeRole({
    required int userId,
    required String role,
  }) async {
    await ApiClient.delete('/admin/users/$userId/roles/$role');
  }

  /// PATCH /admin/users/{id}/reject
  static Future<void> rejectUser(int userId, {String? reason}) async {
    await ApiClient.patch('/admin/users/$userId/reject', {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  /// PATCH /admin/users/{id}/block
  static Future<void> deactivateUser(int userId) async {
    await ApiClient.patch('/admin/users/$userId/block', {});
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static Future<List<AdminNotification>> getNotifications() async {
    final list = await ApiClient.get('/admin/notifications') as List<dynamic>;
    return list
        .map((e) => AdminNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markNotificationRead(int notificationId) async {
    await ApiClient.patch('/admin/notifications/$notificationId/read', {});
  }

  static Future<void> markAllNotificationsRead() async {
    await ApiClient.patch('/admin/notifications/read-all', {});
  }

  static Future<void> deleteNotification(int notificationId) async {
    await ApiClient.delete('/admin/notifications/$notificationId');
  }

  static Future<void> deleteAllNotifications() async {
    await ApiClient.delete('/admin/notifications');
  }

  // ── User detail ───────────────────────────────────────────────────────────

  static Future<AppUser> getUserDetail(int userId) async {
    final json =
        await ApiClient.get('/admin/users/$userId') as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }
}
