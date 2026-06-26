import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/certificate_models.dart';
import 'certificate_pdf_service.dart';

class CertificateFileService {
  const CertificateFileService._();

  /// Generate the PDF bytes for [certificate], using [recipientName] on the design.
  static Future<Uint8List> buildPdf({
    required Certificate certificate,
    required String recipientName,
  }) =>
      CertificatePdfService.generateCertificatePdf(
        certificate: certificate,
        recipientName: recipientName,
      );

  /// Save PDF to device Downloads/Documents and return the saved file path.
  static Future<String?> savePdf({
    required Certificate certificate,
    required String recipientName,
  }) async {
    try {
      final bytes = await buildPdf(
        certificate: certificate,
        recipientName: recipientName,
      );
      final file = await _writeToFile(certificate.certificateId, bytes);
      return file.path;
    } catch (e) {
      debugPrint('CertificateFileService.savePdf error: $e');
      return null;
    }
  }

  /// Open a system print/preview dialog with the certificate PDF.
  static Future<void> printOrPreview({
    required Certificate certificate,
    required String recipientName,
  }) async {
    final bytes = await buildPdf(
      certificate: certificate,
      recipientName: recipientName,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Share the certificate PDF via the native share sheet.
  static Future<void> sharePdf({
    required Certificate certificate,
    required String recipientName,
  }) async {
    final bytes = await buildPdf(
      certificate: certificate,
      recipientName: recipientName,
    );
    final file = await _writeToFile(certificate.certificateId, bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: '${certificate.certificateType.displayName} — Punjabi Welfare Trust',
        text: 'Verify this certificate at: ${certificate.qrToken ?? ""}',
      ),
    );
  }

  /// Open an already-saved PDF file with the device's default PDF viewer.
  static Future<void> openFile(String filePath) async {
    await OpenFilex.open(filePath);
  }

  /// Return the PDF bytes without saving, useful for Printing.layoutPdf.
  static Future<Uint8List> getPdfBytes({
    required Certificate certificate,
    required String recipientName,
  }) =>
      buildPdf(certificate: certificate, recipientName: recipientName);

  // ── Internals ─────────────────────────────────────────────────────────────

  static Future<File> _writeToFile(
    String certificateId,
    Uint8List bytes,
  ) async {
    final Directory dir = kIsWeb
        ? Directory.systemTemp
        : (Platform.isAndroid
            ? (await getExternalStorageDirectory() ??
                await getApplicationDocumentsDirectory())
            : await getApplicationDocumentsDirectory());

    final path = '${dir.path}/$certificateId.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }
}
