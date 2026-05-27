import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models/api_models.dart';
import '../models/counselling_models.dart';
import '../repositories/api_client.dart';
import '../repositories/counselling_repository.dart';
import '../repositories/wellness_repository.dart';
import 'view_state.dart';

class CounsellingViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  List<MentorProfile> _mentors = [];
  List<ApiCounsellingSlot> _slots = [];
  List<ApiCounsellingSession> _mySessions = [];
  CounsellingAnalytics? _analytics;
  String? _selectedCategory;
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<MentorProfile> get mentors => _mentors;
  List<ApiCounsellingSlot> get slots => _slots;
  List<ApiCounsellingSession> get mySessions => _mySessions;
  CounsellingAnalytics? get analytics => _analytics;
  String? get selectedCategory => _selectedCategory;

  List<ApiCounsellingSession> get upcomingSessions =>
      _mySessions.where((s) => s.isUpcoming).toList();

  ApiCounsellingSession? get liveSession => _mySessions
      .where((s) => s.isUpcoming && s.hasMeetingLink)
      .firstOrNull;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    _state = ViewState.loading;
    _errorMessage = null;
    if (!_disposed) notifyListeners();

    try {
      final futures = await Future.wait([
        CounsellingRepository.getMentors(category: _selectedCategory),
        CounsellingRepository.getSlots(category: _selectedCategory),
        WellnessRepository.getCounsellingSessions(AppState.userId),
      ]);
      _mentors = futures[0] as List<MentorProfile>;
      _slots = futures[1] as List<ApiCounsellingSlot>;
      _mySessions = futures[2] as List<ApiCounsellingSession>;
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

  Future<void> loadAnalytics() async {
    try {
      _analytics = await CounsellingRepository.getAnalytics();
      if (!_disposed) notifyListeners();
    } catch (_) {}
  }

  void filterByCategory(String? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    load();
  }

  Future<bool> bookSlot(int slotId, String topic) async {
    try {
      await WellnessRepository.bookAvailabilitySlot(
        AppState.userId,
        slotId: slotId,
        topic: topic,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createMentorProfile(Map<String, dynamic> data) async {
    try {
      await CounsellingRepository.createMentorProfile(data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMentorProfile(int id, Map<String, dynamic> data) async {
    try {
      await CounsellingRepository.updateMentorProfile(id, data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
