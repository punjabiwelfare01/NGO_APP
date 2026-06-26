import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../models/certificate_models.dart';
import '../../../repositories/certificate_repository.dart';

class CertificatePdfService {
  const CertificatePdfService._();

  static Future<Uint8List> generateCertificatePdf({
    required Certificate certificate,
    required String recipientName,
  }) async {
    final pdf = pw.Document();

    // Load NGO logo
    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assests/ngo_logo.jpeg');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {
      // Logo unavailable — proceed without it
    }

    // Generate QR code image
    Uint8List? qrBytes;
    if (certificate.qrToken != null) {
      final verificationUrl =
          CertificateRepository.verificationUrl(certificate);
      qrBytes = await _renderQrToPng(verificationUrl, 180);
    }

    final issueDate = certificate.issueDate ?? DateTime.now();
    final issueDateStr =
        '${issueDate.day.toString().padLeft(2, '0')} '
        '${_monthName(issueDate.month)} '
        '${issueDate.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildCertificatePage(
          context: context,
          certificate: certificate,
          recipientName: recipientName,
          issueDateStr: issueDateStr,
          logoBytes: logoBytes,
          qrBytes: qrBytes,
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCertificatePage({
    required pw.Context context,
    required Certificate certificate,
    required String recipientName,
    required String issueDateStr,
    Uint8List? logoBytes,
    Uint8List? qrBytes,
  }) {
    const primaryBlue = PdfColor.fromInt(0xFF41A7F5);
    const darkBlue = PdfColor.fromInt(0xFF0D47A1);
    const gold = PdfColor.fromInt(0xFFD4A017);
    const ink = PdfColor.fromInt(0xFF17324D);
    const lightGrey = PdfColor.fromInt(0xFFF5F8FF);

    final pageW = PdfPageFormat.a4.landscape.availableWidth +
        PdfPageFormat.a4.landscape.marginLeft +
        PdfPageFormat.a4.landscape.marginRight;
    final pageH = PdfPageFormat.a4.landscape.availableHeight +
        PdfPageFormat.a4.landscape.marginTop +
        PdfPageFormat.a4.landscape.marginBottom;

    return pw.Stack(
      children: [
        // Background
        pw.Positioned.fill(
          child: pw.Container(color: PdfColors.white),
        ),
        // Top colour band
        pw.Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: pw.Container(
            height: pageH * 0.08,
            color: darkBlue,
          ),
        ),
        // Bottom colour band
        pw.Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: pw.Container(
            height: pageH * 0.06,
            color: darkBlue,
          ),
        ),
        // Left accent stripe
        pw.Positioned(
          top: pageH * 0.08,
          bottom: pageH * 0.06,
          left: 0,
          child: pw.Container(width: 10, color: gold),
        ),
        // Right accent stripe
        pw.Positioned(
          top: pageH * 0.08,
          bottom: pageH * 0.06,
          right: 0,
          child: pw.Container(width: 10, color: gold),
        ),
        // Outer border inside stripes
        pw.Positioned(
          top: pageH * 0.08,
          bottom: pageH * 0.06,
          left: 10,
          right: 10,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryBlue, width: 2),
            ),
          ),
        ),
        // Main content
        pw.Positioned.fill(
          child: pw.Padding(
            padding: pw.EdgeInsets.only(
              top: pageH * 0.09,
              bottom: pageH * 0.08,
              left: 30,
              right: 30,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header row: logo + org name
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (logoBytes != null) ...[
                      pw.Image(
                        pw.MemoryImage(logoBytes),
                        width: 52,
                        height: 52,
                        fit: pw.BoxFit.contain,
                      ),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'PUNJABI WELFARE TRUST',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.Text(
                          'Empowering Communities Through Service',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Gold divider line
                pw.Container(height: 1.5, color: gold, width: pageW * 0.6),
                pw.SizedBox(height: 6),

                // Certificate title
                pw.Text(
                  certificate.certificateType.templateTitle.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: gold,
                    letterSpacing: 3,
                  ),
                ),

                pw.SizedBox(height: 6),
                pw.Container(height: 1.5, color: gold, width: pageW * 0.6),
                pw.SizedBox(height: 16),

                // "This is to certify that"
                pw.Text(
                  'This is to certify that',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: ink,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Recipient name
                pw.Text(
                  recipientName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: darkBlue,
                    letterSpacing: 2,
                  ),
                ),

                pw.SizedBox(height: 10),

                // Activity description
                pw.Text(
                  'has successfully completed',
                  style: pw.TextStyle(fontSize: 12, color: ink),
                ),
                pw.SizedBox(height: 8),

                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: lightGrey,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(
                      color: primaryBlue,
                      width: 0.5,
                    ),
                  ),
                  child: pw.Text(
                    certificate.activityName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: ink,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                if (certificate.duration != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Duration: ${certificate.duration}',
                    style: pw.TextStyle(fontSize: 10, color: ink),
                  ),
                ],

                pw.SizedBox(height: 10),
                pw.Text(
                  'Issued on: $issueDateStr',
                  style: pw.TextStyle(fontSize: 10, color: ink),
                ),

                pw.Spacer(),

                // Footer row: signatory + cert ID + QR
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Signatory block
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 120, height: 0.8, color: ink),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          certificate.signatoryName ?? 'Authorized Signatory',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        if (certificate.signatoryTitle != null)
                          pw.Text(
                            certificate.signatoryTitle!,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                        pw.Text(
                          'Punjabi Welfare Trust',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),

                    // Certificate ID
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Certificate ID',
                          style: pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.grey600,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.Text(
                          certificate.certificateId,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        if (certificate.isVerified) ...[
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0xFF70D98B),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              'VERIFIED',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                letterSpacing: 1,
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
                          pw.Image(
                            pw.MemoryImage(qrBytes),
                            width: 68,
                            height: 68,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Scan to Verify',
                            style: pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      )
                    else
                      pw.SizedBox(width: 68),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Renders a QR code string to PNG bytes using QrPainter + Canvas.
  static Future<Uint8List> _renderQrToPng(String data, double size) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: false,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size, size),
    );
    painter.paint(canvas, Size(size, size));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static String _monthName(int month) => const [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ][month];
}
