import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/auth_models.dart';

void main() {
  group('UserRole.fromString', () {
    test('parses all known roles', () {
      expect(UserRole.fromString('super_admin'), UserRole.superAdmin);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('mentor'), UserRole.mentor);
      expect(UserRole.fromString('content_creator'), UserRole.contentCreator);
      expect(UserRole.fromString('student'), UserRole.student);
    });

    test('unknown role falls back to guest', () {
      expect(UserRole.fromString('unknown'), UserRole.guest);
      expect(UserRole.fromString(''), UserRole.guest);
    });
  });

  group('UserRole helpers', () {
    test('isAdmin is true for admin and superAdmin only', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.superAdmin.isAdmin, isTrue);
      expect(UserRole.student.isAdmin, isFalse);
      expect(UserRole.mentor.isAdmin, isFalse);
    });

    test('isStudent is true for student only', () {
      expect(UserRole.student.isStudent, isTrue);
      expect(UserRole.admin.isStudent, isFalse);
    });

    test('isMentor is true for mentor only', () {
      expect(UserRole.mentor.isMentor, isTrue);
      expect(UserRole.student.isMentor, isFalse);
    });
  });

  group('TokenResponse.fromJson', () {
    test('parses all fields', () {
      final token = TokenResponse.fromJson({
        'access_token': 'abc.def.ghi',
        'role': 'admin',
        'user_id': 2,
        'name': 'Admin User',
      });
      expect(token.accessToken, 'abc.def.ghi');
      expect(token.role, 'admin');
      expect(token.userId, 2);
      expect(token.name, 'Admin User');
    });
  });
}
