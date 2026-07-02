import '../models/impact_post.dart';
import 'api_client.dart';

class ImpactRepository {
  const ImpactRepository._();

  static Future<List<ImpactPost>> getPublished({String? category}) async {
    final query = category == null
        ? ''
        : '&category=${Uri.encodeQueryComponent(category)}';
    final data =
        await ApiClient.get('/impact/posts?status=published$query')
            as List<dynamic>;
    return data
        .map((item) => ImpactPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ImpactPost> getPost(int id) async => ImpactPost.fromJson(
    await ApiClient.get('/impact/posts/$id') as Map<String, dynamic>,
  );

  static Future<List<ImpactPost>> getMine() async {
    final data =
        await ApiClient.get('/impact/posts?mine=true') as List<dynamic>;
    return data
        .map((item) => ImpactPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ImpactMetrics> getMetrics() async => ImpactMetrics.fromJson(
    await ApiClient.get('/impact/metrics') as Map<String, dynamic>,
  );

  static Future<ImpactPost> appreciate(int id) async => ImpactPost.fromJson(
    await ApiClient.post('/impact/posts/$id/appreciate', const {})
        as Map<String, dynamic>,
  );

  static Future<String> share(int id) async {
    final data =
        await ApiClient.post('/impact/posts/$id/share', const {})
            as Map<String, dynamic>;
    return data['public_url'] as String;
  }
}
