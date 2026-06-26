import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../models/platform_models.dart';
import '../../repositories/platform_repository.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});
  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  UserSettings? _settings;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await PlatformRepository.settings();
      if (mounted) {
        setState(() {
          _settings = value;
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

  Future<void> _save(Map<String, dynamic> value) async {
    try {
      final updated = await PlatformRepository.updateSettings(value);
      if (mounted) setState(() => _settings = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save settings: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: Text('Retry\n$_error'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                SwitchListTile(
                  title: const Text('In-app notifications'),
                  value: s!.inAppEnabled,
                  onChanged: (v) => _save({'in_app_enabled': v}),
                ),
                SwitchListTile(
                  title: const Text('Email notifications'),
                  value: s.emailEnabled,
                  onChanged: (v) => _save({'email_enabled': v}),
                ),
                SwitchListTile(
                  title: const Text('Event reminders'),
                  value: s.eventReminders,
                  onChanged: (v) => _save({'event_reminders': v}),
                ),
                SwitchListTile(
                  title: const Text('Counselling reminders'),
                  value: s.counsellingReminders,
                  onChanged: (v) => _save({'counselling_reminders': v}),
                ),
                SwitchListTile(
                  title: const Text('Assignment updates'),
                  value: s.assignmentUpdates,
                  onChanged: (v) => _save({'assignment_updates': v}),
                ),
                SwitchListTile(
                  title: const Text('Impact updates'),
                  value: s.impactUpdates,
                  onChanged: (v) => _save({'impact_updates': v}),
                ),
                const Divider(),
                const Text(
                  'Privacy & language',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                DropdownButtonFormField<String>(
                  initialValue: s.language,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'pa', child: Text('Punjabi')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                  ],
                  onChanged: (v) {
                    if (v != null) _save({'language': v});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: s.profileVisibility,
                  decoration: const InputDecoration(
                    labelText: 'Profile visibility',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ngo_members',
                      child: Text('NGO members'),
                    ),
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                  ],
                  onChanged: (v) {
                    if (v != null) _save({'profile_visibility': v});
                  },
                ),
                SwitchListTile(
                  title: const Text('Show my name on approved impact posts'),
                  value: s.showImpactName,
                  onChanged: (v) => _save({'show_impact_name': v}),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Password changes remain available from the main Profile screen.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
    );
  }
}
