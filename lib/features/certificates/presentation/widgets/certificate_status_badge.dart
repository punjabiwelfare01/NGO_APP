import 'package:flutter/material.dart';

import '../../../../core/colors.dart';
import '../../../../models/certificate_models.dart';

class CertificateStatusBadge extends StatelessWidget {
  const CertificateStatusBadge({required this.status, super.key});
  final CertificateStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _attrs(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, IconData) _attrs(CertificateStatus s) => switch (s) {
    CertificateStatus.issued    => (AppColors.secondary, Icons.verified_rounded),
    CertificateStatus.approved  => (const Color(0xFF1976D2), Icons.check_circle_rounded),
    CertificateStatus.generated => (AppColors.primary, Icons.picture_as_pdf_rounded),
    CertificateStatus.pending   => (AppColors.accent, Icons.hourglass_top_rounded),
    CertificateStatus.pending_signature => (AppColors.accent, Icons.draw_rounded),
    CertificateStatus.signed    => (AppColors.primary, Icons.draw_rounded),
    CertificateStatus.rejected  => (AppColors.softRed, Icons.cancel_rounded),
    CertificateStatus.revoked   => (AppColors.softRed, Icons.block_rounded),
    CertificateStatus.draft     => (AppColors.muted, Icons.edit_rounded),
  };
}
