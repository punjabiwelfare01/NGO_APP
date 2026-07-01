import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/colors.dart';
import '../../../../models/certificate_models.dart';
import '../../../../models/ngo_profile.dart';
import '../../../../repositories/certificate_repository.dart';
import '../../../../repositories/ngo_repository.dart';
import '../widgets/certificate_status_badge.dart';
import 'certificate_detail_form_screen.dart';
import 'certificate_preview_screen.dart';

class AdminCertificateApprovalScreen extends StatefulWidget {
  const AdminCertificateApprovalScreen({super.key});

  @override
  State<AdminCertificateApprovalScreen> createState() =>
      _AdminCertificateApprovalScreenState();
}

class _AdminCertificateApprovalScreenState
    extends State<AdminCertificateApprovalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Certificate> _pending = [];
  List<Certificate> _all = [];
  List<Map<String, dynamic>> _ready = [];
  NGOProfile _ngo = NGOProfile.fallback;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
    _loadNgo();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadNgo() async {
    final ngo = await NGORepository.getProfile();
    if (mounted) setState(() => _ngo = ngo);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        CertificateRepository.getPendingCertificates(),
        CertificateRepository.getAllCertificates(),
        CertificateRepository.getReadyToGenerate(),
      ]);
      if (mounted) {
        setState(() {
          _pending = results[0] as List<Certificate>;
          _all     = results[1] as List<Certificate>;
          _ready   = results[2] as List<Map<String, dynamic>>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openDetailForm(
    BuildContext ctx, {
    Certificate? cert,
    Map<String, dynamic>? prefill,
  }) async {
    final result = await Navigator.of(ctx).push<Certificate>(
      MaterialPageRoute(
        builder: (_) => CertificateDetailFormScreen(
          certificate: cert,
          prefill: prefill,
        ),
      ),
    );
    if (result != null) _load();
  }

  Future<void> _previewCert(Certificate cert) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CertificatePreviewScreen(
              certificate: cert,
              recipientName: cert.studentName ?? '',
            ),
      ),
    );
  }

  Future<void> _downloadCert(Certificate cert) async {
    final url = CertificateRepository.adminDownloadUrl(cert);
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppColors.softRed,
        ));
      }
    }
  }

  Future<void> _createImpactStory(Certificate cert) async {
    // If no impact_story_summary, prompt for one
    String? summary;
    final entered = await showDialog<String>(
      context: context,
      builder: (_) => _ImpactStoryDialog(
        studentName: cert.studentName ?? 'Student',
        activityName: cert.activityName,
        prefillSummary: cert.impactStorySummary,
      ),
    );
    if (entered == null) return;
    summary = entered.trim().isEmpty ? null : entered.trim();

    try {
      final result = await CertificateRepository.createImpactStory(
        cert.id,
        overrideSummary: summary,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Impact story created (ID: ${result['impact_story_id']}). '
            'Edit it in Social Impact section.',
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().contains('already')
              ? 'Impact story already exists for this certificate.'
              : 'Failed: $e'),
          backgroundColor: AppColors.softRed,
        ));
      }
    }
  }

  Future<void> _approve(Certificate cert) async {
    final result = await showDialog<_ApproveData>(
      context: context,
      builder: (_) => _ApproveDialog(
        initialName: cert.signatoryName,
        initialTitle: cert.signatoryTitle,
      ),
    );
    if (result == null) return;
    try {
      await CertificateRepository.approveCertificate(
        cert.id,
        signatoryName: result.signatoryName,
        signatoryTitle: result.signatoryTitle,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Certificate approved. Student notified.'),
          backgroundColor: AppColors.secondary,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Approval failed: $e'),
          backgroundColor: AppColors.softRed,
        ));
      }
    }
  }

  Future<void> _reject(Certificate cert) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (reason == null) return;
    try {
      await CertificateRepository.rejectCertificate(cert.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Certificate request rejected.'),
          backgroundColor: AppColors.accent,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Rejection failed: $e'),
          backgroundColor: AppColors.softRed,
        ));
      }
    }
  }

  Future<void> _revoke(Certificate cert) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(title: 'Revoke Certificate'),
    );
    if (reason == null) return;
    try {
      await CertificateRepository.revokeCertificate(cert.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Certificate revoked.'),
          backgroundColor: AppColors.softRed,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Revoke failed: $e'),
          backgroundColor: AppColors.softRed,
        ));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assests/ngo_logo.jpeg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.account_balance_rounded,
                  size: 28,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ngo.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFF0D47A1),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Certificate Management',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Ready (${_ready.length})'),
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'All (${_all.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () { _load(); _loadNgo(); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _ReadyList(
                      items: _ready,
                      onFillDetails: (item) => _openDetailForm(context, prefill: item),
                    ),
                    _CertList(
                      certs: _pending,
                      emptyMessage: 'No pending certificate requests.\nAll caught up!',
                      onApprove: _approve,
                      onReject: _reject,
                      onRevoke: _revoke,
                      onEdit: (c) => _openDetailForm(context, cert: c),
                      onPreview: _previewCert,
                      onDownload: _downloadCert,
                      onImpactStory: _createImpactStory,
                    ),
                    _CertList(
                      certs: _all,
                      emptyMessage: 'No certificates yet.',
                      onApprove: _approve,
                      onReject: _reject,
                      onRevoke: _revoke,
                      onEdit: (c) => _openDetailForm(context, cert: c),
                      onPreview: _previewCert,
                      onDownload: (c) => c.status.canDownload ? _downloadCert(c) : null,
                      onImpactStory: (c) =>
                          c.impactStoryId == null && c.status.canGeneratePdf
                              ? _createImpactStory(c)
                              : null,
                    ),
                  ],
                ),
    );
  }
}

// ── Ready list ────────────────────────────────────────────────────────────────

class _ReadyList extends StatelessWidget {
  const _ReadyList({required this.items, required this.onFillDetails});
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onFillDetails;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt_rounded, size: 52, color: AppColors.secondary),
              SizedBox(height: 14),
              Text(
                'No assignments ready for certificate generation.\nEM must approve submissions first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final item = items[i];
        final hours = (item['hours_worked'] as num?)?.toStringAsFixed(1) ?? '–';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['student_name'] as String? ?? 'Student',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                          ),
                          Text(
                            item['activity_name'] as String? ?? 'Activity',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'EM Verified',
                        style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.w700),
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
                    _Row('Hours', '$hours hrs'),
                    if (item['submission_title'] != null)
                      _Row('Work', item['submission_title'] as String),
                    if (item['approved_at'] != null)
                      _Row('Approved', _fmtDate(item['approved_at'] as String)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => onFillDetails(item),
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Text('Fill Details & Generate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Certificate list ──────────────────────────────────────────────────────────

class _CertList extends StatelessWidget {
  const _CertList({
    required this.certs,
    required this.emptyMessage,
    required this.onApprove,
    required this.onReject,
    required this.onRevoke,
    required this.onEdit,
    required this.onPreview,
    required this.onDownload,
    required this.onImpactStory,
  });

  final List<Certificate> certs;
  final String emptyMessage;
  final void Function(Certificate) onApprove;
  final void Function(Certificate) onReject;
  final void Function(Certificate)? onRevoke;
  final void Function(Certificate) onEdit;
  final void Function(Certificate) onPreview;
  final void Function(Certificate)? onDownload;
  final void Function(Certificate)? onImpactStory;

  @override
  Widget build(BuildContext context) {
    if (certs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.task_alt_rounded, size: 52, color: AppColors.secondary),
              const SizedBox(height: 14),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.5, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: certs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final cert = certs[i];
        return _AdminCertTile(
          certificate: cert,
          onApprove: cert.status == CertificateStatus.pending ? () => onApprove(cert) : null,
          onReject:  cert.status == CertificateStatus.pending ? () => onReject(cert) : null,
          onRevoke: (onRevoke != null &&
                  cert.status != CertificateStatus.revoked &&
                  cert.status != CertificateStatus.rejected)
              ? () => onRevoke!(cert)
              : null,
          onEdit: () => onEdit(cert),
          onPreview: () => onPreview(cert),
          onDownload: onDownload != null ? () => onDownload!(cert) : null,
          onImpactStory: (onImpactStory != null && cert.impactStoryId == null)
              ? () => onImpactStory!(cert)
              : null,
        );
      },
    );
  }
}

// ── Certificate tile ──────────────────────────────────────────────────────────

class _AdminCertTile extends StatelessWidget {
  const _AdminCertTile({
    required this.certificate,
    required this.onApprove,
    required this.onReject,
    required this.onRevoke,
    required this.onEdit,
    required this.onPreview,
    required this.onDownload,
    required this.onImpactStory,
  });

  final Certificate certificate;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRevoke;
  final VoidCallback onEdit;
  final VoidCallback? onPreview;
  final VoidCallback? onDownload;
  final VoidCallback? onImpactStory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.studentName ?? 'Student #${certificate.studentId}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Text(
                        certificate.certificateType.displayName,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                CertificateStatusBadge(status: certificate.status),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row('Activity', certificate.activityName),
                if (certificate.eventName != null)
                  _Row('Event', certificate.eventName!),
                if (certificate.studentRole != null)
                  _Row('Role', certificate.studentRole!),
                if (certificate.serviceHours != null)
                  _Row('Hours', '${certificate.serviceHours} hrs')
                else if (certificate.duration != null)
                  _Row('Duration', certificate.duration!),
                if (certificate.signatoryName != null)
                  _Row('Approved by', certificate.signatoryName!),
                if (certificate.createdAt != null)
                  _Row('Created', _fmt(certificate.createdAt!)),
                if (certificate.rejectionReason != null)
                  _Row('Rejection', certificate.rejectionReason!, valueColor: AppColors.softRed),
                if (certificate.impactStoryId != null)
                  _Row('Impact Story', 'Created (ID ${certificate.impactStoryId})',
                      valueColor: AppColors.secondary),
                _Row('Cert ID', certificate.certificateId),
                const SizedBox(height: 12),

                // Action buttons — primary row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Btn(label: 'Edit Details', icon: Icons.edit_rounded, color: const Color(0xFF0D47A1), onTap: onEdit),
                    if (onPreview != null)
                      _Btn(label: 'Preview', icon: Icons.picture_as_pdf_rounded, color: AppColors.primary, onTap: onPreview!),
                    if (onDownload != null)
                      _Btn(label: 'Download', icon: Icons.download_rounded, color: AppColors.secondary, onTap: onDownload!),
                    if (onApprove != null)
                      _Btn(label: 'Approve', icon: Icons.check_circle_rounded, color: AppColors.secondary, onTap: onApprove!),
                    if (onReject != null)
                      _Btn(label: 'Reject', icon: Icons.cancel_rounded, color: AppColors.softRed, onTap: onReject!),
                    if (onRevoke != null)
                      _Btn(label: 'Revoke', icon: Icons.block_rounded, color: AppColors.muted, onTap: onRevoke!),
                    if (onImpactStory != null)
                      _Btn(
                        label: 'Create Impact Story',
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFF6A1B9A),
                        onTap: onImpactStory!,
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

class _ApproveData {
  const _ApproveData({this.signatoryName, this.signatoryTitle});
  final String? signatoryName;
  final String? signatoryTitle;
}

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog({
    this.initialName,
    this.initialTitle,
  });
  final String? initialName;
  final String? initialTitle;

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.initialName ?? '');
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve Certificate', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Optionally add signatory details that will appear on the certificate.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Signatory Name (optional)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Signatory Title (optional)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(_ApproveData(
            signatoryName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
            signatoryTitle: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          )),
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Approve'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({this.title = 'Reject Request'});
  final String title;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Provide a reason. The student will be notified.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter reason…',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final reason = _ctrl.text.trim();
            if (reason.isEmpty) return;
            Navigator.of(context).pop(reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.softRed,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.title.split(' ').first),
        ),
      ],
    );
  }
}

class _ImpactStoryDialog extends StatefulWidget {
  const _ImpactStoryDialog({
    required this.studentName,
    required this.activityName,
    this.prefillSummary,
  });
  final String studentName;
  final String activityName;
  final String? prefillSummary;

  @override
  State<_ImpactStoryDialog> createState() => _ImpactStoryDialogState();
}

class _ImpactStoryDialogState extends State<_ImpactStoryDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.prefillSummary ??
          '${widget.studentName} completed ${widget.activityName} and made a positive impact in the community.',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Impact Story', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'An impact story draft will be created using the certificate data. Edit the summary below before publishing.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Impact summary…',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Create Story'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.softRed),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
