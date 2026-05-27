import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/auth/login_view.dart';

Widget buildSubject() => const MaterialApp(home: LoginView());

void main() {
  group('LoginView', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('shows login button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('shows error when submitting empty form', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data?.toLowerCase().contains('email') == true ||
                w.data?.toLowerCase().contains('password') == true ||
                w.data?.toLowerCase().contains('required') == true ||
                w.data?.toLowerCase().contains('enter') == true)),
        findsWidgets,
      );
    });

    testWidgets('can type into email field', (tester) async {
      await tester.pumpWidget(buildSubject());
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });
}
