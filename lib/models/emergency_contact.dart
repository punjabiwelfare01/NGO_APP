class EmergencyContact {
  final int id;
  final String name;
  final String phone;
  final String? description;
  final bool isActive;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.description,
    required this.isActive,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool,
    );
  }
}
