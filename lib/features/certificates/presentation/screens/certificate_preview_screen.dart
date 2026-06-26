import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/colors.dart';
import '../../../../models/certificate_models.dart';
import '../../../../repositories/certificate_repository.dart';
import '../../services/certificate_file_service.dart';

class CertificatePreviewScreen extends StatefulWidget {
  const CertificatePreviewScreen({
    required this.certificate,
    required this.recipientName,
    super.key,
  });

  final Certificate certificate;
  final String recipientName;

  @override
  State<CertificatePreviewScreen> createState() =>
      _CertificatePreviewScreenState();
}

class _CertificatePreviewScreenState extends State<CertificatePreviewScreen> {
  Uint8List? _pdfBytes;
  bool _loading = true;
  bool _saving = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    setState(() => _loading = true);
    try {
      final bytes = await CertificateFileService.getPdfBytes(
        certificate: widget.certificate,
        recipientName: widget.recipientName,
      );
      // Notify backend that PDF has been generated (only if currently approved)
      if (widget.certificate.status == CertificateStatus.approved) {
        try {
          await CertificateRepository.markGenerated(widget.certificate.id);
        } catch (_) {
          // Non-fatal — the PDF is still usable
        }
      }
      if (mounted) setState(() => _pdfBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generation failed: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final path = await CertificateFileService.savePdf(
      certificate: widget.certificate,
      recipientName: widget.recipientName,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(path != null
            ? 'Certificate saved to Downloads.'
            : 'Could not save certificate.'),
        backgroundColor:
            path != null ? AppColors.secondary : AppColors.softRed,
        action: path != null
            ? SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () => CertificateFileService.openFile(path),
              )
            : null,
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await CertificateFileService.sharePdf(
        certificate: widget.certificate,
        recipientName: widget.recipientName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _print() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Certificate Preview',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          if (!_loading && _pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.print_rounded),
              onPressed: _print,
              tooltip: 'Print',
            ),
        ],
      ),
      body: Column(
        children: [
          // Action buttons bar
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.download_rounded,
                    label: _saving ? 'Saving…' : 'Save PDF',
                    color: AppColors.primary,
                    onTap:
                        (_loading || _saving) ? null : _save,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.share_rounded,
                    label: _sharing ? 'Sharing…' : 'Share',
                    color: const Color(0xFF1565C0),
                    onTap: (_loading || _sharing) ? null : _share,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // PDF preview
          Expanded(
            child: _loading
                ? const _GeneratingView()
                : _pdfBytes == null
                    ? const Center(
                        child: Text(
                          'Failed to generate PDF.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : PdfPreview(
                        build: (_) async => _pdfBytes!,
                        allowPrinting: true,
                        allowSharing: true,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        pdfFileName:
                            '${widget.certificate.certificateId}.pdf',
                      ),
          ),

          // QR verification section
          if (widget.certificate.qrToken != null && !_loading)
            _QrSection(certificate: widget.certificate),
        ],
      ),
    );
  }
}

class _GeneratingView extends StatelessWidget {
  const _GeneratingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Generating certificate PDF…',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _QrSection extends StatelessWidget {
  const _QrSection({required this.certificate});
  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    final url = CertificateRepository.verificationUrl(certificate);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          QrImageView(
            data: url,
            version: QrVersions.auto,
            size: 72,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan to Verify',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Anyone can scan this QR code to verify the authenticity of this certificate.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  certificate.certificateId,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
