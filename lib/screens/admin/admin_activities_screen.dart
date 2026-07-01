import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../repositories/event_manager_repository.dart';
import 'admin_activity_detail_screen.dart';

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key});

  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<EMActivity> _activities = [];
  Map<String, dynamic> _summary = {};
  bool _loading = true;
  String? _error;

  String? _filterStatus;
  String? _filterCategory;

  static const _tabs = ['All', 'Active', 'Draft', 'Completed', 'Cancelled'];
  static const _tabStatuses = [null, 'active', 'draft', 'completed', 'cancelled'];

  static const _categories = [
    null,
    'education_support',
    'awareness_programs',
    'school_partner',
    'donation_drives',
    'event_organization',
    'digital_branding',
    'documentation',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _filterStatus = _tabStatuses[_tabController.index]);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        EventManagerRepository.adminGetAllActivities(
          status: _filterStatus,
          category: _filterCategory,
        ),
        EventManagerRepository.adminGetActivitiesSummary(),
      ]);
      setState(() {
        _activities = results[0] as List<EMActivity>;
        _summary = results[1] as Map<String, dynamic>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<EMActivity> get _filtered {
    var list = _activities;
    if (_filterStatus != null) {
      list = list.where((a) => a.status.name == _filterStatus).toList();
    }
    if (_filterCategory != null) {
      list = list.where((a) => a.category == _filterCategory).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          if (_summary.isNotEmpty) _SummaryBar(summary: _summary),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _load)
                    : _filtered.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _filtered.length,
                              separatorBuilder: (context, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) =>
                                  _AdminActivityCard(activity: _filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _FilterSheet(
        selectedCategory: _filterCategory,
        categories: _categories,
        onApply: (cat) {
          setState(() => _filterCategory = cat);
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }
}

// ── Summary Bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.summary});
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final acts = summary['activities'] as Map<String, dynamic>? ?? {};
    final asgn = summary['assignments'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF0F4FF),
      child: Row(
        children: [
          _s('${acts['total'] ?? 0}', 'Total', const Color(0xFF1565C0)),
          _div(),
          _s('${acts['active'] ?? 0}', 'Active', const Color(0xFF2E7D32)),
          _div(),
          _s('${acts['completed'] ?? 0}', 'Done', const Color(0xFF1565C0)),
          _div(),
          _s('${asgn['total'] ?? 0}', 'Assigned', const Color(0xFFE65100)),
          _div(),
          _s('${asgn['pending_approvals'] ?? 0}', 'Pending',
              const Color(0xFFF57F17)),
        ],
      ),
    );
  }

  static Widget _s(String val, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(val,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 15)),
            Text(label,
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 10)),
          ],
        ),
      );

  static Widget _div() => Container(
      height: 30, width: 1, color: AppColors.muted.withValues(alpha: 0.2));
}

// ── Admin Activity Card ───────────────────────────────────────────────────────

class _AdminActivityCard extends StatelessWidget {
  const _AdminActivityCard({required this.activity});
  final EMActivity activity;

  @override
  Widget build(BuildContext context) {
    final status = activity.status;
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AdminActivityDetailScreen(
            activityId: activity.id,
            activityTitle: activity.title,
          ),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(status.icon, color: status.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.ink)),
                        Text(
                          _catLabel(activity.category),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 8),

              // Created by + location
              Row(
                children: [
                  if (activity.createdByName != null) ...[
                    const Icon(Icons.person_outline_rounded,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(activity.createdByName!,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                  if (activity.location != null) ...[
                    const Icon(Icons.place_rounded,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(activity.location!,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Stats row
              Row(
                children: [
                  _meta(Icons.people_rounded,
                      '${activity.assignedStudents} students'),
                  const SizedBox(width: 12),
                  _meta(Icons.hourglass_top_rounded,
                      '${activity.pendingApprovals} pending'),
                  const SizedBox(width: 12),
                  _meta(Icons.workspace_premium_outlined,
                      '${activity.certificatesGenerated} certs'),
                  if (activity.impactStoryStatus != null) ...[
                    const SizedBox(width: 12),
                    _meta(Icons.auto_awesome_rounded,
                        'Impact: ${activity.impactStoryStatus}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _catLabel(String cat) => cat
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  static Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 3),
          Text(text,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.label,
          style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w700),
        ),
      );
}

// ── Filter Sheet ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.selectedCategory,
    required this.categories,
    required this.onApply,
  });

  final String? selectedCategory;
  final List<String?> categories;
  final void Function(String?) onApply;

  static String _catLabel(String? c) => c == null
      ? 'All Categories'
      : c.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      shrinkWrap: true,
      children: [
        const Text('Filter by Category',
            style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        const SizedBox(height: 12),
        ...categories.map(
          (cat) => ListTile(
            title: Text(_catLabel(cat)),
            trailing: selectedCategory == cat
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary)
                : const Icon(Icons.circle_outlined, color: AppColors.muted),
            onTap: () => onApply(cat),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

// ── Empty / Error States ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 60,
                color: AppColors.muted.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            const Text('No activities found',
                style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Try changing the filter',
                style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.softRed, size: 40),
            const SizedBox(height: 12),
            Text(error,
                style: const TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
