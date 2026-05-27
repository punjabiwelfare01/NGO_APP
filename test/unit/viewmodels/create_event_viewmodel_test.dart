import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/event_models.dart';
import 'package:flutter_application_1/viewmodels/create_event_viewmodel.dart';

void main() {
  late CreateEventViewModel vm;

  setUp(() => vm = CreateEventViewModel());
  tearDown(() => vm.dispose());

  // ── getTimelineErrors ──────────────────────────────────────────────────────

  group('getTimelineErrors — required fields missing', () {
    test('all required dates missing returns 4 errors', () {
      final errors = vm.getTimelineErrors();
      expect(errors.containsKey('registrationStart'), isTrue);
      expect(errors.containsKey('registrationEnd'), isTrue);
      expect(errors.containsKey('eventStart'), isTrue);
      expect(errors.containsKey('eventEnd'), isTrue);
    });

    test('no errors once all required dates are set in order', () {
      final now = DateTime.now();
      vm.setRegistrationStart(now.add(const Duration(days: 1)));
      vm.setRegistrationEnd(now.add(const Duration(days: 5)));
      vm.setEventStart(now.add(const Duration(days: 7)));
      vm.setEventEnd(now.add(const Duration(days: 8)));
      expect(vm.getTimelineErrors(), isEmpty);
    });
  });

  group('getTimelineErrors — past date rejection', () {
    test('registrationStart in the past is an error', () {
      vm.setRegistrationStart(DateTime.now().subtract(const Duration(hours: 1)));
      final errors = vm.getTimelineErrors();
      expect(errors['registrationStart'], isNotNull);
    });

    test('eventStart in the past is an error', () {
      final now = DateTime.now();
      vm.setRegistrationStart(now.add(const Duration(days: 1)));
      vm.setRegistrationEnd(now.add(const Duration(days: 2)));
      vm.setEventStart(now.subtract(const Duration(hours: 1)));
      final errors = vm.getTimelineErrors();
      expect(errors['eventStart'], isNotNull);
    });
  });

  group('getTimelineErrors — chronological order', () {
    test('registrationEnd before registrationStart is an error', () {
      final now = DateTime.now();
      vm.setRegistrationStart(now.add(const Duration(days: 5)));
      vm.setRegistrationEnd(now.add(const Duration(days: 3)));
      expect(vm.getTimelineErrors().containsKey('registrationEnd'), isTrue);
    });

    test('eventStart before registrationEnd is an error', () {
      final now = DateTime.now();
      vm.setRegistrationStart(now.add(const Duration(days: 1)));
      vm.setRegistrationEnd(now.add(const Duration(days: 10)));
      vm.setEventStart(now.add(const Duration(days: 5)));
      vm.setEventEnd(now.add(const Duration(days: 12)));
      expect(vm.getTimelineErrors().containsKey('eventStart'), isTrue);
    });

    test('eventEnd before eventStart is an error', () {
      final now = DateTime.now();
      vm.setRegistrationStart(now.add(const Duration(days: 1)));
      vm.setRegistrationEnd(now.add(const Duration(days: 3)));
      vm.setEventStart(now.add(const Duration(days: 5)));
      vm.setEventEnd(now.add(const Duration(days: 4)));
      expect(vm.getTimelineErrors().containsKey('eventEnd'), isTrue);
    });

    test('resultDate before eventEnd is an error', () {
      final now = DateTime.now();
      vm.setRegistrationStart(now.add(const Duration(days: 1)));
      vm.setRegistrationEnd(now.add(const Duration(days: 3)));
      vm.setEventStart(now.add(const Duration(days: 5)));
      vm.setEventEnd(now.add(const Duration(days: 7)));
      vm.setResultDate(now.add(const Duration(days: 6)));
      expect(vm.getTimelineErrors().containsKey('resultDate'), isTrue);
    });

    test('resultDate after eventEnd is valid', () {
      final now = DateTime.now();
      vm.setRegistrationStart(now.add(const Duration(days: 1)));
      vm.setRegistrationEnd(now.add(const Duration(days: 3)));
      vm.setEventStart(now.add(const Duration(days: 5)));
      vm.setEventEnd(now.add(const Duration(days: 7)));
      vm.setResultDate(now.add(const Duration(days: 9)));
      expect(vm.getTimelineErrors().containsKey('resultDate'), isFalse);
    });

    test('counsellingDate before eventEnd is an error', () {
      final now = DateTime.now();
      vm.setRegistrationStart(now.add(const Duration(days: 1)));
      vm.setRegistrationEnd(now.add(const Duration(days: 3)));
      vm.setEventStart(now.add(const Duration(days: 5)));
      vm.setEventEnd(now.add(const Duration(days: 7)));
      vm.setCounsellingDate(now.add(const Duration(days: 6)));
      expect(vm.getTimelineErrors().containsKey('counsellingDate'), isTrue);
    });
  });

  group('getTimelineErrors — optional fields', () {
    test('null resultDate and counsellingDate produce no extra errors', () {
      final now = DateTime.now();
      vm.setRegistrationStart(now.add(const Duration(days: 1)));
      vm.setRegistrationEnd(now.add(const Duration(days: 3)));
      vm.setEventStart(now.add(const Duration(days: 5)));
      vm.setEventEnd(now.add(const Duration(days: 7)));
      // resultDate and counsellingDate left null
      final errors = vm.getTimelineErrors();
      expect(errors.containsKey('resultDate'), isFalse);
      expect(errors.containsKey('counsellingDate'), isFalse);
    });
  });

  // ── notifyListeners ────────────────────────────────────────────────────────

  group('setters call notifyListeners', () {
    test('setTitle triggers a notification', () {
      var notified = false;
      vm.addListener(() => notified = true);
      vm.setTitle('New Title');
      expect(notified, isTrue);
      expect(vm.title, 'New Title');
    });

    test('setEventType triggers a notification', () {
      var notified = false;
      vm.addListener(() => notified = true);
      vm.setEventType(EventType.workshop);
      expect(notified, isTrue);
      expect(vm.selectedEventType, EventType.workshop);
    });
  });
}
