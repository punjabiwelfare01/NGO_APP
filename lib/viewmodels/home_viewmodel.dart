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
  DailyChallengeModel? _dailyChallenge;
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<SkillCategory> get categories => _categories;
  ApiCounsellingSession? get upcomingSession => _upcomingSession;
  List<ApiCounsellingSession> get allUpcomingSessions => _allUpcomingSessions;
  List<ApiCounsellingSlot> get availableSlots => _availableSlots;
  EventModel? get upcomingCounsellingEvent => _upcomingCounsellingEvent;
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
      ]);
      _categories = results[0] as List<SkillCategory>;
      final sessions = results[1] as List<ApiCounsellingSession>;
      _dailyChallenge = results[2] as DailyChallengeModel?;
      final counsellingEvents = results[3] as List<EventModel>;
      _availableSlots = results[4] as List<ApiCounsellingSlot>;
      _allUpcomingSessions = sessions.where((s) => s.isUpcoming).toList();
      _upcomingSession = _allUpcomingSessions.firstOrNull;
      _upcomingCounsellingEvent = _nextBookableCounsellingEvent(
        counsellingEvents,
      );
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
}
