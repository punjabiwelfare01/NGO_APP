import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models/api_models.dart';
import '../models/event_models.dart';
import '../models/quiz_models.dart';
import '../models/skill_category.dart';
import '../repositories/api_client.dart';
import '../repositories/course_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/quiz_repository.dart';
import '../repositories/wellness_repository.dart';
import 'view_state.dart';

class HomeViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  List<SkillCategory> _categories = [];
  ApiCounsellingSession? _upcomingSession;
  List<ApiCounsellingSession> _allUpcomingSessions = [];
  List<ApiCounsellingSlot> _availableSlots = [];
  EventModel? _upcomingCounsellingEvent;
  List<EventModel> _upcomingEvents = [];
  DailyChallengeModel? _dailyChallenge;
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<SkillCategory> get categories => _categories;
  ApiCounsellingSession? get upcomingSession => _upcomingSession;
  List<ApiCounsellingSession> get allUpcomingSessions => _allUpcomingSessions;
  List<ApiCounsellingSlot> get availableSlots => _availableSlots;
  EventModel? get upcomingCounsellingEvent => _upcomingCounsellingEvent;
  List<EventModel> get upcomingEvents => _upcomingEvents;
  DailyChallengeModel? get dailyChallenge => _dailyChallenge;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (!AppState.isAuthenticated) {
      _state = ViewState.error;
      _errorMessage = 'Please sign in again to load your home dashboard.';
      notifyListeners();
      return;
    }
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        CourseRepository.getCategories(),
        WellnessRepository.getCounsellingSessions(AppState.userId),
        QuizRepository.getDailyChallenge(),
        EventRepository.getEvents(
          eventType: EventType.counsellingDrive.apiValue,
        ),
        WellnessRepository.getAvailableSlots(AppState.userId),
        EventRepository.getEvents(),
      ]);
      _categories = _mergeCoreSkillCategories(
        results[0] as List<SkillCategory>,
      );
      final sessions = results[1] as List<ApiCounsellingSession>;
      _dailyChallenge = results[2] as DailyChallengeModel?;
      final counsellingEvents = results[3] as List<EventModel>;
      _availableSlots = results[4] as List<ApiCounsellingSlot>;
      final events = results[5] as List<EventModel>;
      _allUpcomingSessions = sessions.where((s) => s.isUpcoming).toList();
      _upcomingSession = _allUpcomingSessions.firstOrNull;
      _upcomingCounsellingEvent = _nextBookableCounsellingEvent(
        counsellingEvents,
      );
      _upcomingEvents = _publicUpcomingEvents(events);
      _state = ViewState.idle;
    } on ApiException catch (e) {
      _state = ViewState.error;
      _errorMessage = e.statusCode == 401
          ? 'Your session expired. Please sign in again.'
          : 'Server error (${e.statusCode}). Please try again.';
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Could not reach the server. Is the backend running?';
    }
    if (!_disposed) notifyListeners();
  }

  EventModel? _nextBookableCounsellingEvent(List<EventModel> events) {
    final bookable =
        events
            .where(
              (event) => event.canRegister || event.status == EventStatus.live,
            )
            .toList()
          ..sort((a, b) {
            final aDate = a.eventStart ?? a.startDate ?? a.createdAt;
            final bDate = b.eventStart ?? b.startDate ?? b.createdAt;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });
    return bookable.isEmpty ? null : bookable.first;
  }

  List<EventModel> _publicUpcomingEvents(List<EventModel> events) {
    final now = DateTime.now();
    final upcoming =
        events.where((event) {
          final public =
              event.status == EventStatus.published ||
              event.status == EventStatus.registrationOpen ||
              event.status == EventStatus.live;
          final notExpired =
              event.registrationEnd == null ||
              event.registrationEnd!.isAfter(now);
          return public && notExpired;
        }).toList()..sort((a, b) {
          final aDate = a.registrationEnd ?? a.eventStart ?? a.createdAt;
          final bDate = b.registrationEnd ?? b.eventStart ?? b.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
    return upcoming.take(6).toList();
  }

  List<SkillCategory> _mergeCoreSkillCategories(
    List<SkillCategory> apiCategories,
  ) {
    final merged = [...skillCategories];
    for (final category in apiCategories) {
      final index = merged.indexWhere(
        (item) => _skillsMatch(item.title, category.title),
      );
      if (index != -1) {
        final core = merged[index];
        merged[index] = SkillCategory(
          core.title,
          core.icon,
          core.color,
          id: category.id,
        );
        continue;
      }
      final isDuplicate = merged.any(
        (item) => _skillsMatch(item.title, category.title),
      );
      if (!isDuplicate) merged.add(category);
    }
    return merged;
  }

  bool _skillsMatch(String left, String right) {
    final leftKeys = _keywordsForSkill(left).toSet();
    final rightKeys = _keywordsForSkill(right).toSet();
    return leftKeys.intersection(rightKeys).isNotEmpty ||
        _skillKey(left) == _skillKey(right);
  }

  List<String> _keywordsForSkill(String title) {
    final lower = title.toLowerCase();
    final keys = <String>{_skillKey(title), ...lower.split(RegExp(r'\s+'))};
    if (lower.contains('communication')) keys.add('communication');
    if (lower.contains('digital') ||
        lower.contains('coding') ||
        lower.contains('computer') ||
        lower.contains('web')) {
      keys.addAll(['digital', 'coding', 'computer', 'web']);
    }
    if (lower.contains('career') ||
        lower.contains('job') ||
        lower.contains('interview')) {
      keys.addAll(['career', 'job', 'interview']);
    }
    if (lower.contains('safety') ||
        lower.contains('cyber') ||
        lower.contains('security')) {
      keys.addAll(['safety', 'cyber', 'security']);
    }
    if (lower.contains('financial') ||
        lower.contains('finance') ||
        lower.contains('money')) {
      keys.addAll(['financial', 'finance', 'money']);
    }
    return keys.where((key) => key.isNotEmpty).toList();
  }

  String _skillKey(String value) => value
      .toLowerCase()
      .replaceAll('skills', '')
      .replaceAll('skill', '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
