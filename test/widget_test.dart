import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('CareSkill starts at login without a session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CareSkillApp());

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Demo accounts'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
