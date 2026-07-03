import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/counselling_models.dart';
import '../../../repositories/counselling_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/top_header.dart';

class CounsellingAdminScreen extends StatefulWidget {
  const CounsellingAdminScreen({super.key});

  @override
  State<CounsellingAdminScreen> createState() => _CounsellingAdminScreenState();
}

class _CounsellingAdminScreenState extends State<CounsellingAdminScreen> {
  ViewState _state = ViewState.loading;
  List<MentorProfile> _mentors = [];
  CounsellingAnalytics? _analytics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = ViewState.loading;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CounsellingRepository.getMentors(),
        CounsellingRepository.getAnalytics(),
      ]);
      if (!mounted) return;
      setState(() {
        _mentors = results[0] as List<MentorProfile>;
        _analytics = results[1] as CounsellingAnalytics;
        _state = ViewState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = ViewState.error;
        _error = 'Could not load management data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMentorSheet(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Mentor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const TopHeader(
              title: 'Counselling Admin',
              subtitle: 'Manage mentors, slots, and analytics',
              actionIcon: Icons.admin_panel_settings_rounded,
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_state == ViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_state == ViewState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Error', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_analytics != null) _AnalyticsCard(analytics: _analytics!),
        const SizedBox(height: 16),
        const Text('Mentor Profiles',
            style: TextStyle(
                color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (_mentors.isEmpty)
          const Text('No mentor profiles yet. Add one using the button below.',
              style: TextStyle(color: AppColors.muted))
        else
          ..._mentors.map((m) => _MentorAdminTile(
                mentor: m,
                onEdit: () => _showEditMentorSheet(context, m),
              )),
        const SizedBox(height: 80),
      ],
    );
  }

  void _showAddMentorSheet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MentorFormSheet(
        onSave: (data) async {
          Navigator.of(context).pop();
          try {
            await CounsellingRepository.createMentorProfile(data);
            await _load();
            messenger.showSnackBar(
              const SnackBar(content: Text('Mentor profile created.')),
            );
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Failed to create mentor profile.')),
            );
          }
        },
      ),
    );
  }

  void _showEditMentorSheet(BuildContext context, MentorProfile mentor) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MentorFormSheet(
        initial: mentor,
        onSave: (data) async {
          Navigator.of(context).pop();
          try {
            await CounsellingRepository.updateMentorProfile(mentor.id, data);
            await _load();
            messenger.showSnackBar(
              const SnackBar(content: Text('Mentor profile updated.')),
            );
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Failed to update mentor profile.')),
            );
          }
        },
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.analytics});

  final CounsellingAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview',
              style: TextStyle(
                  color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(label: 'Mentors', value: '${analytics.activeMentors}', icon: Icons.people_rounded),
              const SizedBox(width: 12),
              _Stat(label: 'Bookings', value: '${analytics.totalBookings}', icon: Icons.event_available_rounded),
              const SizedBox(width: 12),
              _Stat(label: 'Upcoming', value: '${analytics.upcomingBookings}', icon: Icons.schedule_rounded),
              const SizedBox(width: 12),
              _Stat(label: 'Completed', value: '${analytics.completedSessions}', icon: Icons.check_circle_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MentorAdminTile extends StatelessWidget {
  const _MentorAdminTile({required this.mentor, required this.onEdit});

  final MentorProfile mentor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.lavender,
              backgroundImage: mentor.profileImageUrl != null
                  ? NetworkImage(mentor.profileImageUrl!)
                  : null,
              child: mentor.profileImageUrl == null
                  ? Text(mentor.displayName[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w900))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mentor.displayName,
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w700)),
                  if (mentor.expertise != null)
                    Text(mentor.expertise!,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: mentor.isActive
                              ? AppColors.secondary.withValues(alpha: 0.18)
                              : AppColors.muted.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          mentor.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: mentor.isActive ? AppColors.secondary : AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentorFormSheet extends StatefulWidget {
  const _MentorFormSheet({required this.onSave, this.initial});

  final MentorProfile? initial;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<_MentorFormSheet> createState() => _MentorFormSheetState();
}

class _MentorFormSheetState extends State<_MentorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.displayName);
  late final _bio = TextEditingController(text: widget.initial?.bio);
  late final _expertise = TextEditingController(text: widget.initial?.expertise);
  late final _imageUrl = TextEditingController(text: widget.initial?.profileImageUrl);
  String? _category;

  static const _categories = ['Academic', 'Career', 'Wellness', 'Mental Health', 'Life Skills'];

  @override
  void initState() {
    super.initState();
    _category = widget.initial?.category;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _expertise.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSave({
      'display_name': _name.text.trim(),
      'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      'expertise': _expertise.text.trim().isEmpty ? null : _expertise.text.trim(),
      'category': _category,
      'profile_image_url': _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? 'Add Mentor Profile' : 'Edit Mentor Profile',
                style: const TextStyle(
                    color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                decoration: const InputDecoration(
                    labelText: 'Display Name *', border: OutlineInputBorder()),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expertise,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                decoration: const InputDecoration(
                    labelText: 'Expertise (e.g. Career, Mental Health)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                    labelText: 'Category', border: OutlineInputBorder()),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bio,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Bio', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(
                    labelText: 'Profile Image URL', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(widget.initial == null ? 'Create Profile' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
