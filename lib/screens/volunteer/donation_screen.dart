import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/donation_models.dart';
import '../../viewmodels/volunteer_viewmodel.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────

const _primary   = Color(0xFF1976D2);
const _secondary = Color(0xFF42A5F5);
const _bg        = Color(0xFFF7F9FC);
const _success   = Color(0xFFE8F5E9);
const _accent    = Color(0xFFFF6B6B);
const _ink       = Color(0xFF1A1A2E);

const _kCardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 8)),
];

// ── Bank / NGO constants ───────────────────────────────────────────────────────

const _kUpi    = 'punjabiwelfaretrust@upi';
const _kAcct   = '35270101011873';
const _kIfsc   = 'UBIN0535273';
const _kBank   = 'Union Bank of India';
const _kBranch = 'Delhi-Cantonment Branch, South West Delhi – 110010';
const _kHolder = 'Punjabi Welfare Trust';

// ── Screen ─────────────────────────────────────────────────────────────────────

class DonationScreen extends StatefulWidget {
  const DonationScreen({required this.vm, super.key});
  final VolunteerViewModel vm;

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  @override
  void initState() {
    super.initState();
    widget.vm.loadDonations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: _primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Donations',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. NGO hero
                const _NGOHeroCard(),
                const SizedBox(height: 18),

                // 2. 3-step flow
                const _StepFlowCard(),
                const SizedBox(height: 20),

                // 3. QR hero — the star of the page
                const _QRHeroCard(),
                const SizedBox(height: 22),

                // 4. OR divider
                const _OrDivider(),
                const SizedBox(height: 22),

                // 5. UPI ID card
                const _UPICard(),
                const SizedBox(height: 14),

                // 6. Bank details accordion
                const _BankAccordion(),
                const SizedBox(height: 14),

                // 7. Safety note
                const _SafetyCard(),
                const SizedBox(height: 24),

                // 8. Record donation CTA
                _RecordDonationButton(vm: widget.vm),

                // 9. Stipends
                if (widget.vm.stipends.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const _SectionLabel('My Stipends'),
                  const SizedBox(height: 12),
                  ...widget.vm.stipends.map((s) => _StipendTile(s)),
                ],

                // 10. History
                if (widget.vm.donations.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const _SectionLabel('Donation History'),
                  const SizedBox(height: 12),
                  ...widget.vm.donations.map((d) => _DonationTile(d)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── NGO Hero Card ──────────────────────────────────────────────────────────────

class _NGOHeroCard extends StatelessWidget {
  const _NGOHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assests/ngo_logo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Punjabi Welfare Trust',
                        style: TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Color(0xFF2E7D32), size: 10),
                          SizedBox(width: 3),
                          Text('Verified',
                              style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Support education by donating directly to the NGO.',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    height: 1.4,
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

// ── 3-Step Flow Card ───────────────────────────────────────────────────────────

class _StepFlowCard extends StatelessWidget {
  const _StepFlowCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _kCardShadow,
      ),
      child: Row(
        children: [
          _StepBubble(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR',
            number: '1',
          ),
          _StepConnector(),
          _StepBubble(
            icon: Icons.payments_rounded,
            label: 'Pay',
            number: '2',
          ),
          _StepConnector(),
          _StepBubble(
            icon: Icons.favorite_rounded,
            label: 'Record',
            number: '3',
            isOptional: true,
          ),
        ],
      ),
    );
  }
}

class _StepBubble extends StatelessWidget {
  const _StepBubble({
    required this.icon,
    required this.label,
    required this.number,
    this.isOptional = false,
  });
  final IconData icon;
  final String label;
  final String number;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), _secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          if (isOptional)
            Text(
              'Optional',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 2,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── QR Hero Card ───────────────────────────────────────────────────────────────

class _QRHeroCard extends StatefulWidget {
  const _QRHeroCard();

  @override
  State<_QRHeroCard> createState() => _QRHeroCardState();
}

class _QRHeroCardState extends State<_QRHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() => _zoomed = !_zoomed);
    _zoomed ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), _primary, _secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: Colors.white, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'SCAN TO DONATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── QR image ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
            child: GestureDetector(
              onTap: _toggleZoom,
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 240,
                    maxHeight: 290,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _primary.withValues(alpha: 0.10),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    'assests/new_donation_qr.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => SizedBox(
                      height: 240,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_rounded,
                                size: 130,
                                color: _primary.withValues(alpha: 0.35)),
                            const SizedBox(height: 8),
                            Text('QR not found',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Scan labels ───────────────────────────────────────────
          const Text(
            'Scan with any UPI app',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Google Pay  •  PhonePe  •  Paytm  •  BHIM',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap QR to zoom in',
            style: TextStyle(
              color: _primary.withValues(alpha: 0.55),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

// ── OR Divider ─────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.grey.shade300],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _kCardShadow,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'OR',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade300, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── UPI ID Card ────────────────────────────────────────────────────────────────

class _UPICard extends StatefulWidget {
  const _UPICard();

  @override
  State<_UPICard> createState() => _UPICardState();
}

class _UPICardState extends State<_UPICard> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(const ClipboardData(text: _kUpi));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPI ID',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smartphone_rounded,
                    color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  _kUpi,
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Animated copy button
              GestureDetector(
                onTap: _copy,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: _copied
                        ? const Color(0xFF2E7D32)
                        : _primary,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: (_copied
                                ? const Color(0xFF2E7D32)
                                : _primary)
                            .withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _copied
                        ? const Row(
                            key: ValueKey('ok'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text('Copied',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ],
                          )
                        : const Row(
                            key: ValueKey('cp'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text('Copy',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bank Details Accordion ─────────────────────────────────────────────────────

class _BankAccordion extends StatefulWidget {
  const _BankAccordion();

  @override
  State<_BankAccordion> createState() => _BankAccordionState();
}

class _BankAccordionState extends State<_BankAccordion> {
  bool _open = false;
  bool _acctCopied = false;
  bool _ifscCopied = false;

  Future<void> _copyField(String text, bool isAcct) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() {
      if (isAcct) { _acctCopied = true; }
      else { _ifscCopied = true; }
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        if (isAcct) { _acctCopied = false; }
        else { _ifscCopied = false; }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        children: [
          // ── Accordion header ─────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_rounded,
                        color: _primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Bank Details',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible body ─────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Column(
                    children: [
                      Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade100),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(
                          children: [
                            _BankRow(
                                label: 'Beneficiary', value: _kHolder),
                            _BankRow(label: 'Bank', value: _kBank),
                            _BankRow(label: 'Branch', value: _kBranch),
                            _BankRowCopy(
                              label: 'Account Number',
                              display: '••••••11873',
                              copyVal: _kAcct,
                              copied: _acctCopied,
                              onCopy: () => _copyField(_kAcct, true),
                            ),
                            _BankRowCopy(
                              label: 'IFSC Code',
                              display: _kIfsc,
                              copyVal: _kIfsc,
                              copied: _ifscCopied,
                              onCopy: () => _copyField(_kIfsc, false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankRowCopy extends StatelessWidget {
  const _BankRowCopy({
    required this.label,
    required this.display,
    required this.copyVal,
    required this.copied,
    required this.onCopy,
  });
  final String label;
  final String display;
  final String copyVal;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCopy,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: copied
                    ? _success
                    : _primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: copied
                    ? const Row(
                        key: ValueKey('y'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 11, color: Color(0xFF2E7D32)),
                          SizedBox(width: 3),
                          Text('✓',
                              style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ],
                      )
                    : const Row(
                        key: ValueKey('n'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 11, color: _primary),
                          SizedBox(width: 3),
                          Text('Copy',
                              style: TextStyle(
                                  color: _primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Safety Card ────────────────────────────────────────────────────────────────

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _success,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Color(0xFF2E7D32), size: 16),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donate only to the official NGO account.',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '100% of donations go directly to the NGO.\n'
                  'Never transfer money to personal accounts.',
                  style: TextStyle(
                    color: Color(0xFF388E3C),
                    fontSize: 11,
                    height: 1.5,
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

// ── Record Donation CTA ────────────────────────────────────────────────────────

class _RecordDonationButton extends StatelessWidget {
  const _RecordDonationButton({required this.vm});
  final VolunteerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => _DonationSheet(vm: vm),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_accent, Color(0xFFFF4757)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.42),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 21),
            SizedBox(width: 10),
            Text(
              'Record My Donation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Donation Bottom Sheet ──────────────────────────────────────────────────────

class _DonationSheet extends StatefulWidget {
  const _DonationSheet({required this.vm});
  final VolunteerViewModel vm;

  @override
  State<_DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends State<_DonationSheet> {
  DonationType _type   = DonationType.money;
  final _nameCtrl      = TextEditingController();
  final _mobileCtrl    = TextEditingController();
  final _amountCtrl    = TextEditingController();
  final _itemsCtrl     = TextEditingController();
  final _purposeCtrl   = TextEditingController();
  final _txnCtrl       = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _amountCtrl.dispose();
    _itemsCtrl.dispose();
    _purposeCtrl.dispose();
    _txnCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final result = await widget.vm.submitDonation(
      donorName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      donorMobile: _mobileCtrl.text.trim().isEmpty
          ? null
          : _mobileCtrl.text.trim(),
      donationType: _type,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      itemsDesc: _itemsCtrl.text.trim().isEmpty ? null : _itemsCtrl.text.trim(),
      purpose: _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
      transactionId: _txnCtrl.text.trim().isEmpty ? null : _txnCtrl.text.trim(),
    );
    setState(() => _saving = false);
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Donation recorded successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to record donation.'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 18),

          // Sheet title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: _accent, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record Donation',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Track your contribution for the NGO.',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),

          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type selector
                  _TypePicker(
                    selected: _type,
                    onChanged: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: 20),

                  // Fields
                  _Field(
                    ctrl: _nameCtrl,
                    label: 'Donor Name',
                    hint: 'Optional',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    ctrl: _mobileCtrl,
                    label: 'Phone',
                    hint: 'Optional',
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  if (_type == DonationType.money ||
                      _type == DonationType.sponsorship) ...[
                    _Field(
                      ctrl: _amountCtrl,
                      label: 'Amount (₹)',
                      hint: 'e.g. 500',
                      icon: Icons.currency_rupee_rounded,
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (_type == DonationType.things ||
                      _type == DonationType.service) ...[
                    _Field(
                      ctrl: _itemsCtrl,
                      label: 'Items / Service Description',
                      hint: 'e.g. 20 notebooks and stationery',
                      icon: Icons.inventory_2_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                  ],

                  _Field(
                    ctrl: _purposeCtrl,
                    label: 'Purpose / Cause',
                    hint: 'e.g. Education support',
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    ctrl: _txnCtrl,
                    label: 'Transaction ID / UPI Ref',
                    hint: 'Optional — paste from payment app',
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 26),

                  // Sticky submit
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        disabledBackgroundColor:
                            _accent.withValues(alpha: 0.45),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Donation Record'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donation type picker ───────────────────────────────────────────────────────

class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.selected, required this.onChanged});
  final DonationType selected;
  final ValueChanged<DonationType> onChanged;

  static const _items = [
    (DonationType.money,       '₹',  'Money'),
    (DonationType.things,      '📦', 'Things'),
    (DonationType.service,     '🤝', 'Service'),
    (DonationType.sponsorship, '⭐', 'Sponsor'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Donation Type',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_items.length, (i) {
            final (type, emoji, label) = _items[i];
            final sel = selected == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 4,
                  right: i == _items.length - 1 ? 0 : 4,
                ),
                child: GestureDetector(
                  onTap: () => onChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 190),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel
                          ? _primary
                          : _primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel
                            ? _primary
                            : _primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          style: TextStyle(
                            color: sel ? Colors.white : _primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Input Field ────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
  });
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: const TextStyle(
              color: _ink, fontWeight: FontWeight.w600, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w400),
            prefixIcon: Icon(icon, color: _primary, size: 18),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    );
  }
}

// ── Stipend Tile ───────────────────────────────────────────────────────────────

class _StipendTile extends StatelessWidget {
  const _StipendTile(this.stipend);
  final StipendRecord stipend;

  @override
  Widget build(BuildContext context) {
    final color = switch (stipend.status) {
      'paid'     => const Color(0xFF2E7D32),
      'approved' => _primary,
      _          => Colors.grey.shade500,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${stipend.stipendAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${stipend.percentage}% of donation',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stipend.status.toUpperCase(),
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donation Tile ──────────────────────────────────────────────────────────────

class _DonationTile extends StatelessWidget {
  const _DonationTile(this.donation);
  final Donation donation;

  @override
  Widget build(BuildContext context) {
    final color = switch (donation.status) {
      DonationStatus.approved => const Color(0xFF2E7D32),
      DonationStatus.rejected => _accent,
      DonationStatus.verified => _primary,
      _                       => Colors.grey.shade500,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: _accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.donationType.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    fontSize: 13,
                  ),
                ),
                if (donation.amount > 0)
                  Text(
                    '₹${donation.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                if (donation.purpose != null)
                  Text(
                    donation.purpose!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 11),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              donation.status.displayName,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
