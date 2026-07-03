import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../repositories/api_client.dart';
import '../../viewmodels/counsellor_viewmodel.dart';
import '../../widgets/app_card.dart';

class CounsellorProfileScreen extends StatelessWidget {
  const CounsellorProfileScreen({
    required this.counsellor,
    required this.vm,
    super.key,
  });
  final CounsellorProfile counsellor;
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = counsellor;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _HeroAppBar(counsellor: c),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Verified trust badge
                _VerificationBadge(counsellor: c),
                const SizedBox(height: 16),
                // Stats row
                _StatsRow(counsellor: c),
                const SizedBox(height: 16),
                // Short bio
                _Section(
                  title: 'About',
                  icon: Icons.person_rounded,
                  child: Text(
                    c.shortBio.isNotEmpty ? c.shortBio : 'No bio available.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Contact Information
                if (c.phone != null || c.location != null) ...[
                  _Section(
                    title: 'Contact Information',
                    icon: Icons.contact_phone_rounded,
                    child: Column(
                      children: [
                        if (c.phone != null && c.phone!.isNotEmpty)
                          _DetailRow(label: 'Phone', value: c.phone!),
                        if (c.location != null && c.location!.isNotEmpty)
                          _DetailRow(label: 'Location', value: c.location!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                // Designation & background
                _Section(
                  title: 'Designation & Background',
                  icon: Icons.badge_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(label: 'Designation', value: c.designation),
                      if (c.yearsOfExperience > 0)
                        _DetailRow(
                          label: 'Experience',
                          value: '${c.yearsOfExperience} year${c.yearsOfExperience == 1 ? '' : 's'}',
                        ),
                      if (c.serviceBackground.isNotEmpty)
                        _DetailRow(
                          label: 'Background',
                          value: c.serviceBackground,
                        ),
                      if (c.showRetiredStatus)
                        _DetailRow(
                          label: 'Service Status',
                          value: c.publicStatusLabel,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Expertise areas
                if (c.expertiseAreas.isNotEmpty) ...[
                  _Section(
                    title: 'Areas of Expertise',
                    icon: Icons.star_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: c.expertiseAreas
                          .map(
                            (e) => _ExpertiseTag(
                              label: e,
                              color: c.category.color,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                // Session topics
                if (c.sessionTopics.isNotEmpty) ...[
                  _Section(
                    title: 'Session Topics They Can Conduct',
                    icon: Icons.topic_rounded,
                    child: Column(
                      children: c.sessionTopics
                          .asMap()
                          .entries
                          .map(
                            (entry) => _TopicRow(
                              index: entry.key + 1,
                              topic: entry.value,
                              color: c.category.color,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                // Qualifications
                if (c.qualifications.isNotEmpty) ...[
                  _Section(
                    title: 'Qualifications & Certifications',
                    icon: Icons.workspace_premium_rounded,
                    child: Column(
                      children: c.qualifications
                          .map(
                            (q) => _QualificationRow(
                              text: q,
                              color: c.category.color,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                // Session details
                _Section(
                  title: 'Session Details',
                  icon: Icons.calendar_month_rounded,
                  child: Column(
                    children: [
                      _SessionDetailRow(
                        icon: c.sessionMode.icon,
                        label: 'Mode',
                        value: c.sessionMode.label,
                        color: c.sessionMode.color,
                      ),
                      if (c.languages.isNotEmpty)
                        _SessionDetailRow(
                          icon: Icons.language_rounded,
                          label: 'Languages',
                          value: c.languages.join(', '),
                        ),
                      for (final slot in c.availableSlots)
                        _SessionDetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Schedule',
                          value: slot,
                          color: const Color(0xFF2E7D32),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Recognition and appreciation
                if (c.recognitionProof.isNotEmpty ||
                    c.appreciationDocuments.isNotEmpty) ...[
                  _Section(
                    title: 'Recognition & Appreciation',
                    icon: Icons.emoji_events_rounded,
                    child: Column(
                      children: [
                        ...c.recognitionProof.map(
                          (r) => _RecognitionRow(
                            text: r,
                            color: const Color(0xFFF57F17),
                          ),
                        ),
                        if (c.appreciationDocuments.isNotEmpty) ...[
                          if (c.recognitionProof.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                          ],
                          ...c.appreciationDocuments.map(
                            (d) => _RecognitionRow(
                              text: d,
                              color: c.category.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                // NGO Privacy section
                _PrivacySection(counsellor: c),
                const SizedBox(height: 24),
                // CTAs
                _CTASection(counsellor: c, vm: vm),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero App Bar ─────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.counsellor});
  final CounsellorProfile counsellor;

  @override
  Widget build(BuildContext context) {
    final c = counsellor;
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: c.category.color,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sharing counsellor profile...'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                c.category.color,
                c.category.color.withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Profile photo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                        child: c.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  ApiClient.resolveUrl(c.photoUrl!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  c.initialsAvatar,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Verified badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Verified by Punjabi Welfare Trust',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  c.category.icon,
                                  color: Colors.white70,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    c.category.label,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (c.showRetiredStatus) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.publicStatusLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Verification Badge ───────────────────────────────────────────────────────

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.counsellor});
  final CounsellorProfile counsellor;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NGO ID: ${counsellor.ngoVerificationId}',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (counsellor.availableThisWeek)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 7),
                  SizedBox(height: 2),
                  Text(
                    'Available',
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
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.counsellor});
  final CounsellorProfile counsellor;

  @override
  Widget build(BuildContext context) {
    final c = counsellor;
    return Row(
      children: [
        _StatTile(
          value: '${c.yearsOfExperience}+',
          label: 'Years Exp.',
          icon: Icons.schedule_rounded,
          color: c.category.color,
        ),
        const SizedBox(width: 10),
        _StatTile(
          value: '${c.schoolSessionsCompleted}',
          label: 'Sessions',
          icon: Icons.school_rounded,
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 10),
        _StatTile(
          value: c.studentsGuided >= 1000
              ? '${(c.studentsGuided / 1000).toStringAsFixed(1)}K'
              : '${c.studentsGuided}',
          label: 'Students',
          icon: Icons.people_rounded,
          color: const Color(0xFF2E7D32),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.ink, size: 17),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Detail rows ──────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.index,
    required this.topic,
    required this.color,
  });
  final int index;
  final String topic;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              topic,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualificationRow extends StatelessWidget {
  const _QualificationRow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionDetailRow extends StatelessWidget {
  const _SessionDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.ink,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecognitionRow extends StatelessWidget {
  const _RecognitionRow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emoji_events_rounded, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpertiseTag extends StatelessWidget {
  const _ExpertiseTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Privacy Section ──────────────────────────────────────────────────────────

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.counsellor});
  final CounsellorProfile counsellor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF57F17).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFFE65100), size: 18),
              SizedBox(width: 8),
              Text(
                'Privacy & Verification Policy',
                style: TextStyle(
                  color: Color(0xFFBF360C),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            'Government IDs, Army/Air Force IDs, Aadhaar, PAN, and personal phone numbers are never displayed publicly.',
            'Only an internal NGO Verification ID (${counsellor.ngoVerificationId}) is shown.',
            '"${counsellor.showRetiredStatus ? counsellor.publicStatusLabel : "Service status"}" is shown only after document verification and counsellor consent.',
            'Verification documents are reviewed by NGO Admin only and are never shared publicly.',
            'Appreciation letters and recognition shown here are approved public documents.',
          ].map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
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

// ─── CTA Section ─────────────────────────────────────────────────────────────

class _CTASection extends StatelessWidget {
  const _CTASection({required this.counsellor, required this.vm});
  final CounsellorProfile counsellor;
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _showBookingForm(context),
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text(
              'Book Counselling Session',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: counsellor.category.color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAwarenessCampForm(context),
            icon: const Icon(Icons.campaign_rounded, size: 18),
            label: const Text(
              'Request Awareness Camp',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: counsellor.category.color,
              side: BorderSide(color: counsellor.category.color, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBookingForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _BookingForm(counsellor: counsellor, vm: vm, isAwarenessCamp: false),
    );
  }

  void _showAwarenessCampForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _BookingForm(counsellor: counsellor, vm: vm, isAwarenessCamp: true),
    );
  }
}

// ─── Booking Form ─────────────────────────────────────────────────────────────

class _BookingForm extends StatefulWidget {
  const _BookingForm({
    required this.counsellor,
    required this.vm,
    required this.isAwarenessCamp,
  });
  final CounsellorProfile counsellor;
  final CounsellorViewModel vm;
  final bool isAwarenessCamp;

  @override
  State<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<_BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _schoolCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _countCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  SessionMode _mode = SessionMode.offline;
  String _gradeLevel = 'Class 9–12';
  bool _submitting = false;

  static const _gradeLevels = [
    'Class 6–8',
    'Class 9–10',
    'Class 11–12',
    'Class 9–12',
    'All Classes',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select mode based on counsellor availability
    if (widget.counsellor.sessionMode != SessionMode.both) {
      _mode = widget.counsellor.sessionMode;
    }
  }

  @override
  void dispose() {
    _schoolCtrl.dispose();
    _principalCtrl.dispose();
    _emailCtrl.dispose();
    _topicCtrl.dispose();
    _countCtrl.dispose();
    _requirementsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().add(const Duration(days: 3)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final request = CounsellingRequest(
      id: DateTime.now().millisecondsSinceEpoch,
      counsellorId: widget.counsellor.id,
      counsellorName: widget.counsellor.name,
      counsellorCategory: widget.counsellor.category,
      schoolName: _schoolCtrl.text.trim(),
      principalName: _principalCtrl.text.trim(),
      schoolEmail: _emailCtrl.text.trim(),
      topic: _topicCtrl.text.trim().isNotEmpty
          ? _topicCtrl.text.trim()
          : (widget.isAwarenessCamp ? 'Awareness Camp' : 'Counselling Session'),
      preferredDate: DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute,
      ),
      sessionMode: _mode,
      studentCount: int.tryParse(_countCtrl.text.trim()) ?? 0,
      gradeLevel: _gradeLevel,
      specialRequirements: _requirementsCtrl.text.trim(),
      status: RequestStatus.pending,
      requestedAt: DateTime.now(),
    );

    try {
      await widget.vm.submitRequest(request);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit request: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Request sent! Our Event Manager will review and confirm your session with ${widget.counsellor.name}.',
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.counsellor;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.90,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
            // Form header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.isAwarenessCamp
                          ? Icons.campaign_rounded
                          : Icons.calendar_month_rounded,
                      color: c.category.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isAwarenessCamp
                              ? 'Request Awareness Camp'
                              : 'Book Counselling Session',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'with ${c.name}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: ctrl,
                  padding: EdgeInsets.fromLTRB(18, 16, 18,
                      24 + MediaQuery.of(context).viewInsets.bottom),
                  children: [
                    // Counsellor summary tile
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.category.color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: c.category.color.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            c.category.icon,
                            color: c.category.color,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  c.designation,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF2E7D32),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fLabel('School Name *'),
                    _field(
                      _schoolCtrl,
                      'e.g. Govt Sr. Sec. School, Amritsar',
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _fLabel('Principal / Contact Name *'),
                    _field(_principalCtrl, 'Full name', required: true),
                    const SizedBox(height: 12),
                    _fLabel('School Email *'),
                    _field(
                      _emailCtrl,
                      'principal@school.edu',
                      required: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _fLabel('Session Topic *'),
                    _field(
                      _topicCtrl,
                      'e.g. Career Guidance, Mental Health Awareness…',
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _fLabel('Preferred Date / Time *'),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                border: Border.all(
                                  color: AppColors.muted.withValues(alpha: 0.25),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: c.category.color,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                border: Border.all(
                                  color: AppColors.muted.withValues(alpha: 0.25),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: c.category.color,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _time.format(context),
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _fLabel('Session Mode *'),
                    Wrap(
                      spacing: 8,
                      children: SessionMode.values
                          .where(
                            (m) =>
                                c.sessionMode == SessionMode.both ||
                                c.sessionMode == m,
                          )
                          .map(
                            (m) => ChoiceChip(
                              label: Text(
                                m.label,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: _mode == m,
                              onSelected: (_) => setState(() => _mode = m),
                              avatar: Icon(m.icon, size: 13),
                              selectedColor: m.color.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: _mode == m ? m.color : AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _fLabel('Grade Level *'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _gradeLevel,
                      items: _gradeLevels
                          .map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                g,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _gradeLevel = v!),
                      decoration: _dropdownDecoration(),
                    ),
                    const SizedBox(height: 12),
                    _fLabel('Approx. Number of Students *'),
                    _field(
                      _countCtrl,
                      'e.g. 150',
                      required: true,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _fLabel('Special Requirements (Optional)'),
                    _field(
                      _requirementsCtrl,
                      'e.g. Need projector, bring printed materials...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    // Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF1565C0),
                            size: 14,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your request will be reviewed by our Event Manager. Final confirmation will be sent after coordinating with the counsellor\'s availability.',
                              style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.category.color,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.isAwarenessCamp
                                    ? 'Submit Awareness Camp Request'
                                    : 'Submit Booking Request',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _fLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    textInputAction: maxLines <= 1 ? TextInputAction.next : null,
    onEditingComplete: maxLines <= 1
        ? () => FocusScope.of(context).nextFocus()
        : null,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.muted.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: widget.counsellor.category.color,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
        : null,
  );

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF8F9FA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.35)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.25)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
