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

  /// PATCH /users/me/profile — students can update editable fields only.
  static Future<AppUser> updateProfile({
    String? name,
    String? className,
    String? schoolName,
    String? location,
    int? age,
    String? parentEmail,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (className != null) 'class_name': className,
      if (schoolName != null) 'school_name': schoolName,
      if (location != null) 'location': location,
      if (age != null) 'age': age,
      if (parentEmail != null) 'parent_email': parentEmail,
      if (phone != null) 'phone': phone,
    };
    final json = await ApiClient.patch('/users/me/profile', body)
        as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }
}
