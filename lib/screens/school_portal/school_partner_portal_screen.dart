import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_session_models.dart';
import '../../viewmodels/counsellor_viewmodel.dart';
import 'counsellor_directory_screen.dart';
import 'school_request_detail_screen.dart';

class SchoolPartnerPortalScreen extends StatefulWidget {
  const SchoolPartnerPortalScreen({super.key});

  @override
  State<SchoolPartnerPortalScreen> createState() =>
      _SchoolPartnerPortalScreenState();
}

class _SchoolPartnerPortalScreenState extends State<SchoolPartnerPortalScreen> {
  final _vm = CounsellorViewModel.shared;

  @override
  void initState() {
    super.initState();
    _vm.load();
    _vm.loadSchoolRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('School Partner Portal'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _hero(context),
            const SizedBox(height: 18),
            const Text(
              'School Services',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _serviceCard(
              context,
              icon: Icons.verified_user_rounded,
              title: 'Verified Counsellor Panel',
              subtitle:
                  'Review qualifications, service background, recognition and availability before requesting.',
              color: const Color(0xFF1565C0),
              onTap: () => _openDirectory(context),
            ),
            const SizedBox(height: 12),
            _serviceCard(
              context,
              icon: Icons.calendar_month_rounded,
              title: 'Book Counsellor',
              subtitle:
                  'Filter trusted experts and submit a school counselling or awareness-camp request.',
              color: const Color(0xFF2E7D32),
              onTap: () => _openDirectory(context),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your Requests',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${_vm.schoolRequests.length}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_vm.schoolRequests.isEmpty)
              _emptyRequests(context)
            else
              for (final request in _vm.schoolRequests.take(5)) ...[
                _requestCard(request),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 12),
            _assignmentNotice(),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0D2B5E), Color(0xFF1565C0)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF81C784), size: 20),
            SizedBox(width: 7),
            Text(
              'VERIFIED BY PUNJABI WELFARE TRUST',
              style: TextStyle(
                color: Color(0xFFB3E5FC),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Trusted guidance for\nevery student.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${_vm.allCounsellors.length} verified counsellors • Privacy-safe profiles',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => _openDirectory(context),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0D2B5E),
          ),
          icon: const Icon(Icons.search_rounded),
          label: const Text(
            'Explore Counsellors',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget _serviceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .16)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.35,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _requestCard(SchoolBookingRequest request) => GestureDetector(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SchoolRequestDetailScreen(request: request, vm: _vm),
      ),
    ),
    child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: request.status.color.withValues(alpha: .2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: request.status.color.withValues(alpha: .1),
          child: Icon(Icons.school_rounded, color: request.status.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.topic,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                request.counsellorName,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: request.status.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status.label,
                  style: TextStyle(
                    color: request.status.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

  Widget _emptyRequests(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.event_available_rounded,
          color: Color(0xFF1565C0),
          size: 34,
        ),
        const SizedBox(height: 8),
        const Text(
          'No counselling requests yet',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _openDirectory(context),
          child: const Text('Book a counsellor'),
        ),
      ],
    ),
  );

  Widget _assignmentNotice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF9A825).withValues(alpha: .25)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'You may request a specific counsellor. Final assignment is confirmed by the Event Manager/Admin based on verified availability.',
            style: TextStyle(
              color: Color(0xFF795548),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  void _openDirectory(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CounsellorDirectoryScreen(viewModel: _vm),
    ),
  );
}
