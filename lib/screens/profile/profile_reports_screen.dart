import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../models/platform_models.dart';
import '../../repositories/platform_repository.dart';

class ProfileReportsScreen extends StatefulWidget {
  const ProfileReportsScreen({super.key});
  @override
  State<ProfileReportsScreen> createState() => _ProfileReportsScreenState();
}

class _ProfileReportsScreenState extends State<ProfileReportsScreen> {
  List<ProfileReport> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await PlatformRepository.reports();
      if (mounted) {
        setState(() {
          _items = value;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Reports')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: TextButton(onPressed: _load, child: Text('Retry\n$_error')),
          )
        : _items.isEmpty
        ? const Center(
            child: Text(
              'No approved activity reports yet.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (_, i) {
                final item = _items[i];
                return Card(
                  child: ExpansionTile(
                    leading: Icon(_icon(item.type), color: AppColors.primary),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('${item.summary} · ${item.status}'),
                    children: item.details.entries
                        .map(
                          (entry) => ListTile(
                            dense: true,
                            title: Text(_label(entry.key)),
                            trailing: Text('${entry.value ?? '—'}'),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
  );
  IconData _icon(String type) => switch (type) {
    'donation' => Icons.currency_rupee_rounded,
    'certificate' => Icons.workspace_premium_rounded,
    'event' => Icons.event_rounded,
    _ => Icons.assignment_turned_in_rounded,
  };
  String _label(String value) => value
      .split('_')
      .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
}
