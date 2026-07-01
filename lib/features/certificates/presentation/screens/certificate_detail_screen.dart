import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../../../app_state.dart';
import '../../../../core/colors.dart';
import '../../../../models/certificate_models.dart';
import '../../../../models/ngo_profile.dart';
import '../../services/certificate_file_service.dart';
import '../../services/certificate_pdf_service.dart';
import '../widgets/certificate_visual_card.dart';
import 'certificate_preview_screen.dart';

class CertificateDetailScreen extends StatefulWidget {
  const CertificateDetailScreen({
    required this.certificate,
    required this.ngo,
    super.key,
  });

  final Certificate certificate;
  final NGOProfile ngo;

  @override
  State<CertificateDetailScreen> createState() => _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  bool _downloading = false;
  bool _sharing = false;

  Certificate get cert => widget.certificate;
  NGOProfile get ngo => widget.ngo;

  String get _recipientName =>
      AppState.studentName ?? cert.studentName ?? 'Student';

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _downloadPdf() async {
    setState(() => _downloading = true);
    try {
      final bytes = await CertificatePdfService.generateCertificatePdf(
        certificate: cert,
        recipientName: _recipientName,
        ngoProfile: ngo,
      );
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: AppColors.softRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await CertificateFileService.sharePdf(
        certificate: cert,
        recipientName: _recipientName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: AppColors.softRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _viewFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificatePreviewScreen(
          certificate: cert,
          recipientName: _recipientName,
        ),
      ),
    );
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: cert.certificateId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Certificate ID copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A1F44),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Certificate',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: Image.asset(
                  'assests/ngo_logo.jpeg',
                  fit: BoxFit.cover,
                  width: 38,
                  height: 38,
                  errorBuilder: (_, _, _) => const CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFF0D47A1),
                    child: Icon(Icons.account_balance, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            // ── Certificate visual card ──────────────────────────────────────
            CertificateVisualCard(
              certificate: cert,
              recipientName: _recipientName,
              ngo: ngo,
            ),

            const SizedBox(height: 16),

            // ── Metadata section ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MetaRow(
                    icon: Icons.shield_rounded,
                    iconColor: const Color(0xFF0D47A1),
                    label: 'Certificate ID',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cert.certificateId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF0A1F44),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _copyId,
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 15,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Divider(),
                  _MetaRow(
                    icon: Icons.check_circle_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    label: 'Status',
                    trailing: _StatusBadge(status: cert.status),
                  ),
                  const _Divider(),
                  _MetaRow(
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF0D47A1),
                    label: 'Issue Date',
                    trailing: Text(
                      cert.issueDate != null ? _fmtFull(cert.issueDate!) : '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                  ),
                  const _Divider(),
                  _MetaRow(
                    icon: Icons.campaign_rounded,
                    iconColor: const Color(0xFF0D47A1),
                    label: 'Activity',
                    trailing: Text(
                      cert.activityName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Download PDF button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloading ? null : _downloadPdf,
                icon: _downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: Text(
                  _downloading ? 'Generating…' : 'Download PDF',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Share + View Fullscreen row ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      _sharing ? '…' : 'Share',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D47A1),
                      side: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _viewFullscreen,
                    icon: const Icon(Icons.fullscreen_rounded, size: 18),
                    label: const Text(
                      'View Fullscreen',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D47A1),
                      side: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtFull(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ── Metadata helpers ──────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF78909C),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final CertificateStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      CertificateStatus.issued     => (const Color(0xFF2E7D32), 'Issued'),
      CertificateStatus.approved   => (const Color(0xFF2E7D32), 'Approved'),
      CertificateStatus.generated  => (const Color(0xFF1565C0), 'Generated'),
      CertificateStatus.downloaded => (const Color(0xFF00695C), 'Downloaded'),
      CertificateStatus.pending    => (const Color(0xFFF57F17), 'Pending'),
      CertificateStatus.rejected   => (const Color(0xFFC62828), 'Rejected'),
      CertificateStatus.revoked    => (const Color(0xFF616161), 'Revoked'),
      CertificateStatus.draft      => (const Color(0xFF1565C0), 'Draft'),
      _                            => (const Color(0xFF78909C), status.displayName),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
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
  final List<int> pdfBytes;

  @override
  State<_PdfReadySheet> createState() => _PdfReadySheetState();
}

class _PdfReadySheetState extends State<_PdfReadySheet> {
  bool _saving = false;
  bool _done = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: widget.pdfBytes as dynamic,
          filename: 'certificate_${widget.certId}.pdf',
        );
        if (mounted) setState(() => _done = true);
        return;
      }
      final path = await CertificateFileService.savePdfBytes(
        widget.pdfBytes as dynamic,
        filename: 'certificate_${widget.certId}.pdf',
      );
      if (!mounted) return;
      if (path != null) {
        setState(() => _done = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate saved to your device.'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      // ignore
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
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
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
          Text(widget.ngoName,
              style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(widget.certId, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_done ? Icons.check_circle_rounded : Icons.download_rounded, size: 20),
              label: Text(
                _saving ? 'Downloading…' : _done ? 'Downloaded Successfully' : 'Download PDF',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _done ? const Color(0xFF2E7D32) : const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await Printing.sharePdf(
                  bytes: widget.pdfBytes as dynamic,
                  filename: 'certificate_${widget.certId}.pdf',
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share / Print PDF',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D47A1),
                side: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
