import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../models/donation_models.dart';
import '../../viewmodels/volunteer_viewmodel.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({required this.vm, super.key});
  final VolunteerViewModel vm;

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    widget.vm.loadDonations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donations',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // NGO Payment Details card
              _NGOPaymentCard(details: widget.vm.paymentDetails),
              const SizedBox(height: 16),

              // Transparency note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_rounded,
                        size: 16, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All donations are received directly in the NGO account. Student stipend is released only after verification and admin approval.',
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Record donation button
              if (!_showForm)
                FilledButton.icon(
                  onPressed: () => setState(() => _showForm = true),
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('Record a Donation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.softRed,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

              if (_showForm) ...[
                _DonationForm(
                  vm: widget.vm,
                  onSaved: () => setState(() => _showForm = false),
                  onCancel: () => setState(() => _showForm = false),
                ),
                const SizedBox(height: 16),
              ],

              // Stipend section
              if (widget.vm.stipends.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('My Stipends',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        fontSize: 15)),
                const SizedBox(height: 10),
                ...widget.vm.stipends
                    .map((s) => _StipendCard(stipend: s)),
              ],

              // Past donations
              if (widget.vm.donations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('My Donation Records',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        fontSize: 15)),
                const SizedBox(height: 10),
                ...widget.vm.donations
                    .map((d) => _DonationCard(donation: d)),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── NGO Payment Card ──────────────────────────────────────────────────────────

class _NGOPaymentCard extends StatelessWidget {
  const _NGOPaymentCard({required this.details});
  final NGOPaymentDetails? details;

  @override
  Widget build(BuildContext context) {
    final upi = details?.upiId ?? 'punjabiwelfaretrust@upi';
    final bank = details?.bankName ?? 'State Bank of India';
    final holder = details?.accountHolder ?? 'Punjabi Welfare Trust';
    final account = details?.accountNumber;
    final ifsc = details?.ifscCode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('NGO Donation Details',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          _PaymentRow(label: 'Account Holder', value: holder),
          _PaymentRow(
            label: 'UPI ID',
            value: upi,
            onCopy: () => _copy(context, upi, 'UPI ID'),
          ),
          if (bank.isNotEmpty)
            _PaymentRow(label: 'Bank', value: bank),
          if (account != null)
            _PaymentRow(
              label: 'Account No.',
              value: account,
              onCopy: () => _copy(context, account, 'Account number'),
            ),
          if (ifsc != null)
            _PaymentRow(label: 'IFSC', value: ifsc),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '⚠ Never transfer to any personal account. Only use the NGO UPI / bank details shown here.',
              style: TextStyle(
                  color: Colors.white, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.label, required this.value, this.onCopy});
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          if (onCopy != null)
            GestureDetector(
              onTap: onCopy,
              child: const Icon(Icons.copy_rounded,
                  size: 14, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

// ── Donation Form ─────────────────────────────────────────────────────────────

class _DonationForm extends StatefulWidget {
  const _DonationForm({
    required this.vm,
    required this.onSaved,
    required this.onCancel,
  });
  final VolunteerViewModel vm;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  @override
  State<_DonationForm> createState() => _DonationFormState();
}

class _DonationFormState extends State<_DonationForm> {
  DonationType _type = DonationType.money;
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _itemsCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _txnCtrl = TextEditingController();
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

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await widget.vm.submitDonation(
      donorName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      donorMobile:
          _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
      donationType: _type,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      itemsDesc:
          _itemsCtrl.text.trim().isEmpty ? null : _itemsCtrl.text.trim(),
      purpose:
          _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
      transactionId:
          _txnCtrl.text.trim().isEmpty ? null : _txnCtrl.text.trim(),
    );
    setState(() => _saving = false);
    if (result != null) {
      widget.onSaved();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record donation.')),
      );
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.muted.withValues(alpha: 0.6), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.muted.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.muted.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Record Donation',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.ink)),
              const Spacer(),
              TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel')),
            ],
          ),
          const SizedBox(height: 10),
          // Type selector
          Wrap(
            spacing: 8,
            children: DonationType.values.map((t) {
              final sel = _type == t;
              return ChoiceChip(
                label: Text(t.displayName, style: const TextStyle(fontSize: 12)),
                selected: sel,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                    color: sel ? AppColors.primary : AppColors.muted,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.normal),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          TextField(controller: _nameCtrl, decoration: _deco('Donor name (optional)')),
          const SizedBox(height: 8),
          TextField(
              controller: _mobileCtrl,
              decoration: _deco('Donor mobile (optional)'),
              keyboardType: TextInputType.phone),
          const SizedBox(height: 8),
          if (_type == DonationType.money || _type == DonationType.sponsorship)
            TextField(
              controller: _amountCtrl,
              decoration: _deco('Amount in ₹'),
              keyboardType: TextInputType.number,
            ),
          if (_type == DonationType.things || _type == DonationType.service)
            TextField(
              controller: _itemsCtrl,
              decoration: _deco('Describe items / service'),
              maxLines: 2,
            ),
          const SizedBox(height: 8),
          TextField(controller: _purposeCtrl, decoration: _deco('Purpose / cause')),
          const SizedBox(height: 8),
          TextField(
              controller: _txnCtrl,
              decoration: _deco('Transaction ID / UPI ref (optional)')),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(_saving ? 'Saving…' : 'Submit Donation Record'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.softRed,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stipend Card ──────────────────────────────────────────────────────────────

class _StipendCard extends StatelessWidget {
  const _StipendCard({required this.stipend});
  final StipendRecord stipend;

  @override
  Widget build(BuildContext context) {
    final color = switch (stipend.status) {
      'paid'     => AppColors.secondary,
      'approved' => AppColors.primary,
      _          => AppColors.muted,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${stipend.stipendAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 16),
                ),
                Text(
                  '${stipend.percentage}% of donation',
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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

// ── Donation Card ─────────────────────────────────────────────────────────────

class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.donation});
  final Donation donation;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (donation.status) {
      DonationStatus.approved => AppColors.secondary,
      DonationStatus.rejected => AppColors.softRed,
      DonationStatus.verified => AppColors.primary,
      _                       => AppColors.muted,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.softRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: AppColors.softRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.donationType.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      fontSize: 13),
                ),
                if (donation.amount > 0)
                  Text('₹${donation.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                if (donation.purpose != null)
                  Text(donation.purpose!,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              donation.status.displayName,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
