import '../models/api_models.dart';
import 'api_client.dart';

class UserRepository {
  const UserRepository._();

  static Future<AppUser> getUser(int userId) async {
    final json = await ApiClient.get('/users/$userId') as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  static Future<UserStats> getUserStats(int userId) async {
    final json =
        await ApiClient.get('/users/$userId/stats') as Map<String, dynamic>;
    return UserStats.fromJson(json);
  }

  static Future<AppUser> addXp(int userId, int amount) async {
    final json = await ApiClient.post('/users/$userId/xp', {'amount': amount})
        as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }
}
