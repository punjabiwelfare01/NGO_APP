import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../models/platform_models.dart';
import '../../repositories/platform_repository.dart';

class ProfileNotificationsScreen extends StatefulWidget {
  const ProfileNotificationsScreen({super.key});
  @override
  State<ProfileNotificationsScreen> createState() =>
      _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState
    extends State<ProfileNotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await PlatformRepository.notifications();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _read(AppNotification item) async {
    if (item.isRead) return;
    await PlatformRepository.markRead(item.id);
    await _load();
  }

  Future<void> _readAll() async {
    await PlatformRepository.markAllRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        TextButton(
          onPressed: _items.any((e) => !e.isRead) ? _readAll : null,
          child: const Text('Read all'),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: TextButton(
              onPressed: _load,
              child: Text('Retry\n$_error', textAlign: TextAlign.center),
            ),
          )
        : _items.isEmpty
        ? const Center(
            child: Text(
              'No notifications yet.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = _items[i];
                return ListTile(
                  onTap: () => _read(item),
                  tileColor: item.isRead
                      ? Colors.white
                      : AppColors.primary.withValues(alpha: .08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Icon(
                    item.isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(item.message),
                  trailing: item.isRead
                      ? null
                      : const CircleAvatar(
                          radius: 4,
                          backgroundColor: AppColors.primary,
                        ),
                );
              },
            ),
          ),
  );
}
