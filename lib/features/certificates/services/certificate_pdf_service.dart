import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../models/certificate_models.dart';
import '../../../models/ngo_profile.dart';
import '../../../repositories/api_client.dart';
import '../../../repositories/certificate_repository.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavy    = PdfColor.fromInt(0xFF0A1F44);
const _kBlue    = PdfColor.fromInt(0xFF0D47A1);
const _kGold    = PdfColor.fromInt(0xFFD4A017);
const _kMuted   = PdfColor.fromInt(0xFF78909C);
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

    // If the caller didn't pass raw signature bytes directly, fetch them
    // from the certificate's stored signature_url (set on the "Authorized
    // By" admin form) so a configured signature actually shows up on the
    // PDF instead of silently falling back to the signatory's typed name.
    final resolvedSignatureBytes = signatureBytes ??
        await _fetchImageBytes(certificate.signatureUrl);

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
          signatureBytes: resolvedSignatureBytes,
          ngo: ngo,
        ),
      ),
    );
    return pdf.save();
  }

  /// Resolves [url] (absolute, or a server-relative "/uploads/..." path) and
  /// downloads it, returning null on any failure so callers can fall back
  /// to the plain-text signatory name.
  static Future<Uint8List?> _fetchImageBytes(String? url) async {
    if (url == null || url.isEmpty) return null;
    final resolved = url.startsWith('http') ? url : '${ApiClient.baseUrl}$url';
    try {
      final response = await http.get(Uri.parse(resolved));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
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
                ngo: ngo,
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
            width: 66, height: 66,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _kGold, width: 2),
            ),
            child: pw.ClipOval(
              child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(width: 16),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                ngo.name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _kNavy,
                  letterSpacing: 1.8,
                ),
              ),
              if (ngo.tagline != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  ngo.tagline!,
                  style: pw.TextStyle(
                    fontSize: 9.5, color: _kMuted, fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
              pw.SizedBox(height: 5),
              pw.Row(
                children: [
                  _tagPill('REGISTERED NGO'),
                  if (ngo.registrationNumber != null) ...[
                    pw.SizedBox(width: 6),
                    _tagPill('REG. NO. ${ngo.registrationNumber}'),
                  ],
                ],
              ),
              pw.SizedBox(height: 5),
              if (ngo.address != null)
                pw.Text(
                  ngo.address!,
                  style: pw.TextStyle(fontSize: 7.5, color: _kMuted),
                ),
              pw.Row(
                children: [
                  if (ngo.email != null)
                    pw.Text(ngo.email!, style: pw.TextStyle(fontSize: 7.5, color: _kMuted)),
                  if (ngo.email != null && ngo.phone != null)
                    pw.Text('   |   ', style: pw.TextStyle(fontSize: 7.5, color: _kGold)),
                  if (ngo.phone != null)
                    pw.Text('Ph: ${ngo.phone!}', style: pw.TextStyle(fontSize: 7.5, color: _kMuted)),
                  if (ngo.website != null) ...[
                    pw.Text('   |   ', style: pw.TextStyle(fontSize: 7.5, color: _kGold)),
                    pw.Text(ngo.website!, style: pw.TextStyle(fontSize: 7.5, color: _kMuted)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Small bordered label used for trust badges in the header (e.g.
  /// "REGISTERED NGO", "REG. NO. 736").
  static pw.Widget _tagPill(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _kGold, width: 0.7),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: _kGold, letterSpacing: 0.6,
          ),
        ),
      );

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
    required NGOProfile ngo,
  }) {
    final roleText = certificate.studentRole ?? 'Volunteer';
    final workText = certificate.workDescription?.isNotEmpty == true
        ? certificate.workDescription!
        : null;
    final nameWidth = (recipientName.length * 15.0).clamp(160.0, 380.0);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'This certificate is proudly presented to',
          style: pw.TextStyle(fontSize: 11, color: _kMuted, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 10),
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
        pw.Container(width: nameWidth, height: 1.4, color: _kGold),
        pw.SizedBox(height: 6),
        pw.Text(
          roleText,
          style: pw.TextStyle(fontSize: 11, color: _kMuted, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 12),
        // Recognition paragraph
        pw.Container(
          constraints: const pw.BoxConstraints(maxWidth: 400),
          child: pw.Text(
            'In recognition of exceptional dedication, valuable contribution, and unwavering '
            'commitment to community service rendered through ${ngo.name}.',
            style: pw.TextStyle(fontSize: 11, color: _kNavy, lineSpacing: 2),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 16),
        // Activity section — a formal information block, not a UI button.
        pw.Container(
          constraints: const pw.BoxConstraints(maxWidth: 380),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(width: 40, height: 0.8, color: _kGold),
              pw.SizedBox(height: 6),
              pw.Text(
                'VOLUNTEER ACTIVITY',
                style: pw.TextStyle(
                  fontSize: 8, color: _kMuted, letterSpacing: 1.8, fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                _titleCase(certificate.activityName),
                style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold, color: _kNavy,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (certificate.programName != null) ...[
                pw.SizedBox(height: 3),
                pw.Text(certificate.programName!,
                    style: pw.TextStyle(fontSize: 10, color: _kBlue, fontStyle: pw.FontStyle.italic),
                    textAlign: pw.TextAlign.center),
              ],
              if (certificate.eventName != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(certificate.eventName!,
                    style: pw.TextStyle(fontSize: 9, color: _kMuted),
                    textAlign: pw.TextAlign.center),
              ],
              pw.SizedBox(height: 6),
              pw.Container(width: 40, height: 0.8, color: _kGold),
            ],
          ),
        ),
        if (workText != null) ...[
          pw.SizedBox(height: 12),
          pw.Container(
            constraints: const pw.BoxConstraints(maxWidth: 380),
            child: pw.Text(
              '"$workText"',
              style: pw.TextStyle(fontSize: 9.5, color: _kMuted, fontStyle: pw.FontStyle.italic),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
        pw.SizedBox(height: 18),
        // Achievement metrics — plain label/value groups with a divider,
        // not bordered dashboard-style cards.
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (certificate.serviceHours != null) ...[
              _stat(
                'SERVICE HOURS',
                '${certificate.serviceHours!.toStringAsFixed(certificate.serviceHours! % 1 == 0 ? 0 : 1)} hrs',
              ),
              _statDivider(),
            ],
            if (certificate.startDate != null && certificate.endDate != null) ...[
              _stat(
                'SERVICE PERIOD',
                '${_fmtDate(certificate.startDate!)} - ${_fmtDate(certificate.endDate!)}',
              ),
              _statDivider(),
            ],
            _stat('ISSUE DATE', issueDateStr),
          ],
        ),
      ],
    );
  }

  /// A label/value pair for the achievement-metrics row — plain text with
  /// no border, so it reads as certificate copy rather than a UI widget.
  static pw.Widget _stat(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7, color: _kMuted, letterSpacing: 1),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _kNavy),
          ),
        ],
      );

  static pw.Widget _statDivider() => pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 16),
        width: 0.7,
        height: 24,
        color: _kGold,
      );

  /// Capitalizes each word — admin-entered activity names are often typed
  /// lowercase; this is cosmetic capitalization only, not a rewrite.
  static String _titleCase(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return input;
    return trimmed.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      final lower = w.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');
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
        pw.Expanded(
          child: pw.Column(
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
            ],
          ),
        ),

        pw.SizedBox(width: 12),
        _sealBadge(ngo: ngo),
        pw.SizedBox(width: 12),

        // Verification block — QR, certificate ID and the verify URL live
        // together in one bordered section instead of floating separately.
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kGold, width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VERIFY CERTIFICATE',
                    style: pw.TextStyle(
                      fontSize: 6.5, color: _kMuted, letterSpacing: 1,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    certificate.certificateId,
                    style: pw.TextStyle(
                      fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _kGold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.ConstrainedBox(
                    constraints: const pw.BoxConstraints(maxWidth: 175),
                    child: pw.Text(
                      CertificateRepository.verificationUrl(certificate),
                      style: pw.TextStyle(fontSize: 5.5, color: _kMuted),
                      maxLines: 2,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ),
                  if (certificate.isVerified) ...[
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFF2E7D32),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'DIGITALLY VERIFIED',
                        style: pw.TextStyle(
                          fontSize: 6, fontWeight: pw.FontWeight.bold,
                          color: _kWhite, letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (qrBytes != null) ...[
                pw.SizedBox(width: 10),
                pw.Image(pw.MemoryImage(qrBytes), width: 58, height: 58),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// A simple drawn emblem (concentric rings + initials) standing in for a
  /// physical NGO seal — no seal artwork asset exists yet.
  static pw.Widget _sealBadge({required NGOProfile ngo}) {
    final initials = ngo.name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .take(3)
        .join();
    return pw.Container(
      width: 64, height: 64,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _kGold, width: 1.6),
      ),
      child: pw.Container(
        width: 54, height: 54,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: _kGold, width: 0.6),
          color: const PdfColor.fromInt(0xFFFBF3DD),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              initials,
              style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: _kGold, letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text('OFFICIAL', style: pw.TextStyle(fontSize: 4.5, color: _kNavy, letterSpacing: 0.8)),
            pw.Text('SEAL', style: pw.TextStyle(fontSize: 4.5, color: _kNavy, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

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
