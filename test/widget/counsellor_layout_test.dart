import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/counsellor/counsellor_home_view.dart';
import 'package:flutter_application_1/screens/counsellor/counsellor_profile_view.dart';
import 'package:flutter_application_1/viewmodels/counsellor_home_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setPhoneSize(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('counsellor home fits a narrow phone without overflow', (
    tester,
  ) async {
    await setPhoneSize(tester);
    final vm = CounsellorHomeViewModel();
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: CounsellorHomeView(
              vm: vm,
              counsellorName: 'Meera',
              onNavigate: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('counsellor profile exposes editing without header overflow', (
    tester,
  ) async {
    await setPhoneSize(tester);
    final vm = CounsellorHomeViewModel();
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(child: CounsellorProfileView(vm: vm)),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.byTooltip('Edit profile'), findsOneWidget);
    expect(find.text('Private account details'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Counsellor Profile'), findsOneWidget);
    expect(find.text('Save Profile'), findsOneWidget);
  });
}
