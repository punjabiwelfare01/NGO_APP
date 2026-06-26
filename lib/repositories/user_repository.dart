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
    final json =
        await ApiClient.post('/users/$userId/xp', {'amount': amount})
            as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  /// PATCH /users/me/profile — students can update editable fields only.
  static Future<AppUser> updateProfile({
    String? name,
    String? className,
    String? schoolName,
    String? location,
    int? age,
    DateTime? dateOfBirth,
    String? parentEmail,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    void addIfPresent(String key, Object? value) {
      if (value != null) body[key] = value;
    }

    addIfPresent('name', name);
    addIfPresent('class_name', className);
    addIfPresent('school_name', schoolName);
    addIfPresent('location', location);
    addIfPresent('age', age);
    addIfPresent(
      'date_of_birth',
      dateOfBirth?.toIso8601String().split('T').first,
    );
    addIfPresent('parent_email', parentEmail);
    addIfPresent('phone', phone);
    final json =
        await ApiClient.patch('/users/me/profile', body)
            as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  /// POST /users/me/photo — uploads image bytes and returns the updated user.
  /// Pass [bytes] on web (where file paths are unavailable) or [filePath] on
  /// mobile. Exactly one must be non-null.
  static Future<AppUser> uploadProfilePhoto({
    List<int>? bytes,
    String? filePath,
    required String fileName,
  }) async {
    assert(
      (bytes != null) != (filePath != null),
      'Provide bytes (web) OR filePath (mobile), not both',
    );
    final Map<String, dynamic> json;
    if (bytes != null) {
      json = await ApiClient.postMultipart(
        '/users/me/photo',
        fields: const {},
        fileBytes: bytes,
        fileName: fileName,
        fileField: 'file',
      ) as Map<String, dynamic>;
    } else {
      json = await ApiClient.postMultipartFromPath(
        '/users/me/photo',
        fields: const {},
        filePath: filePath!,
        fileName: fileName,
        fileField: 'file',
      ) as Map<String, dynamic>;
    }
    return AppUser.fromJson(json);
  }
}
