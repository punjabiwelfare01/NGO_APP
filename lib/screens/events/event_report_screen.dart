import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../models/event_pipeline_models.dart';
import '../../viewmodels/event_pipeline_viewmodel.dart';
import '../../repositories/event_manager_repository.dart';
import '../../utils/file_download.dart';

class EventReportScreen extends StatelessWidget {
  const EventReportScreen({
    required this.report,
    required this.vm,
    required this.eventId,
    super.key,
  });

  final EventReport report;
  final EventPipelineViewModel vm;
  final int eventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _Header(report: report, vm: vm, eventId: eventId),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                children: [
                  _SummarySection(report: report),
                  const SizedBox(height: 16),
                  _ImpactSection(report: report),
                  const SizedBox(height: 16),
                  _TeamSection(report: report),
                  const SizedBox(height: 16),
                  _ActivitiesSection(report: report),
                  if (report.partnerDetails != null ||
                      report.counsellorDetails != null) ...[
                    const SizedBox(height: 16),
                    _PartnersSection(report: report),
                  ],
                  if (report.schoolFeedback != null) ...[
                    const SizedBox(height: 16),
                    _FeedbackSection(report: report),
                  ],
                  const SizedBox(height: 16),
                  _OutcomesSection(report: report),
                  const SizedBox(height: 20),
                  _ActionsSection(report: report, vm: vm, eventId: eventId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.report,
    required this.vm,
    required this.eventId,
  });
  final EventReport report;
  final EventPipelineViewModel vm;
  final int eventId;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 190,
      backgroundColor: const Color(0xFF0A1F44),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _share(context),
          icon: const Icon(Icons.share_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: () => _download(context),
          icon: const Icon(Icons.download_rounded, color: Colors.white),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F44), Color(0xFF1A3A6C)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 90, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: report.status.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: report.status.color.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      report.status.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: report.status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.summarize_rounded,
                    color: Colors.white60,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Event Report',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.eventName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      report.location,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(report.eventDate),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      final id = await EventManagerRepository.ensureReport(eventId);
      final url = await EventManagerRepository.shareReport(eventId, id);
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report link copied. Finalize the report to make the public link available.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not share report: $e')));
      }
    }
  }

  Future<void> _download(BuildContext context) async {
    try {
      final id = await EventManagerRepository.ensureReport(eventId);
      final ok = await downloadFile(
        EventManagerRepository.reportDownloadUrl(eventId, id),
        'event-$eventId-report.pdf',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Report download started.' : 'Could not open report PDF.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not download report: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Summary Section ──────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.report});
  final EventReport report;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.bar_chart_rounded,
            label: 'Impact Summary',
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  '${report.totalVolunteers}',
                  'Volunteers',
                  Icons.people_rounded,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _BigStat(
                  '${report.studentsReached}',
                  'People Reached',
                  Icons.volunteer_activism_rounded,
                  const Color(0xFF2E7D32),
                ),
              ),
              Expanded(
                child: _BigStat(
                  '${report.certificatesIssued}',
                  'Certificates',
                  Icons.workspace_premium_rounded,
                  const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${report.donationsCollected.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      'Total Donations Collected',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat(this.value, this.label, this.icon, this.color);
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Impact Section ───────────────────────────────────────────────────────────

class _ImpactSection extends StatelessWidget {
  const _ImpactSection({required this.report});
  final EventReport report;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.emoji_events_rounded,
            label: 'Outcomes & Impact',
            color: const Color(0xFF6A1B9A),
          ),
          const SizedBox(height: 12),
          Text(
            report.outcomes,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF17324D),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Team Section ─────────────────────────────────────────────────────────────

class _TeamSection extends StatelessWidget {
  const _TeamSection({required this.report});
  final EventReport report;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.people_rounded,
            label: 'Volunteer Team',
            color: AppColors.primary,
          ),
          const SizedBox(height: 4),
          Text(
            'Event Manager: ${report.eventManagerName}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: report.volunteerNames.map((name) {
              final parts = name.trim().split(' ');
              final initials = parts.length >= 2
                  ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                  : name.isNotEmpty
                  ? name[0].toUpperCase()
                  : '?';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF17324D),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Activities Section ───────────────────────────────────────────────────────

class _ActivitiesSection extends StatelessWidget {
  const _ActivitiesSection({required this.report});
  final EventReport report;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.assignment_rounded,
            label: 'Event Activities',
            color: const Color(0xFF00695C),
          ),
          const SizedBox(height: 10),
          ...report.activityTitles.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00695C),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF17324D),
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

// ─── Partners Section ─────────────────────────────────────────────────────────

class _PartnersSection extends StatelessWidget {
  const _PartnersSection({required this.report});
  final EventReport report;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.handshake_rounded,
            label: 'Partners & Counsellor',
            color: const Color(0xFFE65100),
          ),
          const SizedBox(height: 12),
          if (report.partnerDetails != null)
            _infoRow(
              Icons.school_rounded,
              'School Partner',
              report.partnerDetails!,
            ),
          if (report.counsellorDetails != null)
            _infoRow(
              Icons.support_agent_rounded,
              'Counsellor',
              report.counsellorDetails!,
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF17324D)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Feedback Section ─────────────────────────────────────────────────────────

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({required this.report});
  final EventReport report;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.rate_review_rounded,
            label: 'School Feedback',
            color: const Color(0xFFF57F17),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF57F17).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF57F17).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Color(0xFFF57F17),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.schoolFeedback!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF17324D),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
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

// ─── Outcomes Section ─────────────────────────────────────────────────────────

class _OutcomesSection extends StatelessWidget {
  const _OutcomesSection({required this.report});
  final EventReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1F44), Color(0xFF1A3A6C)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.military_tech_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Generated on',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Text(
                _formatDate(report.generatedAt),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pranam Welfare Trust',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          Text(
            'Official Event Report — ${report.eventName}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF70D98B), size: 14),
              SizedBox(width: 5),
              Text(
                'NGO Verified Report',
                style: TextStyle(
                  color: Color(0xFF70D98B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Actions Section ──────────────────────────────────────────────────────────

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.report,
    required this.vm,
    required this.eventId,
  });
  final EventReport report;
  final EventPipelineViewModel vm;
  final int eventId;

  @override
  Widget build(BuildContext context) {
    if (report.status == EventReportStatus.finalised) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2E7D32),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Report Finalised',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          final reportId = await EventManagerRepository.ensureReport(eventId);
          await EventManagerRepository.finalizeReport(eventId, reportId);
          vm.finaliseReport(eventId);
          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event report finalised!'),
              backgroundColor: Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
        label: const Text(
          'Finalise Report',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF17324D),
          ),
        ),
      ],
    );
  }
}
