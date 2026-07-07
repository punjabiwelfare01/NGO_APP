import '../models/bank_info.dart';
import 'api_client.dart';

class BankRepository {
  const BankRepository._();

  static BankInfo? _cached;

  /// Returns cached bank/UPI details, fetching from backend on first call.
  /// Blank fields fall back to [BankInfo.fallback]; any request error also
  /// falls back entirely, so donation screens never show empty details.
  static Future<BankInfo> getBank() async {
    if (_cached != null) return _cached!;
    try {
      final data = await ApiClient.get('/admin/settings/bank/public');
      _cached = BankInfo.fromJson(data as Map<String, dynamic>).withFallback();
      return _cached!;
    } catch (_) {
      return BankInfo.fallback;
    }
  }

  static void clearCache() => _cached = null;
}
