import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../models/certificate_models.dart';
import '../../../models/ngo_profile.dart';
import '../../../repositories/certificate_repository.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavy    = PdfColor.fromInt(0xFF0A1F44);
const _kBlue    = PdfColor.fromInt(0xFF0D47A1);
const _kGold    = PdfColor.fromInt(0xFFD4A017);
const _kMuted   = PdfColor.fromInt(0xFF78909C);
const _kLightBg = PdfColor.fromInt(0xFFE3F2FD);
const _kWhite   = PdfColors.white;


class CertificatePdfService {
  const CertificatePdfService._();

  static Future<Uint8List> generateCertificatePdf({
    required Certificate certificate,
    required String recipientName,
    NGOProfile? ngoProfile,
    Uint8List? signatureBytes,
  }) async {
    final ngo = ngoProfile ?? NGOProfile.fallback;
    final pdf = pw.Document();

    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assests/ngo_logo.jpeg');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {}

    Uint8List? qrBytes;
    if (certificate.qrToken != null) {
      qrBytes = await _renderQrToPng(
        CertificateRepository.verificationUrl(certificate),
        200,
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // portrait
        margin: pw.EdgeInsets.zero,
        build: (_) => _buildPage(
          certificate: certificate,
          recipientName: recipientName,
          issueDateStr: _fmtDate(certificate.issueDate ?? DateTime.now()),
          logoBytes: logoBytes,
          qrBytes: qrBytes,
          signatureBytes: signatureBytes,
          ngo: ngo,
        ),
      ),
    );
    return pdf.save();
  }

  // ── Page ─────────────────────────────────────────────────────────────────────

  static pw.Widget _buildPage({
    required Certificate certificate,
    required String recipientName,
    required String issueDateStr,
    required NGOProfile ngo,
    Uint8List? logoBytes,
    Uint8List? qrBytes,
    Uint8List? signatureBytes,
  }) {
    const pad = 30.0;

    return pw.Stack(
      children: [
        // White background
        pw.Positioned.fill(child: pw.Container(color: _kWhite)),

        // Gold border frame
        pw.Positioned(
          top: 10, left: 10, right: 10, bottom: 10,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _kGold, width: 2.5),
            ),
          ),
        ),

        // Blue swoosh — top right corner
        pw.Positioned(
          top: 0, right: 0,
          child: pw.Container(
            width: 195, height: 135,
            decoration: pw.BoxDecoration(
              color: _kBlue,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: const pw.Radius.circular(175),
              ),
            ),
          ),
        ),

        // Blue wave — bottom left corner
        pw.Positioned(
          bottom: 0, left: 0,
          child: pw.Container(
            width: 165, height: 110,
            decoration: pw.BoxDecoration(
              color: _kBlue,
              borderRadius: pw.BorderRadius.only(
                topRight: const pw.Radius.circular(145),
              ),
            ),
          ),
        ),

        // Main content
        pw.Positioned(
          top: pad, left: pad, right: pad, bottom: pad,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              _header(ngo: ngo, logoBytes: logoBytes),
              pw.SizedBox(height: 10),
              // Gold divider
              _goldDivider(),
              pw.SizedBox(height: 10),
              // Certificate title
              _title(certificate: certificate),
              pw.SizedBox(height: 12),
              // Body
              _body(
                certificate: certificate,
                recipientName: recipientName,
                issueDateStr: issueDateStr,
              ),
              pw.Spacer(),
              // Footer
              _footer(
                certificate: certificate,
                ngo: ngo,
                qrBytes: qrBytes,
                signatureBytes: signatureBytes,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  static pw.Widget _header({required NGOProfile ngo, Uint8List? logoBytes}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoBytes != null) ...[
          pw.Container(
            width: 52, height: 52,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _kGold, width: 1.5),
            ),
            child: pw.ClipOval(
              child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(width: 14),
        ],
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              ngo.name.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _kNavy,
                letterSpacing: 1.5,
              ),
            ),
            if (ngo.tagline != null)
              pw.Text(
                ngo.tagline!,
                style: pw.TextStyle(fontSize: 9, color: _kMuted),
              ),
            if (ngo.registrationNumber != null)
              pw.Text(
                'Reg. No: ${ngo.registrationNumber}',
                style: pw.TextStyle(fontSize: 8, color: _kGold),
              ),
          ],
        ),
      ],
    );
  }

  // ── Divider ──────────────────────────────────────────────────────────────────

  static pw.Widget _goldDivider() => pw.Container(
        height: 1,
        decoration: const pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [PdfColors.white, _kGold, PdfColors.white],
          ),
        ),
      );

  // ── Title ────────────────────────────────────────────────────────────────────

  static pw.Widget _title({required Certificate certificate}) {
    final parts = certificate.certificateType.templateTitle.split(' ');
    final subtitle = parts.skip(1).join(' ').toUpperCase();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'CERTIFICATE',
          style: pw.TextStyle(
            fontSize: 44,
            fontWeight: pw.FontWeight.bold,
            color: _kGold,
            letterSpacing: 4,
          ),
        ),
        pw.Text(
          subtitle,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _kBlue,
            letterSpacing: 2.5,
          ),
        ),
        pw.SizedBox(height: 8),
        // Ornamental lines
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(width: 70, height: 0.8, color: _kGold),
            pw.SizedBox(width: 8),
            pw.Container(width: 5, height: 5, decoration: const pw.BoxDecoration(color: _kGold, shape: pw.BoxShape.circle)),
            pw.SizedBox(width: 8),
            pw.Container(width: 70, height: 0.8, color: _kGold),
          ],
        ),
      ],
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────────

  static pw.Widget _body({
    required Certificate certificate,
    required String recipientName,
    required String issueDateStr,
  }) {
    final roleText = certificate.studentRole ?? 'Volunteer';
    final workText = certificate.workDescription?.isNotEmpty == true
        ? certificate.workDescription!
        : 'appreciative work and dedication in contribution';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'This is to certify that',
          style: pw.TextStyle(fontSize: 11, color: _kMuted, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          recipientName.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 34,
            fontWeight: pw.FontWeight.bold,
            color: _kNavy,
            letterSpacing: 2,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          roleText,
          style: pw.TextStyle(fontSize: 11, color: _kMuted, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'has successfully completed',
          style: pw.TextStyle(fontSize: 11, color: _kNavy),
        ),
        pw.SizedBox(height: 12),
        // Activity box
        pw.Container(
          constraints: const pw.BoxConstraints(maxWidth: 340),
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: pw.BoxDecoration(
            color: _kLightBg,
            border: pw.Border.all(color: _kBlue, width: 0.8),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                certificate.activityName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _kBlue,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (certificate.eventName != null) ...[
                pw.SizedBox(height: 3),
                pw.Text(certificate.eventName!,
                    style: pw.TextStyle(fontSize: 9, color: _kMuted),
                    textAlign: pw.TextAlign.center),
              ],
              if (certificate.programName != null) ...[
                pw.SizedBox(height: 2),
                pw.Text('Programme: ${certificate.programName}',
                    style: pw.TextStyle(fontSize: 9, color: _kMuted),
                    textAlign: pw.TextAlign.center),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          workText,
          style: pw.TextStyle(fontSize: 9, color: _kMuted, fontStyle: pw.FontStyle.italic),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 14),
        // Stats chips row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (certificate.serviceHours != null) ...[
              _chip(
                'SERVICE HOURS',
                '${certificate.serviceHours!.toStringAsFixed(certificate.serviceHours! % 1 == 0 ? 0 : 1)} hrs',
              ),
              pw.SizedBox(width: 14),
            ],
            if (certificate.startDate != null && certificate.endDate != null) ...[
              _chip(
                'PERIOD',
                '${_fmtDate(certificate.startDate!)} – ${_fmtDate(certificate.endDate!)}',
              ),
              pw.SizedBox(width: 14),
            ],
            _chip('ISSUE DATE', issueDateStr),
          ],
        ),
      ],
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────

  static pw.Widget _footer({
    required Certificate certificate,
    required NGOProfile ngo,
    Uint8List? qrBytes,
    Uint8List? signatureBytes,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Signature block
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (signatureBytes != null)
              pw.Image(pw.MemoryImage(signatureBytes), width: 100, height: 40, fit: pw.BoxFit.contain)
            else
              pw.Text(
                certificate.signatoryName ?? 'Authorized Signatory',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                  color: _kNavy,
                ),
              ),
            pw.Container(width: 130, height: 1, color: _kGold),
            pw.SizedBox(height: 4),
            pw.Text(
              certificate.signatoryName ?? 'Authorized Signatory',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kNavy),
            ),
            if (certificate.signatoryTitle != null)
              pw.Text(certificate.signatoryTitle!,
                  style: pw.TextStyle(fontSize: 8, color: _kMuted)),
            pw.Text(ngo.name, style: pw.TextStyle(fontSize: 8, color: _kMuted)),
            if (ngo.email != null)
              pw.Text(ngo.email!, style: pw.TextStyle(fontSize: 7, color: _kMuted)),
            if (ngo.phone != null)
              pw.Text('Ph: ${ngo.phone!}', style: pw.TextStyle(fontSize: 7, color: _kMuted)),
          ],
        ),

        // Certificate ID + laurel
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'CERTIFICATE ID',
              style: pw.TextStyle(
                fontSize: 7, color: _kMuted, letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              certificate.certificateId,
              style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kGold,
              ),
            ),
            if (certificate.isVerified) ...[
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF2E7D32),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'VERIFIED',
                  style: pw.TextStyle(
                    fontSize: 7, fontWeight: pw.FontWeight.bold,
                    color: _kWhite, letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),

        // QR code
        if (qrBytes != null)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(pw.MemoryImage(qrBytes), width: 72, height: 72),
              pw.SizedBox(height: 3),
              pw.Text('Scan to Verify',
                  style: pw.TextStyle(fontSize: 7, color: _kMuted)),
            ],
          )
        else
          pw.SizedBox(width: 72),
      ],
    );
  }

  // ── Chip ─────────────────────────────────────────────────────────────────────

  static pw.Widget _chip(String label, String value) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: pw.BoxDecoration(
          color: _kWhite,
          border: pw.Border.all(color: _kBlue, width: 0.6),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 7, color: _kMuted, letterSpacing: 0.5),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kNavy,
              ),
            ),
          ],
        ),
      );

  // ── QR rendering ─────────────────────────────────────────────────────────────

  static Future<Uint8List> _renderQrToPng(String data, double size) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: false,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF000000)),
      dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square, color: Color(0xFF000000)),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    painter.paint(canvas, Size(size, size));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static String _fmtDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}
