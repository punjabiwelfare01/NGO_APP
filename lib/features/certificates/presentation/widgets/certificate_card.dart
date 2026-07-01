import 'package:flutter/material.dart';

import '../../../../core/colors.dart';
import '../../../../models/certificate_models.dart';
import 'certificate_status_badge.dart';

class CertificateCard extends StatelessWidget {
  const CertificateCard({
    required this.certificate,
    this.onTap,
    this.onGenerate,
    this.showStudentName = false,
    super.key,
  });

  final Certificate certificate;
  final VoidCallback? onTap;
  final VoidCallback? onGenerate;
  final bool showStudentName;

  @override
  Widget build(BuildContext context) {
    final canGenerate = certificate.status.canGeneratePdf;
    final isActive = certificate.status.isActive;
    final headerColor = _headerColor(certificate.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: headerColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gradient header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    headerColor,
                    headerColor.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificate.certificateType.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          certificate.certificateId,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (certificate.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
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
                            size: 11,
                            color: Colors.white,
                          ),
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
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showStudentName && certificate.studentName != null)
                    _InfoRow(
                      label: 'Student',
                      value: certificate.studentName!,
                    ),
                  _InfoRow(
                    label: 'Activity',
                    value: certificate.activityName,
                  ),
                  if (certificate.duration != null)
                    _InfoRow(label: 'Duration', value: certificate.duration!),
                  if (certificate.signatoryName != null)
                    _InfoRow(
                      label: 'Signed By',
                      value: [
                        certificate.signatoryName!,
                        if (certificate.signatoryTitle != null)
                          certificate.signatoryTitle!,
                      ].join(', '),
                    ),
                  if (certificate.issueDate != null)
                    _InfoRow(
                      label: 'Issue Date',
                      value: _formatDate(certificate.issueDate!),
                    ),
                  if (certificate.rejectionReason != null)
                    _InfoRow(
                      label: 'Reason',
                      value: certificate.rejectionReason!,
                      valueColor: AppColors.softRed,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CertificateStatusBadge(status: certificate.status),
                      const Spacer(),
                      if (canGenerate && isActive && onGenerate != null)
                        _ActionButton(
                          icon: Icons.picture_as_pdf_rounded,
                          label: certificate.status == CertificateStatus.generated
                              ? 'Re-generate'
                              : 'Generate PDF',
                          color: const Color(0xFF1976D2),
                          onTap: onGenerate!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _headerColor(CertificateStatus s) => switch (s) {
    CertificateStatus.issued    => const Color(0xFF2E7D32),
    CertificateStatus.approved  => const Color(0xFF1565C0),
    CertificateStatus.generated => const Color(0xFF1976D2),
    CertificateStatus.pending   => const Color(0xFFE65100),
    CertificateStatus.pending_signature => const Color(0xFF6A1B9A),
    CertificateStatus.signed    => const Color(0xFF6A1B9A),
    CertificateStatus.rejected  => const Color(0xFFC62828),
    CertificateStatus.revoked   => const Color(0xFF616161),
    CertificateStatus.downloaded => const Color(0xFF00695C),
    CertificateStatus.draft      => AppColors.muted,
  };

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label:',
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
                color: valueColor ?? AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
