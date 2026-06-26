import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../repositories/admin_settings_repository.dart';

enum AdminSettingsModule { ngo, roles, audit, announcements, app }

class AdminSettingsModuleScreen extends StatefulWidget {
  const AdminSettingsModuleScreen({required this.module, super.key});
  final AdminSettingsModule module;
  @override
  State<AdminSettingsModuleScreen> createState() =>
      _AdminSettingsModuleScreenState();
}

class _AdminSettingsModuleScreenState extends State<AdminSettingsModuleScreen> {
  dynamic _data;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _title => switch (widget.module) {
    AdminSettingsModule.ngo => 'NGO Profile & Bank',
    AdminSettingsModule.roles => 'Roles & Permissions',
    AdminSettingsModule.audit => 'Security & Audit Logs',
    AdminSettingsModule.announcements => 'Announcements',
    AdminSettingsModule.app => 'Application Settings',
  };
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = switch (widget.module) {
        AdminSettingsModule.ngo => await Future.wait([
          AdminSettingsRepository.ngoProfile(),
          AdminSettingsRepository.bank(),
        ]),
        AdminSettingsModule.roles => await AdminSettingsRepository.roles(),
        AdminSettingsModule.audit => await AdminSettingsRepository.auditLogs(),
        AdminSettingsModule.announcements =>
          await AdminSettingsRepository.announcements(),
        AdminSettingsModule.app => await AdminSettingsRepository.appSettings(),
      };
      if (mounted) {
        setState(() {
          _data = value;
          _loading = false;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_title),
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
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
        : switch (widget.module) {
            AdminSettingsModule.ngo => _ngo(),
            AdminSettingsModule.roles => _roles(),
            AdminSettingsModule.audit => _audit(),
            AdminSettingsModule.announcements => _announcements(),
            AdminSettingsModule.app => _app(),
          },
  );

  Widget _ngo() {
    final profile = Map<String, dynamic>.from((_data as List)[0]);
    final bank = Map<String, dynamic>.from((_data as List)[1]);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _editCard('NGO Profile', profile, const [
          'name',
          'registration_number',
          'email',
          'phone',
          'address',
          'website',
        ], AdminSettingsRepository.updateNgoProfile),
        const SizedBox(height: 12),
        _editCard(
          'Official Bank / UPI',
          bank,
          const [
            'account_holder',
            'bank_name',
            'account_number',
            'ifsc_code',
            'upi_id',
            'qr_url',
          ],
          AdminSettingsRepository.updateBank,
          warning:
              'Saving bank details requires explicit confirmation and creates an audit log.',
        ),
      ],
    );
  }

  Widget _editCard(
    String title,
    Map<String, dynamic> data,
    List<String> keys,
    Future<Map<String, dynamic>> Function(Map<String, dynamic>) save, {
    String? warning,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            if (warning != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  warning,
                  style: const TextStyle(
                    color: AppColors.softRed,
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            ...keys.map(
              (key) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(_label(key)),
                subtitle: Text('${data[key] ?? "Not set"}'),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _editMap(title, data, keys, save),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMap(
    String title,
    Map<String, dynamic> values,
    List<String> keys,
    Future<Map<String, dynamic>> Function(Map<String, dynamic>) save,
  ) async {
    final controllers = {
      for (final key in keys)
        key: TextEditingController(text: '${values[key] ?? ''}'),
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              children: keys
                  .map(
                    (key) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: TextField(
                        controller: controllers[key],
                        decoration: InputDecoration(labelText: _label(key)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await save({
        for (final entry in controllers.entries)
          entry.key: entry.value.text.trim().isEmpty
              ? null
              : entry.value.text.trim(),
      });
      await _load();
    }
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Widget _roles() {
    final roles = _data as List<dynamic>;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: roles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = roles[i] as Map<String, dynamic>;
        final permissions = (item['permissions'] as List<dynamic>)
            .cast<String>();
        return Card(
          child: ExpansionTile(
            title: Text(
              _label(item['role'] as String),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text('${permissions.length} permissions'),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: permissions
                      .map((p) => Chip(label: Text(_label(p))))
                      .toList(),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    _editPermissions(item['role'] as String, permissions),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Edit permissions'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editPermissions(String role, List<String> permissions) async {
    final controller = TextEditingController(text: permissions.join(', '));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permissions: ${_label(role)}'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            helperText: 'Comma-separated permission identifiers',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AdminSettingsRepository.updatePermissions(
        role,
        controller.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );
      await _load();
    }
    controller.dispose();
  }

  Widget _audit() {
    final logs = _data as List<dynamic>;
    return logs.isEmpty
        ? const Center(child: Text('No audit events yet.'))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, i) {
              final item = logs[i] as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(
                  Icons.security_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  _label(item['action'] as String),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${item['entity_type'] ?? 'platform'} · ${item['created_at'] ?? ''}\n${item['details_json'] ?? ''}',
                ),
              );
            },
          );
  }

  Widget _announcements() {
    final items = _data as List<dynamic>;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: _createAnnouncement,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Announcement'),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No announcements yet.'),
            ),
          )
        else
          ...items.map((raw) {
            final item = raw as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(
                  item['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${item['message']}\nAudience: ${item['audience_role'] ?? 'All roles'}',
                ),
                trailing: IconButton(
                  onPressed: () async {
                    await AdminSettingsRepository.deleteAnnouncement(
                      item['id'] as int,
                    );
                    await _load();
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.softRed,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _createAnnouncement() async {
    final title = TextEditingController(), message = TextEditingController();
    String? role;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: message,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Audience'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All roles')),
                  DropdownMenuItem(value: 'student', child: Text('Students')),
                  DropdownMenuItem(value: 'mentor', child: Text('Counsellors')),
                  DropdownMenuItem(
                    value: 'event_manager',
                    child: Text('Event Managers'),
                  ),
                  DropdownMenuItem(
                    value: 'content_creator',
                    child: Text('Content Creators'),
                  ),
                ],
                onChanged: (v) => setLocal(() => role = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
    if (ok == true &&
        title.text.trim().isNotEmpty &&
        message.text.trim().isNotEmpty) {
      await AdminSettingsRepository.createAnnouncement(
        title.text.trim(),
        message.text.trim(),
        role,
      );
      await _load();
    }
    title.dispose();
    message.dispose();
  }

  Widget _app() {
    final values = Map<String, dynamic>.from(
      (_data as Map<String, dynamic>)['values'] as Map<String, dynamic>,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Feature flags and platform defaults',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...values.entries.map(
          (entry) => ListTile(
            title: Text(_label(entry.key)),
            trailing: Text('${entry.value}'),
          ),
        ),
        FilledButton.icon(
          onPressed: () => _editAppSettings(values),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add or Update Setting'),
        ),
      ],
    );
  }

  Future<void> _editAppSettings(Map<String, dynamic> values) async {
    final key = TextEditingController(), value = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Application Setting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: key,
              decoration: const InputDecoration(labelText: 'Key'),
            ),
            TextField(
              controller: value,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && key.text.trim().isNotEmpty) {
      dynamic parsed = value.text.trim();
      if (parsed == 'true') parsed = true;
      if (parsed == 'false') parsed = false;
      await AdminSettingsRepository.updateAppSettings({
        key.text.trim(): parsed,
      });
      await _load();
    }
    key.dispose();
    value.dispose();
  }

  String _label(String value) => value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
