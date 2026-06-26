import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/certificate_models.dart';
import '../../viewmodels/volunteer_viewmodel.dart';
import '../../repositories/certificate_repository.dart';
import '../../utils/file_download.dart';
import 'package:flutter/services.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({required this.vm, super.key});
  final VolunteerViewModel vm;

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  @override
  void initState() {
    super.initState();
    widget.vm.loadCertificates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Certificates',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          if (widget.vm.certificates.isEmpty) {
            return const _EmptyCerts();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: widget.vm.certificates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                _CertificateCard(cert: widget.vm.certificates[i]),
          );
        },
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.cert});
  final Certificate cert;

  @override
  Widget build(BuildContext context) {
    final isIssued = cert.status == CertificateStatus.issued;
    final color = isIssued ? const Color(0xFF9C27B0) : AppColors.muted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Header gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isIssued
                    ? [const Color(0xFF6A1B9A), const Color(0xFF9C27B0)]
                    : [AppColors.muted, AppColors.muted.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.certificateType.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        cert.certificateId,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (cert.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CertRow(label: 'Activity', value: cert.activityName),
                if (cert.duration != null)
                  _CertRow(label: 'Duration', value: cert.duration!),
                if (cert.signatoryName != null)
                  _CertRow(
                    label: 'Signed By',
                    value:
                        '${cert.signatoryName!}${cert.signatoryTitle != null ? ", ${cert.signatoryTitle}" : ""}',
                  ),
                if (cert.issueDate != null)
                  _CertRow(
                    label: 'Issued On',
                    value:
                        '${cert.issueDate!.day}/${cert.issueDate!.month}/${cert.issueDate!.year}',
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _StatusBadge(status: cert.status)),
                    if (isIssued && cert.certificateFile != null)
                      TextButton.icon(
                        onPressed: () => _download(context),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF9C27B0),
                        ),
                      ),
                    if (cert.qrToken != null)
                      IconButton(
                        onPressed: () => _showQrInfo(context, cert.qrToken!),
                        icon: const Icon(
                          Icons.qr_code_rounded,
                          color: AppColors.primary,
                        ),
                        tooltip: 'QR Verify',
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

  Future<void> _download(BuildContext context) async {
    final ok = await downloadFile(
      CertificateRepository.downloadUrl(cert),
      '${cert.certificateId}.pdf',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Certificate download started.'
              : 'Could not open certificate PDF.',
        ),
      ),
    );
  }

  void _showQrInfo(BuildContext context, String token) {
    final verificationUrl = CertificateRepository.verificationUrl(cert);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'QR Verification',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Share this certificate ID to let anyone verify it online.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            SelectableText(
              verificationUrl,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: verificationUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification link copied.')),
              );
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _CertRow extends StatelessWidget {
  const _CertRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
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
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final CertificateStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      CertificateStatus.issued    => (AppColors.secondary, 'Issued & Available'),
      CertificateStatus.approved  => (AppColors.primary, 'Approved — Ready to Generate'),
      CertificateStatus.generated => (AppColors.primary, 'PDF Generated'),
      CertificateStatus.revoked   => (AppColors.softRed, 'Revoked'),
      CertificateStatus.rejected  => (AppColors.softRed, 'Rejected'),
      CertificateStatus.draft     => (AppColors.muted, 'Draft'),
      CertificateStatus.pending_signature => (AppColors.accent, 'Pending Signature'),
      CertificateStatus.signed    => (AppColors.primary, 'Signed — Ready Soon'),
      CertificateStatus.pending   => (AppColors.accent, 'Pending Approval'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyCerts extends StatelessWidget {
  const _EmptyCerts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 48,
                color: Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No certificates yet',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete approved volunteer work and the NGO will issue certificates. QR verification is included.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
