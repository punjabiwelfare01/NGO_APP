import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../repositories/api_client.dart';
import '../../repositories/auth_repository.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';
import '../../widgets/app_card.dart';

class CounsellorProfileView extends StatelessWidget {
  const CounsellorProfileView({required this.vm, super.key});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = vm.profile;
    return CustomScrollView(
      slivers: [
        _HeroAppBar(profile: p, onEdit: () => _openEditProfile(context)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _VerifiedBadge(profile: p),
              const SizedBox(height: 14),
              _PrivateAccountCard(vm: vm),
              const SizedBox(height: 16),
              _StatsRow(profile: p, vm: vm),
              const SizedBox(height: 14),
              _AvailabilityManagementSection(vm: vm),
              const SizedBox(height: 18),
              _Section(
                icon: Icons.info_outline_rounded,
                title: 'About',
                child: Text(
                  p.shortBio,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                icon: Icons.badge_rounded,
                title: 'Designation & Background',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Designation', p.designation),
                    _row('Category', p.category.label),
                    _row('Background', p.serviceBackground),
                    if (p.showRetiredStatus && p.publicStatusLabel.isNotEmpty)
                      _row('Service Status', p.publicStatusLabel),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                icon: Icons.workspace_premium_rounded,
                title: 'Qualifications & Certifications',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: p.qualifications
                      .map(
                        (q) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                                color: Color(0xFF2E7D32),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                icon: Icons.star_rounded,
                title: 'Areas of Expertise',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: p.expertiseAreas
                      .map(
                        (e) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: p.category.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: p.category.color.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            e,
                            style: TextStyle(
                              color: p.category.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                icon: Icons.calendar_month_rounded,
                title: 'Session Details',
                child: Column(
                  children: [
                    _row('Mode', p.sessionMode.label),
                    _row('Languages', p.languages.join(', ')),
                    _row('Experience', '${p.yearsOfExperience} years'),
                    for (final slot in p.availableSlots)
                      _row('Available', slot),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (p.recognitionProof.isNotEmpty)
                _Section(
                  icon: Icons.emoji_events_rounded,
                  title: 'Recognition & Appreciation',
                  child: Column(
                    children: p.recognitionProof
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.military_tech_rounded,
                                  size: 15,
                                  color: Color(0xFFF57F17),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 14),
              _VerificationDocsSection(vm: vm),
              const SizedBox(height: 14),
              _PrivacySection(),
              const SizedBox(height: 14),
              _PublicPreviewSection(profile: p),
              const SizedBox(height: 14),
              _AccountSettingsSection(vm: vm),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCounsellorProfileSheet(vm: vm),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Hero App Bar ─────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.profile, required this.onEdit});
  final CounsellorProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: p.category.color,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0A1F44), p.category.color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2.5,
                              ),
                              image: p.photoUrl == null
                                  ? null
                                  : DecorationImage(
                                      image: NetworkImage(
                                        ApiClient.resolveUrl(p.photoUrl!),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            child: p.photoUrl == null
                                ? Center(
                                    child: Text(
                                      p.initialsAvatar,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: -3,
                            bottom: -3,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: onEdit,
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.photo_camera_rounded,
                                    size: 15,
                                    color: Color(0xFF126BFF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.designation,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Verified badge
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF81C784),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Text(
                                    'Verified NGO Counsellor',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF81C784),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: p.category.color.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.category.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: onEdit,
                        tooltip: 'Edit profile',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 19),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

// ─── Verified Badge ───────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.profile});
  final CounsellorProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF2E7D32),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verified by Punjabi Welfare Trust',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NGO ID: ${p.ngoVerificationId}',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: p.isActive
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                  : AppColors.muted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.isActive ? 'Public' : 'Hidden',
              style: TextStyle(
                color: p.isActive ? const Color(0xFF2E7D32) : AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile, required this.vm});
  final CounsellorProfile profile;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final avgRating = vm.stats.avgRating;
    return Row(
      children: [
        _stat(
          '${p.yearsOfExperience}',
          'Yrs Experience',
          const Color(0xFF1565C0),
        ),
        _stat(
          '${p.schoolSessionsCompleted}',
          'School Sessions',
          const Color(0xFF2E7D32),
        ),
        _stat('${p.studentsGuided}+', 'Students', const Color(0xFF6A1B9A)),
        if (avgRating > 0)
          _stat(
            avgRating.toStringAsFixed(1),
            'Rating',
            const Color(0xFFF57F17),
          ),
      ],
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Section ──────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Privacy Section ──────────────────────────────────────────────────────────

class _PrivacySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF57F17).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFF57F17),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Privacy is Protected',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'The following information is NEVER shown publicly:',
            style: TextStyle(
              color: Color(0xFF795548),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in [
            'Army / Air Force / Government Service ID',
            'Aadhaar card number',
            'PAN card number',
            'Personal phone number',
            'Home address or personal location',
            'Verification documents (admin use only)',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 13,
                    color: Color(0xFFC62828),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF795548),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFFFCC80), height: 1),
          const SizedBox(height: 8),
          const Text(
            'Only your verified designation, NGO verification ID, qualifications, approved recognition, and public bio are visible to schools and students.',
            style: TextStyle(
              color: Color(0xFF795548),
              fontSize: 11,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Public Profile Preview ───────────────────────────────────────────────────

class _PublicPreviewSection extends StatelessWidget {
  const _PublicPreviewSection({required this.profile});
  final CounsellorProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.preview_rounded, size: 18, color: AppColors.ink),
            SizedBox(width: 8),
            Text(
              'Public Profile Preview',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'This is what schools and students see',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.category.color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: p.category.color.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category strip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: p.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p.category.icon, size: 13, color: p.category.color),
                    const SizedBox(width: 5),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: p.category.color.withValues(alpha: 0.15),
                    backgroundImage: p.photoUrl == null
                        ? null
                        : NetworkImage(ApiClient.resolveUrl(p.photoUrl!)),
                    child: p.photoUrl == null
                        ? Text(
                            p.initialsAvatar,
                            style: TextStyle(
                              color: p.category.color,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: Color(0xFF2E7D32),
                            ),
                          ],
                        ),
                        Text(
                          p.designation,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                p.shortBio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: p.expertiseAreas
                    .take(3)
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.category.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          e,
                          style: TextStyle(
                            color: p.category.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _previewStat(
                    Icons.school_rounded,
                    '${p.schoolSessionsCompleted}',
                    'Sessions',
                  ),
                  _previewStat(
                    Icons.people_rounded,
                    '${p.studentsGuided}+',
                    'Students',
                  ),
                  _previewStat(
                    Icons.timer_rounded,
                    '${p.yearsOfExperience} yrs',
                    'Experience',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Verified by PWT · ${p.ngoVerificationId}',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewStat(IconData icon, String value, String label) => Expanded(
    child: Row(
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PrivateAccountCard extends StatelessWidget {
  const _PrivateAccountCard({required this.vm});

  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final phone = vm.user?.phone?.trim();
    final location = vm.user?.location?.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF126BFF).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_person_rounded, color: Color(0xFF126BFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Private account details',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                        if (phone?.isNotEmpty == true) phone!,
                        if (location?.isNotEmpty == true) location!,
                      ].isEmpty
                      ? 'Add your phone and location'
                      : [
                          if (phone?.isNotEmpty == true) phone!,
                          if (location?.isNotEmpty == true) location!,
                        ].join(' • '),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Visible only to you and authorised NGO staff.',
                  style: TextStyle(color: Color(0xFF126BFF), fontSize: 10.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _EditCounsellorProfileSheet(vm: vm),
            ),
            tooltip: 'Edit details',
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF126BFF)),
          ),
        ],
      ),
    );
  }
}

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

  static const _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const _modeOptions = ['online', 'offline', 'both'];
  static const _modeLabels = {'online': 'Online', 'offline': 'Offline', 'both': 'Both'};

  @override
  void initState() {
    super.initState();
    final profile = widget.vm.profile;
    final ext = widget.vm.extendedProfile;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: widget.vm.user?.phone ?? '');
    _locationController = TextEditingController(
      text: widget.vm.user?.location ?? '',
    );
    _bioController = TextEditingController(
      text: widget.vm.mentorProfile?.bio ?? profile.shortBio,
    );
    _expertiseController = TextEditingController(
      text: widget.vm.mentorProfile?.expertise ?? '',
    );
    _dobController = TextEditingController(text: ext?['date_of_birth'] as String? ?? '');
    _qualificationController = TextEditingController(text: ext?['qualification'] as String? ?? '');
    _experienceController = TextEditingController(
      text: ext?['years_of_experience'] != null ? '${ext!['years_of_experience']}' : '',
    );
    _organizationController = TextEditingController(text: ext?['organization'] as String? ?? '');
    _languagesController = TextEditingController(text: ext?['languages_known'] as String? ?? '');
    _cityController = TextEditingController(text: ext?['city'] as String? ?? '');
    _stateController = TextEditingController(text: ext?['state'] as String? ?? '');
    _pinCodeController = TextEditingController(text: ext?['pin_code'] as String? ?? '');
    _category = profile.category;
    _gender = ext?['gender'] as String?;
    _counsellingMode = ext?['counselling_mode'] as String? ?? 'both';
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
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Photo selected — tap Save to apply'),
          ],
        ),
        backgroundColor: Color(0xFF2E7D32),
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
      // Also save extended profile fields
      final extData = <String, dynamic>{
        if (_gender != null) 'gender': _gender,
        if (_dobController.text.trim().isNotEmpty)
          'date_of_birth': _dobController.text.trim(),
        if (_qualificationController.text.trim().isNotEmpty)
          'qualification': _qualificationController.text.trim(),
        if (_experienceController.text.trim().isNotEmpty)
          'years_of_experience': int.tryParse(_experienceController.text.trim()),
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
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Profile updated successfully!',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.vm.profileError ?? 'Could not update profile.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _photoProvider;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
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
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DCEA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Counsellor Profile',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Public bio fields are visible to schools. Phone and location remain private.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Center(
                  child: InkWell(
                    onTap: _saving ? null : _pickPhoto,
                    customBorder: const CircleBorder(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFFEAF4FF),
                          backgroundImage: provider,
                          child: provider == null
                              ? Text(
                                  widget.vm.profile.initialsAvatar,
                                  style: const TextStyle(
                                    color: Color(0xFF126BFF),
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                        ),
                        const Positioned(
                          right: -2,
                          bottom: 2,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Color(0xFF126BFF),
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
                const SizedBox(height: 18),
                _EditField(
                  controller: _nameController,
                  label: 'Full name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CounsellorCategory>(
                  initialValue: _category,
                  decoration: _inputDecoration(
                    'Counsellor category',
                    Icons.category_outlined,
                  ),
                  isExpanded: true,
                  items: CounsellorCategory.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _category = value);
                        },
                ),
                const SizedBox(height: 12),
                _EditField(
                  controller: _bioController,
                  label: 'Public bio',
                  icon: Icons.info_outline_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _EditField(
                  controller: _expertiseController,
                  label: 'Expertise (comma separated)',
                  icon: Icons.star_outline_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _EditField(
                  controller: _phoneController,
                  label: 'Private phone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _EditField(
                  controller: _locationController,
                  label: 'Private location',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Professional Details',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: _inputDecoration('Gender', Icons.person_outline_rounded),
                  isExpanded: true,
                  hint: const Text('Select gender'),
                  items: _genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
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
                  controller: _qualificationController,
                  label: 'Qualification',
                  icon: Icons.school_outlined,
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
                    'Counselling mode',
                    Icons.swap_horiz_rounded,
                  ),
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
                  label: 'Languages known (comma separated)',
                  icon: Icons.language_rounded,
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Location Details',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
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
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF126BFF),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: _inputDecoration(label, icon),
  );
}

InputDecoration _inputDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4A587C)),
      filled: true,
      fillColor: const Color(0xFFF7FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF126BFF), width: 1.5),
      ),
    );

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
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
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
          title: const Text('Add Weekly Slot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: dayOfWeek,
                  decoration: _inputDecoration('Day', Icons.calendar_today_rounded),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(value: i, child: Text(_dayNames[i])),
                  ),
                  onChanged: (v) => setS(() => dayOfWeek = v ?? 0),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: startTime,
                  decoration: _inputDecoration('Start time (HH:MM)', Icons.access_time_rounded),
                  onChanged: (v) => startTime = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: endTime,
                  decoration: _inputDecoration('End time (HH:MM)', Icons.access_time_filled_rounded),
                  onChanged: (v) => endTime = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  decoration: _inputDecoration('Mode', Icons.swap_horiz_rounded),
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Online')),
                    DropdownMenuItem(value: 'offline', child: Text('Offline')),
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
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_repeat_rounded, size: 18, color: AppColors.ink),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Weekly Availability',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Refresh',
              ),
              TextButton.icon(
                onPressed: _loading ? null : _addSlot,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Slot'),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (slots == null || slots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No weekly availability set. Tap "Add Slot" to add one.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            )
          else
            ...slots.map((slot) {
              final day = (slot['day_of_week'] as int?) ?? 0;
              final dayName = day >= 0 && day < 7 ? _dayNames[day] : 'Day $day';
              final start = slot['start_time'] as String? ?? '';
              final end = slot['end_time'] as String? ?? '';
              final mode = slot['mode'] as String? ?? 'both';
              final slotId = slot['id'] as int? ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dayName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$start – $end',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mode,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : () => _deleteSlot(slotId),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: AppColors.softRed,
                      tooltip: 'Remove slot',
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Verification Docs Section ────────────────────────────────────────────────

class _VerificationDocsSection extends StatefulWidget {
  const _VerificationDocsSection({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  State<_VerificationDocsSection> createState() => _VerificationDocsSectionState();
}

class _VerificationDocsSectionState extends State<_VerificationDocsSection> {
  bool _uploading = false;


  Color _statusColor(String? status) {
    switch (status) {
      case 'verified': return const Color(0xFF2E7D32);
      case 'rejected': return AppColors.softRed;
      case 'correction_required': return const Color(0xFFF57F17);
      default: return AppColors.muted;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'verified': return 'Verified';
      case 'rejected': return 'Rejected';
      case 'correction_required': return 'Correction Required';
      default: return 'Pending';
    }
  }

  Future<void> _uploadDoc(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    if (file.bytes == null && file.path == null) return;

    setState(() => _uploading = true);
    try {
      if (file.bytes != null) {
        await ApiClient.postMultipart(
          '/counsellor/upload-verification-doc',
          fields: {'doc_type': docType},
          fileBytes: file.bytes!,
          fileName: file.name,
          fileField: 'file',
        );
      } else {
        await ApiClient.postMultipartFromPath(
          '/counsellor/upload-verification-doc',
          fields: {'doc_type': docType},
          filePath: file.path!,
          fileName: file.name,
          fileField: 'file',
        );
      }
      await widget.vm.fetchExtendedProfile();
      final label = docType == 'id_proof' ? 'ID proof' : 'Certificate';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label uploaded.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed. Please try again.'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = widget.vm.extendedProfile;
    final status = ext?['verification_status'] as String? ?? 'pending';
    final idProofDocUrl = ext?['id_proof_doc_url'] as String?;
    final certUrl = ext?['professional_cert_url'] as String?;
    final adminRemark = ext?['admin_remark'] as String?;
    final idProofType = ext?['id_proof_type'] as String?;
    final idProofNumber = ext?['id_proof_number'] as String?;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.ink),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Verification Documents',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ID Proof type & number (read-only display from extended profile)
          if (idProofType != null && idProofType.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Text(
                    'ID Type: ',
                    style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      idProofType,
                      style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          if (idProofNumber != null && idProofNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Text(
                    'ID Number: ',
                    style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      idProofNumber,
                      style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

          // ID Proof upload
          _DocRow(
            label: 'ID Proof Document',
            icon: Icons.badge_rounded,
            hasDoc: idProofDocUrl != null && idProofDocUrl.isNotEmpty,
            uploading: _uploading,
            onUpload: () => _uploadDoc('id_proof'),
          ),
          const SizedBox(height: 8),

          // Professional cert upload
          _DocRow(
            label: 'Professional Certificate',
            icon: Icons.workspace_premium_rounded,
            hasDoc: certUrl != null && certUrl.isNotEmpty,
            uploading: _uploading,
            onUpload: () => _uploadDoc('professional_cert'),
          ),

          if (adminRemark != null && adminRemark.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF57F17).withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Admin remark: $adminRemark',
                      style: const TextStyle(color: Color(0xFF795548), fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Documents submitted for admin verification only. Not shown publicly.',
            style: TextStyle(color: AppColors.muted, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.label,
    required this.icon,
    required this.hasDoc,
    required this.uploading,
    required this.onUpload,
  });

  final String label;
  final IconData icon;
  final bool hasDoc;
  final bool uploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        if (hasDoc)
          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
        const SizedBox(width: 6),
        uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_rounded, size: 14),
                label: Text(hasDoc ? 'Replace' : 'Upload'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
      ],
    );
  }
}

// ─── Account Settings Section ─────────────────────────────────────────────────

class _AccountSettingsSection extends StatelessWidget {
  const _AccountSettingsSection({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E9F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(Icons.settings_rounded, size: 18, color: AppColors.ink),
                SizedBox(width: 8),
                Text(
                  'Account Settings',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            title: const Text(
              'Change Password',
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _ChangePasswordSheet(),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.softRed),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.softRed, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.softRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
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
        const SnackBar(content: Text('Password changed successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not change password. Check your current password.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
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
                    width: 42, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DCEA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Password',
                  style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: _obscureCurrent,
                  decoration: _inputDecoration('Current password', Icons.lock_outline_rounded).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: _obscureNew,
                  decoration: _inputDecoration('New password', Icons.lock_rounded).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
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
                  decoration: _inputDecoration('Confirm new password', Icons.lock_rounded).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.3, color: Colors.white),
                        )
                      : const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
