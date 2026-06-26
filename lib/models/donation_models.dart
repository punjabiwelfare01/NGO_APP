// ignore_for_file: constant_identifier_names

enum DonationType {
  money,
  things,
  service,
  sponsorship;

  String get displayName => switch (this) {
    money       => 'Money',
    things      => 'Things / Items',
    service     => 'Service',
    sponsorship => 'Sponsorship',
  };

  static DonationType fromString(String v) =>
      DonationType.values.firstWhere((e) => e.name == v,
          orElse: () => DonationType.money);
}

enum DonationStatus {
  pending,
  verified,
  approved,
  rejected;

  String get displayName => switch (this) {
    pending  => 'Pending',
    verified => 'Verified',
    approved => 'Approved',
    rejected => 'Rejected',
  };

  static DonationStatus fromString(String v) =>
      DonationStatus.values.firstWhere((e) => e.name == v,
          orElse: () => DonationStatus.pending);
}

class Donation {
  final int id;
  final String? donorName;
  final String? donorMobile;
  final String? donorEmail;
  final DonationType donationType;
  final String? category;
  final double amount;
  final String? itemsDesc;
  final String? purpose;
  final String? transactionId;
  final String? proofFile;
  final int? referredBy;
  final DonationStatus status;
  final String? receiptNumber;
  final DateTime? createdAt;

  const Donation({
    required this.id,
    this.donorName,
    this.donorMobile,
    this.donorEmail,
    required this.donationType,
    this.category,
    required this.amount,
    this.itemsDesc,
    this.purpose,
    this.transactionId,
    this.proofFile,
    this.referredBy,
    required this.status,
    this.receiptNumber,
    this.createdAt,
  });

  factory Donation.fromJson(Map<String, dynamic> j) => Donation(
        id: j['id'] as int,
        donorName: j['donor_name'] as String?,
        donorMobile: j['donor_mobile'] as String?,
        donorEmail: j['donor_email'] as String?,
        donationType: DonationType.fromString(j['donation_type'] as String),
        category: j['category'] as String?,
        amount: (j['amount'] as num).toDouble(),
        itemsDesc: j['items_desc'] as String?,
        purpose: j['purpose'] as String?,
        transactionId: j['transaction_id'] as String?,
        proofFile: j['proof_file'] as String?,
        referredBy: j['referred_by'] as int?,
        status: DonationStatus.fromString(j['status'] as String),
        receiptNumber: j['receipt_number'] as String?,
        createdAt: j['created_at'] == null
            ? null
            : DateTime.tryParse(j['created_at'] as String),
      );
}

class NGOPaymentDetails {
  final int id;
  final String? upiId;
  final String? qrCodeFile;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolder;

  const NGOPaymentDetails({
    required this.id,
    this.upiId,
    this.qrCodeFile,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolder,
  });

  factory NGOPaymentDetails.fromJson(Map<String, dynamic> j) =>
      NGOPaymentDetails(
        id: j['id'] as int,
        upiId: j['upi_id'] as String?,
        qrCodeFile: j['qr_code_file'] as String?,
        bankName: j['bank_name'] as String?,
        accountNumber: j['account_number'] as String?,
        ifscCode: j['ifsc_code'] as String?,
        accountHolder: j['account_holder'] as String?,
      );
}

class StipendRecord {
  final int id;
  final int studentId;
  final int donationId;
  final double percentage;
  final double stipendAmount;
  final String status;
  final DateTime? createdAt;

  const StipendRecord({
    required this.id,
    required this.studentId,
    required this.donationId,
    required this.percentage,
    required this.stipendAmount,
    required this.status,
    this.createdAt,
  });

  factory StipendRecord.fromJson(Map<String, dynamic> j) => StipendRecord(
        id: j['id'] as int,
        studentId: j['student_id'] as int,
        donationId: j['donation_id'] as int,
        percentage: (j['percentage'] as num).toDouble(),
        stipendAmount: (j['stipend_amount'] as num).toDouble(),
        status: j['status'] as String? ?? 'pending',
        createdAt: j['created_at'] == null
            ? null
            : DateTime.tryParse(j['created_at'] as String),
      );
}
