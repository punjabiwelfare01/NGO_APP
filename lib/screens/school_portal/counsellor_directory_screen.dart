import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../repositories/api_client.dart';
import '../../viewmodels/counsellor_viewmodel.dart';
import '../../widgets/app_card.dart';
import 'counsellor_profile_screen.dart';

class CounsellorDirectoryScreen extends StatefulWidget {
  const CounsellorDirectoryScreen({this.viewModel, super.key});

  final CounsellorViewModel? viewModel;

  @override
  State<CounsellorDirectoryScreen> createState() =>
      _CounsellorDirectoryScreenState();
}

class _CounsellorDirectoryScreenState extends State<CounsellorDirectoryScreen> {
  late final CounsellorViewModel _vm;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = widget.viewModel ?? CounsellorViewModel();
    _vm.load();
    _searchCtrl.addListener(() {
      _vm.applyFilter(_vm.filter.copyWith(searchQuery: _searchCtrl.text));
    });
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _vm.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              _AppBar(vm: _vm, searchCtrl: _searchCtrl),
              if (_vm.state == CounsellorLoadState.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Trust Banner
                const SliverToBoxAdapter(child: _TrustBanner()),
                // Filter chips
                SliverToBoxAdapter(child: _FilterBar(vm: _vm)),
                // Active filter indicator
                if (_vm.filter.hasActiveFilter)
                  SliverToBoxAdapter(child: _ActiveFilterBar(vm: _vm)),
                // Featured section (only when no filters active)
                if (!_vm.filter.hasActiveFilter &&
                    _vm.featuredCounsellors.isNotEmpty)
                  SliverToBoxAdapter(child: _FeaturedSection(vm: _vm)),
                // All counsellors heading
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                    child: Row(
                      children: [
                        Text(
                          _vm.filter.hasActiveFilter
                              ? '${_vm.filtered.length} Results'
                              : 'All Verified Counsellors',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_vm.allCounsellors.length} verified',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Counsellor list
                if (_vm.filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onClear: _vm.clearFilters),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CounsellorCard(
                            counsellor: _vm.filtered[i],
                            onTap: () => _openProfile(_vm.filtered[i]),
                            onRequest: () => _openProfile(_vm.filtered[i]),
                          ),
                        ),
                        childCount: _vm.filtered.length,
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openProfile(CounsellorProfile c) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CounsellorProfileScreen(counsellor: c, vm: _vm),
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({required this.vm, required this.searchCtrl});
  final CounsellorViewModel vm;
  final TextEditingController searchCtrl;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0D2B5E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
          onPressed: () => _showFilterSheet(context),
          tooltip: 'Advanced Filters',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D2B5E), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF64B5F6),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PUNJABI WELFARE TRUST',
                        style: TextStyle(
                          color: Color(0xFF90CAF9),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verified Counsellor Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Trusted experts for your school sessions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search counsellors, expertise...',
                        hintStyle: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.muted,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(vm: vm),
    );
  }
}

// ─── Trust Banner ─────────────────────────────────────────────────────────────

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF2E7D32),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy-Protected & NGO Verified',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'All profiles are admin-verified. Government IDs, army IDs, and personal contact details are never displayed publicly.',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.vm});
  final CounsellorViewModel vm;

  static const _quickFilters = [
    'Defence / NDA Guidance',
    'Career Guidance',
    'Mental Wellness',
    'Cyber Safety',
    'Anti-Drug Awareness',
    'Women Safety',
    'Government Mentor',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Text(
            'Filter by Category',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _quickFilters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final tag = _quickFilters[i];
              final active = vm.filter.category?.filterTag == tag;
              return GestureDetector(
                onTap: () {
                  final cat = CounsellorCategory.values
                      .where((c) => c.filterTag == tag)
                      .toList();
                  if (cat.isEmpty) return;
                  if (active) {
                    vm.applyFilter(vm.filter.copyWith(clearCategory: true));
                  } else {
                    vm.applyFilter(vm.filter.copyWith(category: cat.first));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF1565C0) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF1565C0)
                          : AppColors.muted.withValues(alpha: 0.25),
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF1565C0,
                              ).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Mode + Available this week toggles
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ModeChip(
                label: 'Online',
                icon: Icons.videocam_rounded,
                active: vm.filter.sessionMode == SessionMode.online,
                color: const Color(0xFF1565C0),
                onTap: () => vm.applyFilter(
                  vm.filter.sessionMode == SessionMode.online
                      ? vm.filter.copyWith(clearMode: true)
                      : vm.filter.copyWith(sessionMode: SessionMode.online),
                ),
              ),
              _ModeChip(
                label: 'Offline',
                icon: Icons.location_on_rounded,
                active: vm.filter.sessionMode == SessionMode.offline,
                color: const Color(0xFF2E7D32),
                onTap: () => vm.applyFilter(
                  vm.filter.sessionMode == SessionMode.offline
                      ? vm.filter.copyWith(clearMode: true)
                      : vm.filter.copyWith(sessionMode: SessionMode.offline),
                ),
              ),
              _ModeChip(
                label: 'Available This Week',
                icon: Icons.calendar_today_rounded,
                active: vm.filter.availableThisWeek,
                color: const Color(0xFF6A1B9A),
                onTap: () => vm.applyFilter(
                  vm.filter.copyWith(
                    availableThisWeek: !vm.filter.availableThisWeek,
                  ),
                ),
              ),
              _ModeChip(
                label: 'Featured',
                icon: Icons.star_rounded,
                active: vm.filter.featuredOnly,
                color: const Color(0xFFF57F17),
                onTap: () => vm.applyFilter(
                  vm.filter.copyWith(featuredOnly: !vm.filter.featuredOnly),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : AppColors.muted.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? color : AppColors.muted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? color : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active Filter Bar ────────────────────────────────────────────────────────

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.vm});
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_rounded,
            size: 14,
            color: Color(0xFF1565C0),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _buildLabel(),
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: vm.clearFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.softRed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: AppColors.softRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildLabel() {
    final parts = <String>[];
    final f = vm.filter;
    if (f.category != null) parts.add(f.category!.filterTag);
    if (f.sessionMode != null) parts.add(f.sessionMode!.label);
    if (f.language != null) parts.add(f.language!);
    if (f.availableThisWeek) parts.add('Available This Week');
    if (f.featuredOnly) parts.add('Featured');
    if (f.searchQuery.isNotEmpty) parts.add('"${f.searchQuery}"');
    return '${vm.filtered.length} results for ${parts.join(' · ')}';
  }
}

// ─── Featured Section ─────────────────────────────────────────────────────────

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({required this.vm});
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFF57F17),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Featured Counsellors',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${vm.featuredCounsellors.length} experts',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: vm.featuredCounsellors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = vm.featuredCounsellors[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CounsellorProfileScreen(counsellor: c, vm: vm),
                  ),
                ),
                child: _FeaturedCard(counsellor: c),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.counsellor});
  final CounsellorProfile counsellor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            counsellor.category.color,
            counsellor.category.color.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: counsellor.category.color.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(counsellor: counsellor, radius: 22, textSize: 14),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              counsellor.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              counsellor.category.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.school_rounded,
                  color: Colors.white70,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '${counsellor.schoolSessionsCompleted} sessions',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  counsellor.sessionMode.icon,
                  color: Colors.white70,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Text(
                  counsellor.sessionMode.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Counsellor Card ──────────────────────────────────────────────────────────

class _CounsellorCard extends StatelessWidget {
  const _CounsellorCard({
    required this.counsellor,
    required this.onTap,
    required this.onRequest,
  });
  final CounsellorProfile counsellor;
  final VoidCallback onTap;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final c = counsellor;
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header strip
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: c.category.color.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: c.category.color.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      c.category.icon,
                      color: c.category.color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.category.label,
                      style: TextStyle(
                        color: c.category.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (c.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF57F17).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF57F17),
                            size: 10,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Color(0xFFF57F17),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Avatar row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(counsellor: c, radius: 28, textSize: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Verified by PWT',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (c.showRetiredStatus) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1565C0,
                                      ).withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c.publicStatusLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.designation,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats row
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _StatItem(
                          icon: Icons.school_rounded,
                          value: '${c.schoolSessionsCompleted}',
                          label: 'Sessions',
                        ),
                        _Divider(),
                        _StatItem(
                          icon: Icons.people_rounded,
                          value: c.studentsGuided >= 1000
                              ? '${(c.studentsGuided / 1000).toStringAsFixed(1)}K'
                              : '${c.studentsGuided}',
                          label: 'Students',
                        ),
                        _Divider(),
                        _StatItem(
                          icon: Icons.schedule_rounded,
                          value: '${c.yearsOfExperience}yr',
                          label: 'Experience',
                        ),
                        _Divider(),
                        _StatItem(
                          icon: c.sessionMode.icon,
                          value: c.sessionMode == SessionMode.both
                              ? 'Both'
                              : c.sessionMode.label,
                          label: 'Mode',
                          color: c.sessionMode.color,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Expertise chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: c.expertiseAreas
                        .take(3)
                        .map(
                          (e) =>
                              _ExpertiseChip(label: e, color: c.category.color),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  // Languages + slots
                  Row(
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        color: AppColors.muted,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.languages.join(' · '),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (c.availableThisWeek)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                color: Color(0xFF2E7D32),
                                size: 6,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Available this week',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // NGO verification ID
                  Row(
                    children: [
                      const Icon(
                        Icons.fingerprint_rounded,
                        color: AppColors.muted,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.ngoVerificationId,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  // CTAs
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.person_rounded, size: 15),
                          label: const Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.category.color,
                            side: BorderSide(
                              color: c.category.color.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onRequest,
                          icon: const Icon(Icons.send_rounded, size: 15),
                          label: const Text(
                            'Request',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: c.category.color,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.counsellor,
    required this.radius,
    required this.textSize,
  });
  final CounsellorProfile counsellor;
  final double radius;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    if (counsellor.photoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(ApiClient.resolveUrl(counsellor.photoUrl!)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: counsellor.category.color.withValues(alpha: 0.15),
      child: Text(
        counsellor.initialsAvatar,
        style: TextStyle(
          color: counsellor.category.color,
          fontSize: textSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ─── Small shared widgets ─────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.ink,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 30,
    color: AppColors.muted.withValues(alpha: 0.15),
  );
}

class _ExpertiseChip extends StatelessWidget {
  const _ExpertiseChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: AppColors.muted.withValues(alpha: 0.35),
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'No counsellors found',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or search terms.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Advanced Filter Sheet ────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.vm});
  final CounsellorViewModel vm;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late CounsellorFilter _local;

  @override
  void initState() {
    super.initState();
    _local = widget.vm.filter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Text(
                  'Advanced Filters',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _local = const CounsellorFilter());
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterSectionLabel('Session Mode'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: SessionMode.values
                        .map(
                          (m) => ChoiceChip(
                            label: Text(m.label),
                            selected: _local.sessionMode == m,
                            onSelected: (_) => setState(
                              () => _local = _local.sessionMode == m
                                  ? _local.copyWith(clearMode: true)
                                  : _local.copyWith(sessionMode: m),
                            ),
                            selectedColor: m.color.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: _local.sessionMode == m
                                  ? m.color
                                  : AppColors.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  _FilterSectionLabel('Language'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.vm.allLanguages
                        .map(
                          (lang) => ChoiceChip(
                            label: Text(lang),
                            selected: _local.language == lang,
                            onSelected: (_) => setState(
                              () => _local = _local.language == lang
                                  ? _local.copyWith(clearLanguage: true)
                                  : _local.copyWith(language: lang),
                            ),
                            selectedColor: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: _local.language == lang
                                  ? const Color(0xFF1565C0)
                                  : AppColors.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SwitchTile(
                          label: 'Available This Week',
                          icon: Icons.calendar_today_rounded,
                          value: _local.availableThisWeek,
                          onChanged: (v) => setState(
                            () =>
                                _local = _local.copyWith(availableThisWeek: v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SwitchTile(
                          label: 'Featured Only',
                          icon: Icons.star_rounded,
                          value: _local.featuredOnly,
                          onChanged: (v) => setState(
                            () => _local = _local.copyWith(featuredOnly: v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        widget.vm.applyFilter(_local);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.ink,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF1565C0).withValues(alpha: 0.06)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF1565C0).withValues(alpha: 0.3)
              : AppColors.muted.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? const Color(0xFF1565C0) : AppColors.muted,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? const Color(0xFF1565C0) : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF1565C0),
            activeTrackColor: const Color(0xFF1565C0).withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
