enum UserRole {
  superAdmin,
  admin,
  mentor,
  contentCreator,
  student,
  guest;

  static UserRole fromString(String value) => switch (value) {
        'super_admin'     => UserRole.superAdmin,
        'admin'           => UserRole.admin,
        'mentor'          => UserRole.mentor,
        'content_creator' => UserRole.contentCreator,
        'student'         => UserRole.student,
        _                 => UserRole.guest,
      };

  bool get isAdmin => this == superAdmin || this == admin;
  bool get isMentor => this == mentor;
  bool get isStudent => this == student;
  bool get isContentCreator => this == contentCreator;

  String get displayName => switch (this) {
        UserRole.superAdmin     => 'Super Admin',
        UserRole.admin          => 'Admin',
        UserRole.mentor         => 'Mentor',
        UserRole.contentCreator => 'Content Creator',
        UserRole.student        => 'Student',
        UserRole.guest          => 'Guest',
      };
}

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.role,
    required this.userId,
    required this.name,
  });

  final String accessToken;
  final String role;
  final int userId;
  final String name;

  factory TokenResponse.fromJson(Map<String, dynamic> j) => TokenResponse(
        accessToken: j['access_token'] as String,
        role: j['role'] as String,
        userId: j['user_id'] as int,
        name: j['name'] as String,
      );
}
