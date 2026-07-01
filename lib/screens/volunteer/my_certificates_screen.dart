import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../features/certificates/presentation/screens/certificate_detail_screen.dart';
import '../../features/certificates/services/certificate_file_service.dart';
import '../../features/certificates/services/certificate_pdf_service.dart';
import '../../models/certificate_models.dart';
import '../../models/ngo_profile.dart';
import '../../repositories/certificate_repository.dart';
import '../../repositories/ngo_repository.dart';
import '../../utils/file_download.dart';
import '../../viewmodels/volunteer_viewmodel.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({required this.vm, super.key});
  final VolunteerViewModel vm;

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  NGOProfile _ngo = NGOProfile.fallback;

  @override
  void initState() {
    super.initState();
    widget.vm.loadCertificates();
    _loadNgo();
  }

  Future<void> _loadNgo() async {
    final ngo = await NGORepository.getProfile();
    if (mounted) setState(() => _ngo = ngo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text(
          'My Certificates',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              widget.vm.loadCertificates();
              _loadNgo();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          if (widget.vm.certificates.isEmpty) {
            return _EmptyCerts(ngo: _ngo);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            itemCount: widget.vm.certificates.length,
            separatorBuilder: (context, _) => const SizedBox(height: 20),
            itemBuilder: (_, i) => _CertificateCard(
              cert: widget.vm.certificates[i],
              ngo: _ngo,
              onRefresh: widget.vm.loadCertificates,
            ),
          );
        },
      ),
    );
  }
}

// ── Certificate Card ──────────────────────────────────────────────────────────

class _CertificateCard extends StatefulWidget {
  const _CertificateCard({
    required this.cert,
    required this.ngo,
    required this.onRefresh,
  });
  final Certificate cert;
  final NGOProfile ngo;
  final VoidCallback onRefresh;

  @override
  State<_CertificateCard> createState() => _CertificateCardState();
}

class _CertificateCardState extends State<_CertificateCard> {
  bool _generating = false;
  bool _downloading = false;

  Certificate get cert => widget.cert;
  NGOProfile get ngo => widget.ngo;

  // Show generate/download for every active certificate (not rejected or revoked).
  bool get _canGenerate => cert.status.isActive;

  // Official server PDF is available for generated / issued / downloaded + file set.
  bool get _hasServerFile =>
      cert.status.canDownload && cert.certificateFile != null;

  bool get _isIssued => cert.status == CertificateStatus.issued;
  bool get _isRevoked => cert.status == CertificateStatus.revoked;
  bool get _isRejected => cert.status == CertificateStatus.rejected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildBody(context),
        ],
      ),
    );
  }

  // ── Header with NGO branding ──────────────────────────────────────────────

  Widget _buildHeader() {
    final (gradA, gradB) = _isIssued
        ? (const Color(0xFF4A148C), const Color(0xFF7B1FA2))
        : _canGenerate
            ? (const Color(0xFF0D47A1), const Color(0xFF1565C0))
            : _isRevoked || _isRejected
                ? (const Color(0xFF616161), const Color(0xFF757575))
                : (const Color(0xFF1565C0), const Color(0xFF1976D2));

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradA, gradB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NGO identity row
          Row(
            children: [
              // NGO Logo
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assests/ngo_logo.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, _) => const Icon(
                      Icons.account_balance_rounded,
                      size: 28,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ngo.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (ngo.tagline != null)
                      Text(
                        ngo.tagline!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10,
                          letterSpacing: 0.2,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusChip(status: cert.status),
            ],
          ),
          const SizedBox(height: 14),
          // Thin gold divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFD4A017).withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Certificate title
          Text(
            cert.certificateType.templateTitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFD4A017),
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                cert.certificateId,
                style: const TextStyle(
                  color: Color(0xFFD4A017),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (cert.isVerified) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 10, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volunteer info row
          if (AppState.studentName != null)
            _InfoRow(
              icon: Icons.person_rounded,
              label: 'Volunteer',
              value: AppState.studentName!,
              highlight: true,
            ),
          _InfoRow(
            icon: Icons.volunteer_activism_rounded,
            label: 'Activity',
            value: cert.activityName,
          ),
          if (cert.duration != null)
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Duration',
              value: cert.duration!,
            ),
          if (cert.signatoryName != null)
            _InfoRow(
              icon: Icons.draw_rounded,
              label: 'Signed By',
              value:
                  '${cert.signatoryName!}${cert.signatoryTitle != null ? '\n${cert.signatoryTitle!}' : ''}',
            ),
          if (cert.issueDate != null)
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Issue Date',
              value:
                  '${cert.issueDate!.day.toString().padLeft(2, '0')} ${_month(cert.issueDate!.month)} ${cert.issueDate!.year}',
            ),
          if (ngo.registrationNumber != null)
            _InfoRow(
              icon: Icons.badge_rounded,
              label: 'NGO Reg.',
              value: ngo.registrationNumber!,
            ),
          if (cert.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.softRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.softRed.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.softRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cert.rejectionReason!,
                      style: const TextStyle(
                        color: AppColors.softRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Action buttons
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Generate / Download PDF button — visible for all active certificates
        if (_canGenerate)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : () => _generatePdf(context),
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: Text(
                _generating ? 'Generating…' : 'Generate & Download PDF',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

        // Download PDF button (server file available: generated / issued / downloaded)
        if (_hasServerFile) ...[
          if (_canGenerate) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _downloading ? null : () => _download(context),
              icon: _downloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4A148C),
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(
                _downloading ? 'Downloading…' : 'Download PDF',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4A148C),
                side: const BorderSide(color: Color(0xFF4A148C), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        // QR verification button
        // View full certificate detail screen
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CertificateDetailScreen(
                  certificate: cert,
                  ngo: ngo,
                ),
              ),
            ),
            icon: const Icon(Icons.workspace_premium_rounded, size: 18),
            label: const Text(
              'View Certificate',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD4A017),
              side: const BorderSide(color: Color(0xFFD4A017), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        if (cert.qrToken != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showQrInfo(context),
              icon: const Icon(Icons.qr_code_rounded, size: 16),
              label: const Text(
                'Share Verification Link',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _generatePdf(BuildContext context) async {
    setState(() => _generating = true);
    try {
      final recipientName =
          AppState.studentName ?? cert.studentName ?? 'Student';
      final bytes = await CertificatePdfService.generateCertificatePdf(
        certificate: cert,
        recipientName: recipientName,
        ngoProfile: widget.ngo,
      );

      if (cert.status == CertificateStatus.approved) {
        try {
          await CertificateRepository.markGenerated(cert.id);
          widget.onRefresh();
        } catch (_) {}
      }

      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _PdfReadySheet(
          certId: cert.certificateId,
          ngoName: ngo.name,
          pdfBytes: bytes,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generation failed: $e'),
          backgroundColor: AppColors.softRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _download(BuildContext context) async {
    setState(() => _downloading = true);
    try {
      final ok = await downloadFile(
        CertificateRepository.downloadUrl(cert),
        'certificate_${cert.certificateId}.pdf',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Certificate downloaded successfully.'
                : 'Certificate PDF is not available yet.',
          ),
          backgroundColor: ok ? const Color(0xFF2E7D32) : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while downloading. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showQrInfo(BuildContext context) {
    final url = CertificateRepository.verificationUrl(cert);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.qr_code_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Verify Certificate',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Anyone can verify this certificate from ${ngo.name} using the link below.',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification link copied!')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text('Copy Link'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}

// ── PDF Ready Bottom Sheet ────────────────────────────────────────────────────

class _PdfReadySheet extends StatefulWidget {
  const _PdfReadySheet({
    required this.certId,
    required this.ngoName,
    required this.pdfBytes,
  });
  final String certId;
  final String ngoName;
  final Uint8List pdfBytes;

  @override
  State<_PdfReadySheet> createState() => _PdfReadySheetState();
}

class _PdfReadySheetState extends State<_PdfReadySheet> {
  bool _saving = false;
  String? _savedPath;

  Future<void> _saveToDevice() async {
    setState(() => _saving = true);
    try {
      // On web, trigger the browser's print/save dialog via the printing package.
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: widget.pdfBytes,
          filename: 'certificate_${widget.certId}.pdf',
        );
        if (mounted) setState(() => _savedPath = 'web');
        return;
      }

      final path = await CertificateFileService.savePdfBytes(
        widget.pdfBytes,
        filename: 'certificate_${widget.certId}.pdf',
      );
      if (!mounted) return;
      if (path != null) {
        setState(() => _savedPath = path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate saved to your device.'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the file. Try "Share / Print PDF" instead.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download failed. Try "Share / Print PDF" instead.'),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Success icon
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 40,
              color: Color(0xFFD4A017),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Certificate Ready!',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.ngoName,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.certId,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 24),
          // Download to device button (primary)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveToDevice,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _savedPath != null
                          ? Icons.check_circle_rounded
                          : Icons.download_rounded,
                      size: 20,
                    ),
              label: Text(
                _saving
                    ? 'Downloading…'
                    : _savedPath != null
                        ? 'Downloaded Successfully'
                        : 'Download PDF',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _savedPath != null
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Share / Open button (secondary)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await Printing.sharePdf(
                  bytes: widget.pdfBytes,
                  filename: 'certificate_${widget.certId}.pdf',
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text(
                'Share / Print PDF',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D47A1),
                side: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CertificateStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, label, icon) = switch (status) {
      CertificateStatus.issued    => (const Color(0xFFD4A017), 'Issued', Icons.star_rounded),
      CertificateStatus.approved  => (Colors.white, 'Ready', Icons.check_circle_rounded),
      CertificateStatus.generated => (Colors.white, 'Generated', Icons.picture_as_pdf_rounded),
      CertificateStatus.pending   => (Colors.white70, 'Pending', Icons.hourglass_top_rounded),
      CertificateStatus.rejected  => (Colors.redAccent, 'Rejected', Icons.cancel_rounded),
      CertificateStatus.revoked   => (Colors.redAccent, 'Revoked', Icons.block_rounded),
      _                           => (Colors.white70, status.displayName, Icons.info_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: bg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: bg,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: const Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
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
                color: highlight
                    ? const Color(0xFF0D47A1)
                    : AppColors.ink,
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCerts extends StatelessWidget {
  const _EmptyCerts({required this.ngo});
  final NGOProfile ngo;

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
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 52,
                color: Color(0xFFD4A017),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              ngo.name,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No Certificates Yet',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Complete volunteer activities and get your\nwork approved to earn official certificates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                height: 1.6,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
