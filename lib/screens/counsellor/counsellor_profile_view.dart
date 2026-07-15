import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models/counsellor_models.dart';
import '../../repositories/api_client.dart';
import '../../repositories/auth_repository.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';
import '../../widgets/profile_section.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────

const _kBlue   = Color(0xFF2563EB);
const _kGreen  = Color(0xFF16A34A);
const _kAmber  = Color(0xFFF59E0B);
const _kPurple = Color(0xFF8B5CF6);
const _kNavy   = Color(0xFF0A1F44);
const _kInk    = Color(0xFF17324D);
const _kMuted  = Color(0xFF8E96A3);
const _kBg     = Color(0xFFFAF7F2);
const _kCard   = Colors.white;

// ─── Root View ────────────────────────────────────────────────────────────────

class CounsellorProfileView extends StatelessWidget {
  const CounsellorProfileView({required this.vm, super.key});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final p = vm.profile;
        return Scaffold(
          backgroundColor: _kBg,
          body: CustomScrollView(
            slivers: [
              _HeroSliver(
                profile: p,
                vm: vm,
                onEdit: () => _openEdit(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1 — Overview stats
                    _OverviewRow(profile: p, vm: vm),
                    const SizedBox(height: 16),
                    // 2 — Professional info
                    _ProfessionalCard(profile: p),
                    const SizedBox(height: 16),
                    // 3 — About
                    _AboutCard(bio: p.shortBio),
                    const SizedBox(height: 16),
                    // 4 — Expertise chips
                    _ExpertiseCard(profile: p),
                    if (p.qualifications.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _QualificationsCard(items: p.qualifications),
                    ],
                    if (p.recognitionProof.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _RecognitionCard(items: p.recognitionProof),
                    ],
                    // 5 — Availability
                    const SizedBox(height: 16),
                    _AvailabilityManagementSection(vm: vm),
                    // 8 — Public preview
                    const SizedBox(height: 16),
                    _PublicPreviewCard(profile: p),
                    // 9 — Settings
                    const SizedBox(height: 16),
                    _SettingsCard(vm: vm),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCounsellorProfileSheet(vm: vm),
    );
  }
}

// ─── Hero Sliver ──────────────────────────────────────────────────────────────

class _HeroSliver extends StatelessWidget {
  const _HeroSliver({
    required this.profile,
    required this.vm,
    required this.onEdit,
  });
  final CounsellorProfile profile;
  final CounsellorHomeViewModel vm;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: _kNavy,
      surfaceTintColor: _kNavy,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kNavy, Color(0xFF1565C0)],
                ),
              ),
            ),
            // NGO watermark
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.06,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assests/ngo_logo.jpeg',
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 160,
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with camera button
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: .15),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: .4),
                                  width: 2.5),
                            ),
                            foregroundDecoration: p.photoUrl != null
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          ApiClient.resolveUrl(p.photoUrl!)),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : null,
                            child: p.photoUrl == null
                                ? Center(
                                    child: Text(
                                      p.initialsAvatar,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          // Online dot
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _kNavy, width: 2),
                              ),
                            ),
                          ),
                          // Camera edit
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: GestureDetector(
                              onTap: onEdit,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.photo_camera_rounded,
                                    size: 14,
                                    color: _kBlue),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Name + designation + badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.designation,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .75),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Verified chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kGreen.withValues(alpha: .2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF81C784)
                                        .withValues(alpha: .4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      color: Color(0xFF81C784), size: 12),
                                  SizedBox(width: 5),
                                  Text(
                                    'Verified NGO Counsellor',
                                    style: TextStyle(
                                      color: Color(0xFFB9F6CA),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // ID badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p.ngoVerificationId,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit button
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded,
                            size: 13, color: Colors.white),
                        label: const Text('Edit',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: .5)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Category chip + NGO name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: p.category.color.withValues(alpha: .3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(p.category.icon,
                                color: Colors.white, size: 11),
                            const SizedBox(width: 5),
                            Text(
                              p.category.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Punjabi Welfare Service Organisation',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .6),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
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
      title: const Text(
        'My Profile',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─── Overview Row ─────────────────────────────────────────────────────────────

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.profile, required this.vm});
  final CounsellorProfile profile;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final stats = [
      (
        value: '${p.yearsOfExperience}',
        label: 'Yrs Exp.',
        icon: Icons.military_tech_rounded,
        color: _kBlue,
      ),
      (
        value: '${p.schoolSessionsCompleted}',
        label: 'Sessions',
        icon: Icons.people_rounded,
        color: _kGreen,
      ),
      (
        value: '${p.studentsGuided}+',
        label: 'Students',
        icon: Icons.school_rounded,
        color: _kPurple,
      ),
      (
        value: vm.stats.avgRating > 0
            ? vm.stats.avgRating.toStringAsFixed(1)
            : '—',
        label: 'Rating',
        icon: Icons.star_rounded,
        color: _kAmber,
      ),
    ];
    return Row(
      children: stats.map((s) {
        final idx = stats.indexOf(s);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: idx < stats.length - 1 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.color.withValues(alpha: .15)),
            ),
            child: Column(
              children: [
                Icon(s.icon, color: s.color, size: 20),
                const SizedBox(height: 5),
                Text(
                  s.value,
                  style: TextStyle(
                    color: s.color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.label,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Professional Info Card ───────────────────────────────────────────────────

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({required this.profile});
  final CounsellorProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return ProfileSection(
      title: 'Professional Information',
      rows: [
        ProfileRow(Icons.badge_rounded, 'Designation', p.designation),
        ProfileRow(Icons.category_rounded, 'Category', p.category.label),
        ProfileRow(Icons.history_rounded, 'Experience', '${p.yearsOfExperience} years'),
        ProfileRow(Icons.translate_rounded, 'Languages', p.languages.join(' • ')),
        ProfileRow(Icons.swap_horiz_rounded, 'Mode', p.sessionMode.label),
        if (p.serviceBackground.isNotEmpty)
          ProfileRow(Icons.work_rounded, 'Background', p.serviceBackground),
        if (p.showRetiredStatus && p.publicStatusLabel.isNotEmpty)
          ProfileRow(Icons.info_rounded, 'Status', p.publicStatusLabel),
      ],
    );
  }
}

// ─── About Card ───────────────────────────────────────────────────────────────

class _AboutCard extends StatefulWidget {
  const _AboutCard({required this.bio});
  final String bio;

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      icon: Icons.info_outline_rounded,
      title: 'About Me',
      color: _kGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.bio.isNotEmpty
                ? widget.bio
                : 'No bio added yet. Tap Edit Profile to add one.',
            style: TextStyle(
              color: widget.bio.isNotEmpty ? _kInk : _kMuted,
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            maxLines: _expanded ? null : 4,
            overflow: _expanded ? null : TextOverflow.ellipsis,
          ),
          if (widget.bio.length > 200) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  color: _kGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Expertise Card ───────────────────────────────────────────────────────────

class _ExpertiseCard extends StatelessWidget {
  const _ExpertiseCard({required this.profile});
  final CounsellorProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p.expertiseAreas.isEmpty) return const SizedBox.shrink();
    return _ProfileCard(
      icon: Icons.star_rounded,
      title: 'Areas of Expertise',
      color: _kAmber,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.expertiseAreas.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.category.color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: p.category.color.withValues(alpha: .2)),
            ),
            child: Text(
              e,
              style: TextStyle(
                color: p.category.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Qualifications Card ──────────────────────────────────────────────────────

class _QualificationsCard extends StatelessWidget {
  const _QualificationsCard({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      icon: Icons.workspace_premium_rounded,
      title: 'Qualifications & Certifications',
      color: _kPurple,
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: _kGreen, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Recognition Card ────────────────────────────────────────────────────────

class _RecognitionCard extends StatelessWidget {
  const _RecognitionCard({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      icon: Icons.emoji_events_rounded,
      title: 'Recognition & Appreciation',
      color: _kAmber,
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.military_tech_rounded,
                    size: 18, color: _kAmber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      color: _kInk,
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Public Profile Preview Card ─────────────────────────────────────────────

class _PublicPreviewCard extends StatelessWidget {
  const _PublicPreviewCard({required this.profile});
  final CounsellorProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.preview_rounded, color: _kBlue, size: 15),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Public Profile Preview',
                  style: TextStyle(
                    color: _kInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'What schools see',
                  style: TextStyle(
                    color: _kGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.category.color.withValues(alpha: .2)),
            boxShadow: [
              BoxShadow(
                color: p.category.color.withValues(alpha: .08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: avatar + name + designation + category chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        p.category.color.withValues(alpha: .15),
                    backgroundImage: p.photoUrl != null
                        ? NetworkImage(
                            ApiClient.resolveUrl(p.photoUrl!))
                        : null,
                    child: p.photoUrl == null
                        ? Text(
                            p.initialsAvatar,
                            style: TextStyle(
                              color: p.category.color,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                  color: _kInk,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.verified_rounded,
                                size: 14, color: _kGreen),
                          ],
                        ),
                        Text(
                          p.designation,
                          style: const TextStyle(
                              color: _kMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.category.color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(p.category.icon,
                                  size: 11, color: p.category.color),
                              const SizedBox(width: 4),
                              Text(
                                p.category.label,
                                style: TextStyle(
                                  color: p.category.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bio
              if (p.shortBio.isNotEmpty)
                Text(
                  p.shortBio,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 10),
              // Top 3 skills
              if (p.expertiseAreas.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: p.expertiseAreas.take(3).map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.category.color.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        e,
                        style: TextStyle(
                          color: p.category.color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Stats row
              Row(
                children: [
                  _previewStat(Icons.timer_rounded,
                      '${p.yearsOfExperience} yrs', 'Experience'),
                  _previewStat(Icons.event_rounded,
                      '${p.schoolSessionsCompleted}', 'Sessions'),
                  _previewStat(
                      Icons.people_rounded, '${p.studentsGuided}+', 'Students'),
                ],
              ),
              const SizedBox(height: 12),
              // NGO badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _kGreen.withValues(alpha: .2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded,
                        size: 13, color: _kGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Verified by Punjabi Welfare Trust · ${p.ngoVerificationId}',
                      style: const TextStyle(
                        color: _kGreen,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewStat(IconData icon, String value, String label) =>
      Expanded(
        child: Row(
          children: [
            Icon(icon, size: 14, color: _kMuted),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: _kInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
                Text(label,
                    style: const TextStyle(
                        color: _kMuted, fontSize: 9.5)),
              ],
            ),
          ],
        ),
      );
}

// ─── Settings Card ────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ProfileActionsCard(
      title: 'Account Actions',
      actions: [
        ProfileActionTile(
          icon: Icons.lock_outline_rounded,
          color: _kBlue,
          label: 'Change Password',
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _ChangePasswordSheet(),
          ),
        ),
        ProfileActionTile(
          icon: Icons.logout_rounded,
          color: const Color(0xFFC62828),
          label: 'Logout',
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
            'Are you sure you want to logout from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final nav = Navigator.of(context);
      try {
        await AuthRepository.logout();
      } catch (_) {}
      AppState.clear();
      nav.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}

// ─── Shared profile card shell ────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _kInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: _kMuted.withValues(alpha: .1)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── Availability Management Section ─────────────────────────────────────────

class _AvailabilityManagementSection extends StatefulWidget {
  const _AvailabilityManagementSection({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  State<_AvailabilityManagementSection> createState() =>
      _AvailabilityManagementSectionState();
}

class _AvailabilityManagementSectionState
    extends State<_AvailabilityManagementSection> {
  static const _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Saturday', 'Sunday',
  ];

  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await widget.vm.fetchWeeklyAvailability();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addSlot() async {
    int dayOfWeek = 0;
    String startTime = '09:00';
    String endTime = '10:00';
    String mode = 'both';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Weekly Slot',
              style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: dayOfWeek,
                  decoration:
                      _inputDecoration('Day', Icons.calendar_today_rounded),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                        value: i, child: Text(_dayNames[i])),
                  ),
                  onChanged: (v) => setS(() => dayOfWeek = v ?? 0),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: startTime,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(ctx).nextFocus(),
                  decoration: _inputDecoration(
                      'Start (HH:MM)', Icons.access_time_rounded),
                  onChanged: (v) => startTime = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: endTime,
                  decoration: _inputDecoration(
                      'End (HH:MM)', Icons.access_time_filled_rounded),
                  onChanged: (v) => endTime = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  decoration:
                      _inputDecoration('Mode', Icons.swap_horiz_rounded),
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Online')),
                    DropdownMenuItem(
                        value: 'offline', child: Text('Offline')),
                    DropdownMenuItem(value: 'both', child: Text('Both')),
                  ],
                  onChanged: (v) => setS(() => mode = v ?? 'both'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kBlue),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add Slot'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    setState(() => _loading = true);
    await widget.vm.addWeeklySlot({
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'mode': mode,
    });
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteSlot(int slotId) async {
    setState(() => _loading = true);
    await widget.vm.deleteWeeklySlot(slotId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final slots = widget.vm.weeklySlots;
    return _ProfileCard(
      icon: Icons.event_repeat_rounded,
      title: 'Weekly Availability',
      color: _kGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your available session slots for schools.',
                  style: TextStyle(color: _kMuted, fontSize: 11.5),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: _kMuted,
                tooltip: 'Refresh',
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _addSlot,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Add Slot',
                    style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: _kGreen,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (slots == null || slots.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _kMuted.withValues(alpha: .1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.event_busy_rounded,
                      color: _kMuted, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No slots set. Tap "Add Slot" to add your availability.',
                      style: TextStyle(color: _kMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            ...slots.map((slot) {
              final day = (slot['day_of_week'] as int?) ?? 0;
              final dayName =
                  day >= 0 && day < 7 ? _dayNames[day] : 'Day $day';
              final start = slot['start_time'] as String? ?? '';
              final end = slot['end_time'] as String? ?? '';
              final mode = slot['mode'] as String? ?? 'both';
              final slotId = slot['id'] as int? ?? 0;
              final modeColor = mode == 'online'
                  ? _kBlue
                  : mode == 'offline'
                      ? _kGreen
                      : _kPurple;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _kGreen.withValues(alpha: .15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dayName,
                          style: const TextStyle(
                            color: _kGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$start – $end',
                          style: const TextStyle(
                            color: _kInk,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: modeColor.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          mode,
                          style: TextStyle(
                            color: modeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed:
                            _loading ? null : () => _deleteSlot(slotId),
                        icon: const Icon(
                            Icons.delete_outline_rounded, size: 17),
                        color: const Color(0xFFC62828),
                        tooltip: 'Remove slot',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Verification Docs Section ────────────────────────────────────────────────

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditCounsellorProfileSheet extends StatefulWidget {
  const _EditCounsellorProfileSheet({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  State<_EditCounsellorProfileSheet> createState() =>
      _EditCounsellorProfileSheetState();
}

class _EditCounsellorProfileSheetState
    extends State<_EditCounsellorProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  late final TextEditingController _expertiseController;
  late final TextEditingController _dobController;
  late final TextEditingController _qualificationController;
  late final TextEditingController _experienceController;
  late final TextEditingController _organizationController;
  late final TextEditingController _languagesController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pinCodeController;
  late CounsellorCategory _category;
  String? _gender;
  String? _counsellingMode;
  Uint8List? _photoBytes;
  String? _photoPath;
  String? _photoName;
  bool _saving = false;

  static const _genderOptions = [
    'Male', 'Female', 'Other', 'Prefer not to say',
  ];
  static const _modeOptions = ['online', 'offline', 'both'];
  static const _modeLabels = {
    'online': 'Online',
    'offline': 'Offline',
    'both': 'Both',
  };

  @override
  void initState() {
    super.initState();
    final profile = widget.vm.profile;
    final ext = widget.vm.extendedProfile;
    _nameController = TextEditingController(text: profile.name);
    _phoneController =
        TextEditingController(text: widget.vm.user?.phone ?? '');
    _locationController =
        TextEditingController(text: widget.vm.user?.location ?? '');
    _bioController = TextEditingController(
      text: widget.vm.mentorProfile?.bio ?? profile.shortBio,
    );
    _expertiseController = TextEditingController(
      text: widget.vm.mentorProfile?.expertise ?? '',
    );
    _dobController = TextEditingController(
        text: ext?['date_of_birth'] as String? ?? '');
    _qualificationController = TextEditingController(
        text: ext?['qualification'] as String? ?? '');
    _experienceController = TextEditingController(
      text: ext?['years_of_experience'] != null
          ? '${ext!['years_of_experience']}'
          : '',
    );
    _organizationController = TextEditingController(
        text: ext?['organization'] as String? ?? '');
    _languagesController = TextEditingController(
        text: ext?['languages_known'] as String? ?? '');
    _cityController =
        TextEditingController(text: ext?['city'] as String? ?? '');
    _stateController =
        TextEditingController(text: ext?['state'] as String? ?? '');
    _pinCodeController =
        TextEditingController(text: ext?['pin_code'] as String? ?? '');
    _category = profile.category;
    _gender = ext?['gender'] as String?;
    _counsellingMode =
        ext?['counselling_mode'] as String? ?? 'both';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _expertiseController.dispose();
    _dobController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _organizationController.dispose();
    _languagesController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    setState(() {
      _photoBytes = file.bytes;
      _photoPath = file.path;
      _photoName = file.name;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Photo selected — tap Save to apply'),
        ]),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  ImageProvider<Object>? get _photoProvider {
    if (_photoBytes != null) return MemoryImage(_photoBytes!);
    if (!kIsWeb && _photoPath != null) return FileImage(File(_photoPath!));
    final existing = widget.vm.profile.photoUrl;
    if (existing != null && existing.isNotEmpty) {
      return NetworkImage(ApiClient.resolveUrl(existing));
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await widget.vm.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      bio: _bioController.text.trim(),
      expertise: _expertiseController.text.trim(),
      category: _category,
      photoBytes: _photoBytes?.toList(),
      photoPath: kIsWeb ? null : _photoPath,
      photoFileName: _photoName,
    );
    if (ok) {
      final extData = <String, dynamic>{
        if (_gender != null) 'gender': _gender,
        if (_dobController.text.trim().isNotEmpty)
          'date_of_birth': _dobController.text.trim(),
        if (_qualificationController.text.trim().isNotEmpty)
          'qualification': _qualificationController.text.trim(),
        if (_experienceController.text.trim().isNotEmpty)
          'years_of_experience':
              int.tryParse(_experienceController.text.trim()),
        if (_organizationController.text.trim().isNotEmpty)
          'organization': _organizationController.text.trim(),
        if (_counsellingMode != null) 'counselling_mode': _counsellingMode,
        if (_languagesController.text.trim().isNotEmpty)
          'languages_known': _languagesController.text.trim(),
        if (_cityController.text.trim().isNotEmpty)
          'city': _cityController.text.trim(),
        if (_stateController.text.trim().isNotEmpty)
          'state': _stateController.text.trim(),
        if (_pinCodeController.text.trim().isNotEmpty)
          'pin_code': _pinCodeController.text.trim(),
      };
      if (extData.isNotEmpty) {
        await widget.vm.updateExtendedProfile(extData);
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Profile updated!',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.vm.profileError ?? 'Could not update profile.'),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _photoProvider;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.93,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle + header (sticky)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6DCEA),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: _kBlue, size: 17),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: _kInk,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Public fields visible to schools. Phone & location are private.',
                              style: TextStyle(
                                  color: _kMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: _kMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  children: [
                    // Photo
                    Center(
                      child: GestureDetector(
                        onTap: _saving ? null : _pickPhoto,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: _kBlue.withValues(alpha: .1),
                              backgroundImage: provider,
                              child: provider == null
                                  ? Text(
                                      widget.vm.profile.initialsAvatar,
                                      style: const TextStyle(
                                        color: _kBlue,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : null,
                            ),
                            const Positioned(
                              right: -2,
                              bottom: 2,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: _kBlue,
                                child: Icon(
                                  Icons.photo_camera_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('Basic Information'),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _nameController,
                      label: 'Full name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CounsellorCategory>(
                      initialValue: _category,
                      decoration: _inputDecoration(
                          'Category', Icons.category_outlined),
                      isExpanded: true,
                      items: CounsellorCategory.values
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) {
                              if (v != null) setState(() => _category = v);
                            },
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _phoneController,
                      label: 'Private phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _locationController,
                      label: 'Private location',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('Professional Details'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration:
                          _inputDecoration('Gender', Icons.person_outline_rounded),
                      isExpanded: true,
                      hint: const Text('Select gender'),
                      items: _genderOptions
                          .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _dobController,
                      label: 'Date of birth (yyyy-mm-dd)',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _experienceController,
                      label: 'Years of experience',
                      icon: Icons.timeline_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _organizationController,
                      label: 'Organization',
                      icon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _counsellingMode,
                      decoration: _inputDecoration(
                          'Counselling mode', Icons.swap_horiz_rounded),
                      isExpanded: true,
                      items: _modeOptions
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(_modeLabels[m] ?? m),
                              ))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _counsellingMode = v),
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _languagesController,
                      label: 'Languages (comma separated)',
                      icon: Icons.language_rounded,
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('Public Bio & Expertise'),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _bioController,
                      label: 'Public bio',
                      icon: Icons.info_outline_rounded,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _expertiseController,
                      label: 'Expertise areas (comma separated)',
                      icon: Icons.star_outline_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('Qualifications & Location'),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _qualificationController,
                      label: 'Qualification',
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.map_outlined,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      controller: _pinCodeController,
                      label: 'Pin code',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            // Sticky save bar
            Container(
              padding: EdgeInsets.fromLTRB(
                20, 12, 20,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kMuted,
                        side: BorderSide(
                            color: _kMuted.withValues(alpha: .3)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kBlue,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: _kMuted,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
      ),
    );
  }
}

// ─── Change Password Sheet ────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AuthRepository.changePassword(
        currentPassword: _currentCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not change password. Check your current password.'),
          backgroundColor: Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFD6DCEA),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Password',
                  style: TextStyle(
                      color: _kInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: _obscureCurrent,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  decoration:
                      _inputDecoration('Current password', Icons.lock_outline_rounded)
                          .copyWith(
                    suffixIcon: ExcludeFocus(
                      child: IconButton(
                        icon: Icon(_obscureCurrent
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded),
                        onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  decoration:
                      _inputDecoration('New password', Icons.lock_rounded)
                          .copyWith(
                    suffixIcon: ExcludeFocus(
                      child: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: _inputDecoration(
                          'Confirm new password', Icons.lock_rounded)
                      .copyWith(
                    suffixIcon: ExcludeFocus(
                      child: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _newCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kBlue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.3, color: Colors.white))
                      : const Text('Change Password',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.isLast = false,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isLast;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction:
            (maxLines == 1 && !isLast) ? TextInputAction.next : null,
        onEditingComplete: (maxLines == 1 && !isLast)
            ? () => FocusScope.of(context).nextFocus()
            : null,
        decoration: _inputDecoration(label, icon),
      );
}

InputDecoration _inputDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4A587C), size: 18),
      filled: true,
      fillColor: _kBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
