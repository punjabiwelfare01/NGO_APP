import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/auth_models.dart';

void main() {
  test('counsellor and mentor API roles route to the counsellor role', () {
    expect(UserRole.fromString('mentor'), UserRole.mentor);
    expect(UserRole.fromString('counsellor'), UserRole.mentor);
    expect(UserRole.mentor.isMentor, isTrue);
  });

  test('pending status aliases never resolve as approved', () {
    for (final value in [
      'pending',
      'pending_verification',
      'pending_review',
      'under_review',
    ]) {
      expect(AccessStatus.fromString(value), AccessStatus.pendingVerification);
    }
    expect(AccessStatus.pendingVerification.apiValue, 'pending');
  });

  test('school partner has a dedicated role instead of student fallback', () {
    expect(UserRole.fromString('school_partner'), UserRole.schoolPartner);
    expect(UserRole.schoolPartner.isSchoolPartner, isTrue);
  });
}
