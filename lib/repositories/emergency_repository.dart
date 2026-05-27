import '../models/emergency_contact.dart';
import 'api_client.dart';

class EmergencyRepository {
  const EmergencyRepository._();

  static Future<List<EmergencyContact>> getContacts() async {
    final list = await ApiClient.get('/emergency-contacts') as List<dynamic>;
    return list
        .map((j) => EmergencyContact.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<List<EmergencyContact>> getAllContacts() async {
    final list = await ApiClient.get('/emergency-contacts/all') as List<dynamic>;
    return list
        .map((j) => EmergencyContact.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<EmergencyContact> createContact({
    required String name,
    required String phone,
    String? description,
    bool isActive = true,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'is_active': isActive,
    };
    if (description != null) body['description'] = description;
    final json = await ApiClient.post('/emergency-contacts', body) as Map<String, dynamic>;
    return EmergencyContact.fromJson(json);
  }

  static Future<EmergencyContact> updateContact(
    int id, {
    String? name,
    String? phone,
    String? description,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (description != null) body['description'] = description;
    if (isActive != null) body['is_active'] = isActive;
    final json = await ApiClient.patch('/emergency-contacts/$id', body) as Map<String, dynamic>;
    return EmergencyContact.fromJson(json);
  }

  static Future<void> deleteContact(int id) async {
    await ApiClient.delete('/emergency-contacts/$id');
  }
}
