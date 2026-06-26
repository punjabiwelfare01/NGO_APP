import 'package:flutter/material.dart';

import '../../../../core/colors.dart';
import '../../../../models/certificate_models.dart';
import '../../../../repositories/certificate_repository.dart';
import '../widgets/certificate_status_badge.dart';

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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CertificateRepository.getPendingCertificates(),
        CertificateRepository.getAllCertificates(),
      ]);
      if (mounted) {
        setState(() {
          _pending = results[0];
          _all = results[1];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Certificate cert) async {
    final result = await showDialog<_ApproveData>(
      context: context,
      builder: (_) => const _ApproveDialog(),
    );
    if (result == null) return;
    try {
      await CertificateRepository.approveCertificate(
        cert.id,
        signatoryName: result.signatoryName,
        signatoryTitle: result.signatoryTitle,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate approved. Student has been notified.'),
            backgroundColor: AppColors.secondary,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate request rejected.'),
            backgroundColor: AppColors.accent,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejection failed: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate revoked.'),
            backgroundColor: AppColors.softRed,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Revoke failed: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Certificate Management',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'All (${_all.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
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
                    _CertList(
                      certs: _pending,
                      emptyMessage:
                          'No pending certificate requests.\nAll caught up!',
                      onApprove: _approve,
                      onReject: _reject,
                      onRevoke: null,
                    ),
                    _CertList(
                      certs: _all,
                      emptyMessage: 'No certificates yet.',
                      onApprove: _approve,
                      onReject: _reject,
                      onRevoke: _revoke,
                    ),
                  ],
                ),
    );
  }
}

class _CertList extends StatelessWidget {
  const _CertList({
    required this.certs,
    required this.emptyMessage,
    required this.onApprove,
    required this.onReject,
    required this.onRevoke,
  });

  final List<Certificate> certs;
  final String emptyMessage;
  final void Function(Certificate) onApprove;
  final void Function(Certificate) onReject;
  final void Function(Certificate)? onRevoke;

  @override
  Widget build(BuildContext context) {
    if (certs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.task_alt_rounded,
                size: 52,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 14),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.5,
                  fontSize: 13,
                ),
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
          onApprove: cert.status == CertificateStatus.pending
              ? () => onApprove(cert)
              : null,
          onReject: cert.status == CertificateStatus.pending
              ? () => onReject(cert)
              : null,
          onRevoke: onRevoke != null &&
                  cert.status != CertificateStatus.revoked &&
                  cert.status != CertificateStatus.rejected
              ? () => onRevoke!(cert)
              : null,
        );
      },
    );
  }
}

class _AdminCertTile extends StatelessWidget {
  const _AdminCertTile({
    required this.certificate,
    required this.onApprove,
    required this.onReject,
    required this.onRevoke,
  });

  final Certificate certificate;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRevoke;

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
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.studentName ?? 'Student #${certificate.studentId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        certificate.certificateType.displayName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
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
                if (certificate.duration != null)
                  _Row('Duration', certificate.duration!),
                if (certificate.createdAt != null)
                  _Row('Requested', _fmt(certificate.createdAt!)),
                if (certificate.rejectionReason != null)
                  _Row(
                    'Rejection',
                    certificate.rejectionReason!,
                    valueColor: AppColors.softRed,
                  ),
                _Row('Cert ID', certificate.certificateId),
                const SizedBox(height: 12),

                // Action buttons
                if (onApprove != null || onReject != null || onRevoke != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onApprove != null)
                        _Btn(
                          label: 'Approve',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.secondary,
                          onTap: onApprove!,
                        ),
                      if (onReject != null)
                        _Btn(
                          label: 'Reject',
                          icon: Icons.cancel_rounded,
                          color: AppColors.softRed,
                          onTap: onReject!,
                        ),
                      if (onRevoke != null)
                        _Btn(
                          label: 'Revoke',
                          icon: Icons.block_rounded,
                          color: AppColors.muted,
                          onTap: onRevoke!,
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
            width: 72,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
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
  const _Btn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialogs ──────────────────────────────────────────────────────────────────

class _ApproveData {
  const _ApproveData({this.signatoryName, this.signatoryTitle});
  final String? signatoryName;
  final String? signatoryTitle;
}

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog();

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Approve Certificate',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Signatory Title (optional)',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(
            _ApproveData(
              signatoryName: _nameCtrl.text.trim().isEmpty
                  ? null
                  : _nameCtrl.text.trim(),
              signatoryTitle: _titleCtrl.text.trim().isEmpty
                  ? null
                  : _titleCtrl.text.trim(),
            ),
          ),
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
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
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
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.softRed),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
