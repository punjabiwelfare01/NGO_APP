import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/event_models.dart';

import '../../helpers/fake_api_helpers.dart';

void main() {
  group('EventModel.fromJson', () {
    test('parses required fields correctly', () {
      final json = fakeEventJson(id: 42, title: 'My Event', eventType: 'competition');
      final model = EventModel.fromJson(json);

      expect(model.id, 42);
      expect(model.title, 'My Event');
      expect(model.eventType, EventType.competition);
      expect(model.status, EventStatus.draft);
      expect(model.selectionMethod, SelectionMethod.luckyDraw);
      expect(model.themeColor, '#41A7F5');
      expect(model.participantCount, 0);
    });

    test('parses all event types', () {
      final types = {
        'quiz': EventType.quiz,
        'talent_hunt': EventType.talentHunt,
        'daily_challenge': EventType.dailyChallenge,
        'counselling_drive': EventType.counsellingDrive,
        'scholarship': EventType.scholarship,
        'awareness_campaign': EventType.awarenessCampaign,
        'workshop': EventType.workshop,
        'competition': EventType.competition,
        'cyber_security': EventType.cyberSecurity,
      };
      for (final entry in types.entries) {
        final model = EventModel.fromJson(fakeEventJson(eventType: entry.key));
        expect(model.eventType, entry.value,
            reason: 'Failed for type: ${entry.key}');
      }
    });

    test('parses all event statuses', () {
      final statuses = {
        'draft': EventStatus.draft,
        'pending_review': EventStatus.pendingReview,
        'published': EventStatus.published,
        'registration_open': EventStatus.registrationOpen,
        'live': EventStatus.live,
        'evaluation': EventStatus.evaluation,
        'selection': EventStatus.selection,
        'completed': EventStatus.completed,
        'archived': EventStatus.archived,
      };
      for (final entry in statuses.entries) {
        final json = {...fakeEventJson(), 'status': entry.key};
        expect(EventModel.fromJson(json).status, entry.value,
            reason: 'Failed for status: ${entry.key}');
      }
    });

    test('parses all selection methods', () {
      final methods = {
        'lucky_draw': SelectionMethod.luckyDraw,
        'manual': SelectionMethod.manual,
        'hybrid': SelectionMethod.hybrid,
        'score_based': SelectionMethod.scoreBased,
      };
      for (final entry in methods.entries) {
        final json = {...fakeEventJson(), 'selection_method': entry.key};
        expect(EventModel.fromJson(json).selectionMethod, entry.value,
            reason: 'Failed for method: ${entry.key}');
      }
    });

    test('unknown type falls back to quiz', () {
      final json = {...fakeEventJson(), 'event_type': 'unknown_type'};
      expect(EventModel.fromJson(json).eventType, EventType.quiz);
    });

    test('parses nullable date fields', () {
      final json = {
        ...fakeEventJson(),
        'event_start': '2030-06-15T10:00:00',
        'event_end': '2030-06-15T18:00:00',
        'result_date': null,
      };
      final model = EventModel.fromJson(json);
      expect(model.eventStart, isNotNull);
      expect(model.eventEnd, isNotNull);
      expect(model.resultDate, isNull);
    });

    test('parses boolean flags correctly', () {
      final json = {
        ...fakeEventJson(),
        'counselling_enabled': true,
        'certificate_enabled': true,
        'scholarship_enabled': false,
        'mentorship_enabled': true,
      };
      final model = EventModel.fromJson(json);
      expect(model.counsellingEnabled, isTrue);
      expect(model.certificateEnabled, isTrue);
      expect(model.scholarshipEnabled, isFalse);
      expect(model.mentorshipEnabled, isTrue);
    });

    test('themeColorValue converts hex to Color', () {
      final model = EventModel.fromJson(fakeEventJson(themeColor: '#FF5733'));
      expect(model.themeColorValue.toARGB32(), 0xFFFF5733);
    });

    test('canRegister is true for published and registration_open', () {
      for (final s in ['published', 'registration_open']) {
        final model = EventModel.fromJson({...fakeEventJson(), 'status': s});
        expect(model.canRegister, isTrue, reason: 'Expected canRegister for $s');
      }
      for (final s in ['draft', 'live', 'completed']) {
        final model = EventModel.fromJson({...fakeEventJson(), 'status': s});
        expect(model.canRegister, isFalse, reason: 'Expected !canRegister for $s');
      }
    });
  });

  group('EventType', () {
    test('apiValue round-trips through fromString', () {
      for (final type in EventType.values) {
        expect(EventType.fromString(type.apiValue), type);
      }
    });
  });

  group('SelectionMethod', () {
    test('apiValue round-trips through fromString', () {
      for (final method in SelectionMethod.values) {
        expect(SelectionMethod.fromString(method.apiValue), method);
      }
    });
  });
}
