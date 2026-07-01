import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../models/certificate_models.dart';
import '../../../../models/ngo_profile.dart';
import '../../../../repositories/certificate_repository.dart';

class CertificateVisualCard extends StatelessWidget {
  const CertificateVisualCard({
    required this.certificate,
    required this.recipientName,
    required this.ngo,
    super.key,
  });

  final Certificate certificate;
  final String recipientName;
  final NGOProfile ngo;

  static const _navy     = Color(0xFF0A1F44);
  static const _blue     = Color(0xFF0D47A1);
  static const _gold     = Color(0xFFD4A017);
  static const _muted    = Color(0xFF78909C);
  static const _lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = w * (842 / 595); // A4 portrait
      return SizedBox(
        width: w,
        height: h,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _gold, width: 2.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Blue swoosh — top right corner
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: w * 0.34,
                    height: h * 0.14,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(w * 0.30),
                      ),
                    ),
                  ),
                ),
                // Blue wave — bottom left corner
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: w * 0.28,
                    height: h * 0.09,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(w * 0.24),
                      ),
                    ),
                  ),
                ),
                // Main content
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.03, w * 0.06, h * 0.025),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Header(ngo: ngo, w: w, h: h),
                        SizedBox(height: h * 0.014),
                        _GoldDivider(w: w),
                        SizedBox(height: h * 0.012),
                        _Title(certificate: certificate, w: w, h: h),
                        SizedBox(height: h * 0.010),
                        _Body(certificate: certificate, recipientName: recipientName, w: w, h: h),
                        const Spacer(),
                        _Footer(certificate: certificate, ngo: ngo, w: w, h: h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ngo, required this.w, required this.h});
  final NGOProfile ngo;
  final double w, h;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: w * 0.13,
          height: w * 0.13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CertificateVisualCard._gold, width: 1.5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(
            'assests/ngo_logo.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.account_balance, color: CertificateVisualCard._blue),
            ),
          ),
        ),
        SizedBox(width: w * 0.035),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ngo.name.toUpperCase(),
                style: TextStyle(
                  fontSize: w * 0.042,
                  fontWeight: FontWeight.w900,
                  color: CertificateVisualCard._navy,
                  letterSpacing: 0.8,
                ),
              ),
              if (ngo.tagline != null)
                Text(
                  ngo.tagline!,
                  style: TextStyle(
                    fontSize: w * 0.027,
                    color: CertificateVisualCard._muted,
                  ),
                ),
              if (ngo.registrationNumber != null)
                Text(
                  'Reg. No: ${ngo.registrationNumber}',
                  style: TextStyle(
                    fontSize: w * 0.024,
                    color: CertificateVisualCard._gold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, CertificateVisualCard._gold, Colors.transparent],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.certificate, required this.w, required this.h});
  final Certificate certificate;
  final double w, h;

  @override
  Widget build(BuildContext context) {
    final parts = certificate.certificateType.templateTitle.split(' ');
    final subtitle = parts.skip(1).join(' ').toUpperCase();
    return Column(
      children: [
        Text(
          'CERTIFICATE',
          style: TextStyle(
            fontSize: w * 0.092,
            fontWeight: FontWeight.w900,
            color: CertificateVisualCard._gold,
            letterSpacing: 3.5,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: w * 0.036,
            fontWeight: FontWeight.w700,
            color: CertificateVisualCard._blue,
            letterSpacing: 2.0,
          ),
        ),
        SizedBox(height: h * 0.008),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: w * 0.14, height: 0.8, color: CertificateVisualCard._gold),
            SizedBox(width: w * 0.02),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: CertificateVisualCard._gold,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: w * 0.02),
            Container(width: w * 0.14, height: 0.8, color: CertificateVisualCard._gold),
          ],
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.certificate,
    required this.recipientName,
    required this.w,
    required this.h,
  });
  final Certificate certificate;
  final String recipientName;
  final double w, h;

  @override
  Widget build(BuildContext context) {
    final roleText = certificate.studentRole ?? 'Volunteer';
    final workText = certificate.workDescription?.isNotEmpty == true
        ? certificate.workDescription!
        : 'appreciative work and dedication in contribution';

    return Column(
      children: [
        Text(
          'This is to certify that',
          style: TextStyle(
            fontSize: w * 0.030,
            color: CertificateVisualCard._muted,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: h * 0.007),
        Text(
          recipientName.toUpperCase(),
          style: TextStyle(
            fontSize: w * 0.085,
            fontWeight: FontWeight.w900,
            color: CertificateVisualCard._navy,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: h * 0.004),
        Text(
          roleText,
          style: TextStyle(
            fontSize: w * 0.028,
            color: CertificateVisualCard._muted,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: h * 0.008),
        Text(
          'has successfully completed',
          style: TextStyle(fontSize: w * 0.028, color: CertificateVisualCard._navy),
        ),
        SizedBox(height: h * 0.012),
        // Activity box
        Container(
          constraints: BoxConstraints(maxWidth: w * 0.80),
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
          decoration: BoxDecoration(
            color: CertificateVisualCard._lightBlue,
            border: Border.all(
              color: CertificateVisualCard._blue.withValues(alpha: 0.5),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.campaign_rounded, size: w * 0.055, color: CertificateVisualCard._blue),
              SizedBox(width: w * 0.025),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certificate.activityName,
                      style: TextStyle(
                        fontSize: w * 0.034,
                        fontWeight: FontWeight.w800,
                        color: CertificateVisualCard._blue,
                      ),
                    ),
                    if (certificate.eventName != null)
                      Text(
                        certificate.eventName!,
                        style: TextStyle(
                          fontSize: w * 0.027,
                          color: CertificateVisualCard._muted,
                        ),
                      ),
                    if (certificate.programName != null)
                      Text(
                        'Programme: ${certificate.programName}',
                        style: TextStyle(
                          fontSize: w * 0.025,
                          color: CertificateVisualCard._muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: h * 0.010),
        Text(
          workText,
          style: TextStyle(
            fontSize: w * 0.026,
            color: CertificateVisualCard._muted,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: h * 0.016),
        // Stats row
        Wrap(
          spacing: w * 0.025,
          runSpacing: h * 0.008,
          alignment: WrapAlignment.center,
          children: [
            if (certificate.serviceHours != null)
              _StatChip(
                label: 'SERVICE HOURS',
                value:
                    '${certificate.serviceHours!.toStringAsFixed(certificate.serviceHours! % 1 == 0 ? 0 : 1)} hrs',
                icon: Icons.access_time_rounded,
                w: w,
              ),
            if (certificate.startDate != null && certificate.endDate != null)
              _StatChip(
                label: 'PERIOD',
                value:
                    '${_fmt(certificate.startDate!)} – ${_fmt(certificate.endDate!)}',
                icon: Icons.calendar_today_rounded,
                w: w,
              ),
            _StatChip(
              label: 'ISSUE DATE',
              value: _fmt(certificate.issueDate ?? DateTime.now()),
              icon: Icons.calendar_month_rounded,
              w: w,
            ),
          ],
        ),
      ],
    );
  }

  static String _fmt(DateTime d) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.w,
  });
  final String label;
  final String value;
  final IconData icon;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.028, vertical: w * 0.018),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF1565C0), width: 0.6),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: w * 0.030, color: const Color(0xFF1565C0)),
              SizedBox(width: w * 0.010),
              Text(
                label,
                style: TextStyle(
                  fontSize: w * 0.022,
                  color: const Color(0xFF78909C),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.010),
          Text(
            value,
            style: TextStyle(
              fontSize: w * 0.026,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0A1F44),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.certificate,
    required this.ngo,
    required this.w,
    required this.h,
  });
  final Certificate certificate;
  final NGOProfile ngo;
  final double w, h;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Signature block
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              certificate.signatoryName ?? 'Authorized Signatory',
              style: TextStyle(
                fontSize: w * 0.038,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: CertificateVisualCard._navy,
              ),
            ),
            Container(width: w * 0.26, height: 1, color: CertificateVisualCard._gold),
            SizedBox(height: h * 0.005),
            Text(
              certificate.signatoryName ?? 'Authorized Signatory',
              style: TextStyle(
                fontSize: w * 0.025,
                fontWeight: FontWeight.w800,
                color: CertificateVisualCard._navy,
              ),
            ),
            if (certificate.signatoryTitle != null)
              Text(
                certificate.signatoryTitle!,
                style: TextStyle(
                  fontSize: w * 0.023,
                  color: CertificateVisualCard._muted,
                ),
              ),
            Text(
              ngo.name,
              style: TextStyle(
                fontSize: w * 0.023,
                color: CertificateVisualCard._muted,
              ),
            ),
          ],
        ),

        // Certificate ID with laurel decoration
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('❧', style: TextStyle(color: CertificateVisualCard._gold, fontSize: w * 0.038)),
                SizedBox(width: w * 0.015),
                Text('❦', style: TextStyle(color: CertificateVisualCard._gold, fontSize: w * 0.038)),
              ],
            ),
            SizedBox(height: h * 0.003),
            Text(
              'CERTIFICATE ID',
              style: TextStyle(
                fontSize: w * 0.022,
                color: CertificateVisualCard._muted,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: h * 0.002),
            Text(
              certificate.certificateId,
              style: TextStyle(
                fontSize: w * 0.028,
                fontWeight: FontWeight.w900,
                color: CertificateVisualCard._gold,
              ),
            ),
          ],
        ),

        // QR code
        if (certificate.qrToken != null)
          Column(
            children: [
              QrImageView(
                data: CertificateRepository.verificationUrl(certificate),
                version: QrVersions.auto,
                size: w * 0.19,
              ),
              Text(
                'Scan to Verify',
                style: TextStyle(
                  fontSize: w * 0.022,
                  color: CertificateVisualCard._muted,
                ),
              ),
            ],
          )
        else
          SizedBox(width: w * 0.19),
      ],
    );
  }
}
