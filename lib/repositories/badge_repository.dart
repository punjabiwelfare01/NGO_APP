import '../models/api_models.dart';
import 'api_client.dart';

class BadgeRepository {
  const BadgeRepository._();

  static Future<List<UserBadge>> getUserBadges(int userId) async {
    final list =
        await ApiClient.get('/users/$userId/badges') as List<dynamic>;
    return list
        .map((j) => UserBadge.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<UserBadge> awardBadge(int userId, int badgeId) async {
    final json = await ApiClient.post(
      '/users/$userId/badges/$badgeId',
      {},
    ) as Map<String, dynamic>;
    return UserBadge.fromJson(json);
  }
}
