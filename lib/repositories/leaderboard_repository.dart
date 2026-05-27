import '../models/api_models.dart';
import 'api_client.dart';

class LeaderboardRepository {
  const LeaderboardRepository._();

  static Future<List<LeaderboardEntry>> getLeaderboard(
      {int limit = 10}) async {
    final list =
        await ApiClient.get('/leaderboard/?limit=$limit') as List<dynamic>;
    return list
        .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<LeaderboardEntry> getUserRank(int userId) async {
    final json = await ApiClient.get('/leaderboard/$userId/rank')
        as Map<String, dynamic>;
    return LeaderboardEntry.fromJson(json);
  }
}
