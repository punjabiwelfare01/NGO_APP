import '../models/api_models.dart';
import '../models/counselling_models.dart';
import 'api_client.dart';

class CounsellingRepository {
  const CounsellingRepository._();

  static Future<List<MentorProfile>> getMentors({String? category}) async {
    final query = category != null ? '?category=${Uri.encodeComponent(category)}' : '';
    final list = await ApiClient.get('/counselling/mentors$query') as List<dynamic>;
    return list
        .map((j) => MentorProfile.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<MentorProfile> getMentor(int id) async {
    final json = await ApiClient.get('/counselling/mentors/$id') as Map<String, dynamic>;
    return MentorProfile.fromJson(json);
  }

  static Future<MentorProfile> createMentorProfile(Map<String, dynamic> payload) async {
    final json = await ApiClient.post('/counselling/mentors', payload) as Map<String, dynamic>;
    return MentorProfile.fromJson(json);
  }

  static Future<MentorProfile> updateMentorProfile(
      int id, Map<String, dynamic> payload) async {
    final json = await ApiClient.patch('/counselling/mentors/$id', payload) as Map<String, dynamic>;
    return MentorProfile.fromJson(json);
  }

  static Future<List<ApiCounsellingSlot>> getSlots({String? category}) async {
    final query = category != null ? '?category=${Uri.encodeComponent(category)}' : '';
    final list = await ApiClient.get('/counselling/slots$query') as List<dynamic>;
    return list
        .map((j) => ApiCounsellingSlot.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ApiCounsellingSlot>> getMentorSlots(int userId) async {
    final list = await ApiClient.get('/counselling/slots/mentor/$userId') as List<dynamic>;
    return list
        .map((j) => ApiCounsellingSlot.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<CounsellingAnalytics> getAnalytics() async {
    final json = await ApiClient.get('/counselling/analytics') as Map<String, dynamic>;
    return CounsellingAnalytics.fromJson(json);
  }
}
