import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/certificate_models.dart';
import 'certificate_pdf_service.dart';

class CertificateFileService {
  const CertificateFileService._();

  /// Generate the PDF bytes for [certificate].
  static Future<Uint8List> buildPdf({
    required Certificate certificate,
    required String recipientName,
  }) =>
      CertificatePdfService.generateCertificatePdf(
        certificate: certificate,
        recipientName: recipientName,
      );

  /// Open a system print/preview dialog with the certificate PDF.
  static Future<void> printOrPreview({
    required Certificate certificate,
    required String recipientName,
  }) async {
    final bytes = await buildPdf(
        certificate: certificate, recipientName: recipientName);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Share the certificate PDF via the native share sheet.
  /// On web, falls back to the print/download dialog.
  static Future<void> sharePdf({
    required Certificate certificate,
    required String recipientName,
  }) async {
    final bytes = await buildPdf(
        certificate: certificate, recipientName: recipientName);

    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: '${certificate.certificateId}.pdf',
        ),
      ],
      subject:
          '${certificate.certificateType.displayName} — Punjabi Welfare Trust',
      text: 'Verify at: ${certificate.qrToken ?? ""}',
    );
  }

  /// Save PDF to the device documents folder and return the path.
  /// Returns null on web (browser handles downloads via [printOrPreview]).
  static Future<String?> savePdf({
    required Certificate certificate,
    required String recipientName,
  }) async {
    if (kIsWeb) return null;
    try {
      final bytes = await buildPdf(
          certificate: certificate, recipientName: recipientName);
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${certificate.certificateId}.pdf';
      await XFile.fromData(bytes,
              mimeType: 'application/pdf',
              name: '${certificate.certificateId}.pdf')
          .saveTo(path);
      return path;
    } catch (e) {
      debugPrint('CertificateFileService.savePdf: $e');
      return null;
    }
  }

  /// Save already-generated PDF bytes to the device documents folder.
  /// Returns the saved file path, or null on web / on error.
  static Future<String?> savePdfBytes(
    Uint8List bytes, {
    required String filename,
  }) async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$filename';
      await XFile.fromData(bytes, mimeType: 'application/pdf', name: filename)
          .saveTo(path);
      return path;
    } catch (e) {
      debugPrint('CertificateFileService.savePdfBytes: $e');
      return null;
    }
  }

  /// Open an already-saved PDF with the device's default viewer. No-op on web.
  static Future<void> openFile(String filePath) async {
    if (kIsWeb) return;
    await OpenFilex.open(filePath);
  }

  /// Return raw PDF bytes without saving.
  static Future<Uint8List> getPdfBytes({
    required Certificate certificate,
    required String recipientName,
  }) =>
      buildPdf(certificate: certificate, recipientName: recipientName);
}
