import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../repositories/api_client.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';
import '../../widgets/app_card.dart';

class CounsellorProfileView extends StatelessWidget {
  const CounsellorProfileView({required this.vm, super.key});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
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
              _PrivacySection(),
              const SizedBox(height: 14),
              _PublicPreviewSection(profile: p),
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
  late CounsellorCategory _category;
  Uint8List? _photoBytes;
  String? _photoPath;
  String? _photoName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.vm.profile;
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
    _category = profile.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _expertiseController.dispose();
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
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Counsellor profile updated.')),
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
