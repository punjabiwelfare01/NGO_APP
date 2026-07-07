class BankInfo {
  final String? accountHolder;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? qrUrl;

  const BankInfo({
    this.accountHolder,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.qrUrl,
  });

  // The bank/UPI details in live use before this became admin-editable;
  // also used as a fallback when the admin hasn't saved anything yet.
  static const BankInfo fallback = BankInfo(
    accountHolder: 'Punjabi Welfare Trust',
    bankName: 'Union Bank of India',
    accountNumber: '35270101011873',
    ifscCode: 'UBIN0535273',
    upiId: 'punjabiwelfaretrust@upi',
  );

  factory BankInfo.fromJson(Map<String, dynamic> j) => BankInfo(
    accountHolder: j['account_holder'] as String?,
    bankName: j['bank_name'] as String?,
    accountNumber: j['account_number'] as String?,
    ifscCode: j['ifsc_code'] as String?,
    upiId: j['upi_id'] as String?,
    qrUrl: j['qr_url'] as String?,
  );

  /// Fills any blank field from [fallback] so the UI never shows "Not set"
  /// for details that are simply unconfigured yet.
  BankInfo withFallback() => BankInfo(
    accountHolder: _orFallback(accountHolder, fallback.accountHolder),
    bankName: _orFallback(bankName, fallback.bankName),
    accountNumber: _orFallback(accountNumber, fallback.accountNumber),
    ifscCode: _orFallback(ifscCode, fallback.ifscCode),
    upiId: _orFallback(upiId, fallback.upiId),
    qrUrl: qrUrl,
  );

  static String? _orFallback(String? value, String? fallbackValue) =>
      (value == null || value.isEmpty) ? fallbackValue : value;
}
