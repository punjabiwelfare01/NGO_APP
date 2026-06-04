import '../models/creator_content.dart';
import '../models/creator_post.dart';
import 'api_client.dart';

class CreatorRepository {
  const CreatorRepository._();

  static Future<List<CreatorContentItem>> getContent({
    String? status,
    String? type,
    String? search,
  }) async {
    final params = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (type != null && type.isNotEmpty) 'type': type,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final path = query.isEmpty ? '/creator/content' : '/creator/content?$query';
    final json = await ApiClient.get(path) as Map<String, dynamic>;
    return CreatorContentResponse.fromJson(json).items;
  }

  static Future<CreatorContentItem> getContentDetail({
    required String type,
    required int id,
  }) async {
    final json =
        await ApiClient.get('/creator/content/$type/$id')
            as Map<String, dynamic>;
    return CreatorContentItem.fromJson(json);
  }

  static Future<List<CreatorPostItem>> getPosts({String? status}) async {
    final path = status == null || status.isEmpty
        ? '/creator/posts'
        : '/creator/posts?status=${Uri.encodeQueryComponent(status)}';
    final json = await ApiClient.get(path) as Map<String, dynamic>;
    return CreatorContentResponse.fromJson(json).items;
  }

  static Future<CreatorPostItem> createPost(CreatorPostDraft draft) async {
    final json =
        await ApiClient.post('/creator/posts', draft.toJson())
            as Map<String, dynamic>;
    return CreatorContentItem.fromJson(json);
  }

  static Future<CreatorContentItem> updateContent({
    required String type,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final json =
        await ApiClient.patch('/creator/content/$type/$id', data)
            as Map<String, dynamic>;
    return CreatorContentItem.fromJson(json);
  }

  static Future<void> deleteContent({
    required String type,
    required int id,
  }) async {
    await ApiClient.delete('/creator/content/$type/$id');
  }

  static Future<CreatorContentItem> submitReview({
    required String type,
    required int id,
  }) async {
    final json =
        await ApiClient.post('/creator/content/$type/$id/submit-review', {})
            as Map<String, dynamic>;
    return CreatorContentItem.fromJson(json);
  }

  static Future<CreatorContentItem> publish({
    required String type,
    required int id,
  }) async {
    final json =
        await ApiClient.post('/creator/content/$type/$id/publish', {})
            as Map<String, dynamic>;
    return CreatorContentItem.fromJson(json);
  }

  static Future<CreatorContentItem> unpublish({
    required String type,
    required int id,
  }) async {
    final json =
        await ApiClient.post('/creator/content/$type/$id/unpublish', {})
            as Map<String, dynamic>;
    return CreatorContentItem.fromJson(json);
  }
}
