import '../models/ngo_profile.dart';
import 'api_client.dart';

class NGORepository {
  const NGORepository._();

  static NGOProfile? _cached;

  /// Returns cached profile, fetching from backend on first call.
  /// Falls back to [NGOProfile.fallback] on any error.
  static Future<NGOProfile> getProfile() async {
    if (_cached != null) return _cached!;
    try {
      final data = await ApiClient.get('/admin/settings/ngo-profile/public');
      _cached = NGOProfile.fromJson(data as Map<String, dynamic>);
      return _cached!;
    } catch (_) {
      return NGOProfile.fallback;
    }
  }

  static void clearCache() => _cached = null;
}
