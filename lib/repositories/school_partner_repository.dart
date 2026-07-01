import '../models/school_partner_models.dart';
import 'api_client.dart';

class SchoolPartnerRepository {
  const SchoolPartnerRepository._();

  /// GET /school/profile
  static Future<SchoolPartnerProfile> getProfile() async {
    final json =
        await ApiClient.get('/school/profile') as Map<String, dynamic>;
    return SchoolPartnerProfile.fromJson(json);
  }

  /// PATCH /school/profile
  static Future<SchoolPartnerProfile> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final json =
        await ApiClient.patch('/school/profile', data) as Map<String, dynamic>;
    return SchoolPartnerProfile.fromJson(json);
  }

  /// POST /school/profile/upload-logo  (multipart)
  static Future<String> uploadLogo(
    List<int> bytes,
    String filename,
  ) async {
    final json = await ApiClient.postMultipart(
      '/school/profile/upload-logo',
      fields: {},
      fileBytes: bytes,
      fileName: filename,
      fileField: 'file',
    ) as Map<String, dynamic>;
    return json['url'] as String;
  }
}
