import 'package:flutter/foundation.dart';

import '../models/api_models.dart';
import '../repositories/admin_repository.dart';
import '../repositories/api_client.dart';
import 'view_state.dart';

class AdminViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  bool _disposed = false;

  List<PendingUserItem>   _pendingUsers  = [];
  List<AdminNotification> _notifications = [];
  List<AdminUserItem>     _allUsers      = [];
  AdminStats              _stats         = AdminStats.empty();

  ViewState               get state         => _state;
  String?                 get errorMessage  => _errorMessage;
  List<PendingUserItem>   get pendingUsers  => _pendingUsers;
  List<AdminNotification> get notifications => _notifications;
  List<AdminUserItem>     get allUsers      => _allUsers;
  AdminStats              get stats         => _stats;

  int get unreadCount  => _notifications.where((n) => !n.isRead).length;
  int get pendingCount => _pendingUsers.length;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    _state = ViewState.loading;
    _errorMessage = null;
    if (!_disposed) notifyListeners();
    try {
      final results = await Future.wait([
        AdminRepository.getPendingUsers(),
        AdminRepository.getNotifications(),
        AdminRepository.getStats(),
      ]);
      _pendingUsers  = results[0] as List<PendingUserItem>;
      _notifications = results[1] as List<AdminNotification>;
      _stats         = results[2] as AdminStats;
      _state = ViewState.idle;
    } on ApiException catch (e) {
      _state = ViewState.error;
      _errorMessage = 'Failed to load data (${e.statusCode}).';
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Connection failed. Is the backend running?';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> loadPendingUsers() async {
    try {
      _pendingUsers = await AdminRepository.getPendingUsers();
    } on ApiException {
      // silently ignore
    } catch (_) {}
    if (!_disposed) notifyListeners();
  }

  Future<void> loadNotifications() async {
    try {
      _notifications = await AdminRepository.getNotifications();
    } on ApiException {
      // ignore
    } catch (_) {}
    if (!_disposed) notifyListeners();
  }

  Future<void> loadAllUsers({
    String? search,
    String? role,
    String? status,
  }) async {
    try {
      _allUsers = await AdminRepository.getAllUsers(
        search: search,
        role: role,
        status: status,
      );
    } on ApiException {
      // caller shows its own error state
    } catch (_) {}
    if (!_disposed) notifyListeners();
  }

  // ── Approval actions ──────────────────────────────────────────────────────

  Future<bool> assignRole({
    required int userId,
    required String role,
    String? verificationNote,
  }) async {
    try {
      await AdminRepository.assignRole(
        userId: userId,
        role: role,
        accessStatus: 'approved',
        verificationNote: verificationNote,
      );
      _pendingUsers.removeWhere((u) => u.id == userId);
      _updateAllUser(userId, role: role, accessStatus: 'approved');
      if (!_disposed) notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = 'Role assignment failed (${e.statusCode}).';
      if (!_disposed) notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Connection failed.';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<bool> rejectUser(int userId, {String? reason}) async {
    try {
      await AdminRepository.rejectUser(userId, reason: reason);
      _pendingUsers.removeWhere((u) => u.id == userId);
      _updateAllUser(userId, accessStatus: 'rejected');
      if (!_disposed) notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = 'Rejection failed (${e.statusCode}).';
      if (!_disposed) notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Connection failed.';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  // ── Block / unblock / delete ──────────────────────────────────────────────

  Future<bool> blockUser(int userId, {String? reason}) async {
    try {
      await AdminRepository.blockUser(userId, reason: reason);
      _updateAllUser(userId, accessStatus: 'deactivated');
      if (!_disposed) notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = 'Block failed (${e.statusCode}).';
      if (!_disposed) notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Connection failed.';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<bool> unblockUser(int userId) async {
    try {
      await AdminRepository.unblockUser(userId);
      _updateAllUser(userId, accessStatus: 'approved');
      if (!_disposed) notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = 'Unblock failed (${e.statusCode}).';
      if (!_disposed) notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Connection failed.';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await AdminRepository.deleteUser(userId);
      _allUsers.removeWhere((u) => u.id == userId);
      _pendingUsers.removeWhere((u) => u.id == userId);
      if (!_disposed) notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = 'Delete failed (${e.statusCode}).';
      if (!_disposed) notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Connection failed.';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  // ── Notification actions ──────────────────────────────────────────────────

  Future<void> markNotificationRead(int notificationId) async {
    try {
      await AdminRepository.markNotificationRead(notificationId);
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        if (!_disposed) notifyListeners();
      }
    } on ApiException {
      // ignore
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await AdminRepository.markAllNotificationsRead();
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      if (!_disposed) notifyListeners();
    } on ApiException {
      // ignore
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _updateAllUser(int userId, {String? role, String? accessStatus}) {
    final idx = _allUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _allUsers[idx] =
          _allUsers[idx].copyWith(role: role, accessStatus: accessStatus);
    }
  }
}
