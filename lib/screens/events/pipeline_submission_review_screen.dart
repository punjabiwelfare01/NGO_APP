import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_pipeline_models.dart';
import '../../viewmodels/event_pipeline_viewmodel.dart';

class PipelineSubmissionReviewScreen extends StatefulWidget {
  const PipelineSubmissionReviewScreen({
    required this.assignment,
    required this.event,
    required this.activity,
    required this.vm,
    super.key,
  });

  final PipelineAssignment assignment;
  final PipelineEvent event;
  final PipelineActivity activity;
  final EventPipelineViewModel vm;

  @override
  State<PipelineSubmissionReviewScreen> createState() => _PipelineSubmissionReviewScreenState();
}

class _PipelineSubmissionReviewScreenState extends State<PipelineSubmissionReviewScreen> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final submission = assignment.submission;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        title: const Text(
          'Review Submission',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
      body: submission == null
          ? Center(child: Text('No submission found', style: TextStyle(color: AppColors.muted)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                _StudentCard(assignment: assignment),
                const SizedBox(height: 16),
                _SubmissionCard(submission: submission),
                const SizedBox(height: 16),
                if (submission.donationProof != null) ...[
                  _DonationProofCard(proof: submission.donationProof!),
                  const SizedBox(height: 16),
                ],
                if (submission.logEntries.isNotEmpty) ...[
                  _LogEntriesCard(logs: submission.logEntries),
                  const SizedBox(height: 16),
                ],
                _ReviewNoteCard(controller: _noteCtrl, assignment: assignment),
                const SizedBox(height: 20),
                _ActionButtons(
                  assignment: assignment,
                  event: widget.event,
                  activity: widget.activity,
                  vm: widget.vm,
                  noteCtrl: _noteCtrl,
                ),
              ],
            ),
    );
  }
}

// ─── Student Card ─────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.assignment});
  final PipelineAssignment assignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              assignment.initials,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.studentName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF17324D)),
                ),
                Text(assignment.studentEmail, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    assignment.activityTitle,
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
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

// ─── Submission Card ──────────────────────────────────────────────────────────

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.submission});
  final PipelineWorkSubmission submission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.upload_file_rounded, color: Color(0xFF00695C), size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Work Submission', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF17324D))),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            submission.workTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF17324D)),
          ),
          const SizedBox(height: 6),
          Text(submission.description, style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetricPill(
                icon: Icons.schedule_rounded,
                label: '${submission.hoursWorked.toStringAsFixed(1)} hrs',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _MetricPill(
                icon: Icons.people_rounded,
                label: '${submission.peopleReached} reached',
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 8),
              _MetricPill(
                icon: Icons.calendar_today_rounded,
                label: _formatDate(submission.submittedAt),
                color: AppColors.muted,
              ),
            ],
          ),
          if (submission.remarks != null && submission.remarks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment_outlined, size: 14, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      submission.remarks!,
                      style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (submission.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Photos (${submission.photoUrls.length})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 6),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: submission.photoUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, i) => Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.image_rounded, color: AppColors.muted, size: 28),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Donation Proof Card ──────────────────────────────────────────────────────

class _DonationProofCard extends StatelessWidget {
  const _DonationProofCard({required this.proof});
  final PipelineDonationProof proof;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_rounded, color: Color(0xFF2E7D32), size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Donation Proof', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF17324D))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: proof.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(proof.status.label, style: TextStyle(fontSize: 10, color: proof.status.color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Amount', '₹${proof.amount.toStringAsFixed(2)}'),
          _row('Transaction ID', proof.transactionId),
          if (proof.donorName != null) _row('Donor', proof.donorName!),
          _row('Date', _formatDate(proof.donationDate)),
          if (proof.stipendAmount != null && proof.stipendAmount! > 0)
            _row('Stipend', '₹${proof.stipendAmount!.toStringAsFixed(0)}', color: const Color(0xFF6A1B9A)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.5, color: color ?? const Color(0xFF17324D), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Log Entries Card ─────────────────────────────────────────────────────────

class _LogEntriesCard extends StatelessWidget {
  const _LogEntriesCard({required this.logs});
  final List<PipelineDailyLog> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF6A1B9A)),
              const SizedBox(width: 8),
              Text('Daily Log Entries (${logs.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF17324D))),
            ],
          ),
          const SizedBox(height: 12),
          ...logs.map((log) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF17324D))),
                const SizedBox(height: 3),
                Text(log.content, style: TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Review Note Card ─────────────────────────────────────────────────────────

class _ReviewNoteCard extends StatelessWidget {
  const _ReviewNoteCard({required this.controller, required this.assignment});
  final TextEditingController controller;
  final PipelineAssignment assignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reviewer Note (optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF17324D))),
          const SizedBox(height: 3),
          Text('Required if requesting resubmission or rejecting.', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
          const SizedBox(height: 10),
          if (assignment.reviewerNotes != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF57F17).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.history_rounded, size: 13, color: Color(0xFFF57F17)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Previous note: ${assignment.reviewerNotes}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFF57F17)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add note for the volunteer…',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.assignment,
    required this.event,
    required this.activity,
    required this.vm,
    required this.noteCtrl,
  });

  final PipelineAssignment assignment;
  final PipelineEvent event;
  final PipelineActivity activity;
  final EventPipelineViewModel vm;
  final TextEditingController noteCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Approve
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _approve(context),
            icon: const Icon(Icons.verified_rounded, size: 16),
            label: const Text('Approve Submission', style: TextStyle(fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _requestResubmission(context),
                icon: const Icon(Icons.replay_rounded, size: 15),
                label: const Text('Request Resubmission', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6A1B9A),
                  side: const BorderSide(color: Color(0xFF6A1B9A)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reject(context),
                icon: const Icon(Icons.cancel_outlined, size: 15),
                label: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC62828),
                  side: const BorderSide(color: Color(0xFFC62828)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _approve(BuildContext context) {
    vm.approveSubmission(event.id, activity.id, assignment.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Submission approved for ${assignment.studentName}'),
        backgroundColor: const Color(0xFF00695C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requestResubmission(BuildContext context) {
    final note = noteCtrl.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a note explaining what needs to be corrected.'),
          backgroundColor: Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    vm.requestResubmission(event.id, activity.id, assignment.id, note);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resubmission requested. Volunteer will be notified.'),
        backgroundColor: Color(0xFF6A1B9A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reject(BuildContext context) {
    final note = noteCtrl.text.trim();
    vm.rejectSubmission(event.id, activity.id, assignment.id, note);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Submission rejected for ${assignment.studentName}.'),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
