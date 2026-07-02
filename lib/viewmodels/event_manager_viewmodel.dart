import 'package:flutter/foundation.dart';

import '../models/event_manager_models.dart';
import '../repositories/event_manager_repository.dart';
import '../repositories/impact_repository.dart';

enum EMLoadState { idle, loading, error }

class EventManagerViewModel extends ChangeNotifier {
  EMLoadState _state = EMLoadState.idle;
  String? _error;
  EventManagerStats _stats = EventManagerStats.empty;
  List<NGOEvent> _events = [];
  List<EMStudentAssignment> _assignments = [];
  List<EMImpactPost> _impactPosts = [];
  List<EMActivity> _activities = [];

  // True once loadImpactOnly() has been used instead of load() — keeps
  // subsequent refreshes from hitting the event-manager-only dashboard.
  bool _impactOnlyMode = false;

  // Activities loading is separate so the main dashboard doesn't block on it
  bool _activitiesLoading = false;
  String? _activitiesError;

  EMLoadState get state => _state;
  String? get error => _error;
  EventManagerStats get stats => _stats;
  List<NGOEvent> get events => List.unmodifiable(_events);
  List<EMStudentAssignment> get assignments => List.unmodifiable(_assignments);
  List<EMImpactPost> get impactPosts => List.unmodifiable(_impactPosts);
  List<EMActivity> get activities => List.unmodifiable(_activities);
  bool get activitiesLoading => _activitiesLoading;
  String? get activitiesError => _activitiesError;
  List<NGOEvent> get todayEvents {
    final now = DateTime.now();
    return _events
        .where(
          (event) =>
              event.date.year == now.year &&
              event.date.month == now.month &&
              event.date.day == now.day,
        )
        .toList();
  }

  List<NGOEvent> get activeEvents => _events
      .where(
        (event) =>
            event.status == EventStatus.ongoing ||
            event.status == EventStatus.registrationOpen,
      )
      .toList();
  List<EMStudentAssignment> get pendingSubmissions => _assignments
      .where((item) => item.status == AssignmentStatus.workSubmitted)
      .toList();
  List<EMStudentAssignment> get appliedStudents => _assignments
      .where((item) => item.status == AssignmentStatus.applied)
      .toList();
  List<EMStudentAssignment> get assignedStudents => _assignments
      .where(
        (item) =>
            item.status == AssignmentStatus.shortlisted ||
            item.status == AssignmentStatus.assigned,
      )
      .toList();
  List<EMImpactPost> get draftPosts =>
      _impactPosts.where((item) => !item.adminApproved).toList();
  List<EMImpactPost> get publishedPosts => _impactPosts
      .where((item) => item.adminApproved && item.isPublished)
      .toList();

  Future<void> load() async {
    _state = EMLoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await EventManagerRepository.dashboard();
      _stats = result.stats;
      _events = result.events;
      _assignments = result.assignments;
      _impactPosts = result.impacts;
      _state = EMLoadState.idle;
    } catch (error) {
      _error = error.toString();
      _state = EMLoadState.error;
    }
    notifyListeners();
  }

  /// Lightweight counterpart to [load] for roles (e.g. counsellor) that can
  /// create impact posts but shouldn't see the full event-manager dashboard
  /// (events, assignments, student submissions). Only populates impact posts.
  Future<void> loadImpactOnly() async {
    _impactOnlyMode = true;
    _state = EMLoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final posts = await ImpactRepository.getMine();
      _impactPosts = posts.map(EMImpactPost.fromImpactPost).toList();
      _state = EMLoadState.idle;
    } catch (error) {
      _error = error.toString();
      _state = EMLoadState.error;
    }
    notifyListeners();
  }

  /// Refreshes impact posts after a mutation, using whichever load path this
  /// view model was initialized with.
  Future<void> _refreshImpact() => _impactOnlyMode ? loadImpactOnly() : load();

  Future<void> updateAssignmentStatus(
    int id,
    AssignmentStatus status, {
    String? notes,
    String? instructions,
  }) async {
    await EventManagerRepository.updateAssignment(
      id,
      status,
      notes: notes,
      instructions: instructions,
    );
    await load();
  }

  Future<EMImpactPost> convertToImpactPost(
    EMStudentAssignment assignment,
  ) async {
    final id = await EventManagerRepository.createImpact(assignment);
    await load();
    return _impactPosts.firstWhere((post) => post.id == id);
  }

  Future<void> submitImpactPostForApproval(int postId) async {
    await EventManagerRepository.submitImpact(postId);
    await _refreshImpact();
  }

  Future<void> approveAndPublishImpactPost(int postId) async {
    await EventManagerRepository.publishImpact(postId);
    await _refreshImpact();
  }

  Future<void> deleteImpactPost(int postId) async {
    await EventManagerRepository.deleteImpact(postId);
    _impactPosts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }

  Future<EventReport> generateReport(int eventId) async {
    final response = await EventManagerRepository.generateReport(eventId);
    final event = _events.firstWhere((item) => item.id == eventId);
    final approved = _assignments
        .where(
          (item) =>
              item.event.id == eventId &&
              (item.status == AssignmentStatus.approved ||
                  item.status == AssignmentStatus.certificateEligible),
        )
        .toList();
    return EventReport(
      id: response['id'] as int,
      eventId: event.id,
      eventName: event.title,
      eventDate: event.date,
      location: event.location,
      volunteersParticipated: approved.length,
      peopleReached: approved.fold(
        0,
        (sum, item) => sum + (item.submission?.peopleReached ?? 0),
      ),
      totalDonationCollected: approved.fold(
        0,
        (sum, item) => sum + (item.submission?.donationCollected ?? 0),
      ),
      photoUrls: approved
          .expand((item) => item.submission?.photoUrls ?? const <String>[])
          .toList(),
      partnerSchool: event.partnerSchool,
      summary: response['summary'] as String? ?? '',
      outcomes: response['outcomes'] as String? ?? '',
      studentContributors: approved.map((item) => item.student.name).toList(),
      generatedAt: DateTime.now(),
    );
  }

  Future<void> loadActivities({String? status}) async {
    _activitiesLoading = true;
    _activitiesError = null;
    notifyListeners();
    try {
      _activities = await EventManagerRepository.getMyActivities(status: status);
    } catch (e) {
      _activitiesError = e.toString();
    }
    _activitiesLoading = false;
    notifyListeners();
  }

  Future<void> editActivity(int activityId, Map<String, dynamic> payload) async {
    final updated = await EventManagerRepository.editActivity(activityId, payload);
    final idx = _activities.indexWhere((a) => a.id == activityId);
    if (idx != -1) {
      _activities[idx] = updated;
      notifyListeners();
    }
  }

  /// Creates a new activity (linked to an event or standalone) and prepends it
  /// to the local activities list so the UI updates immediately.
  Future<EMActivity> createActivity({
    required String title,
    required String category,
    int? eventId,
    String? description,
    String? location,
    String? expectedWork,
    String? workInstructions,
    String? proofRequired,
    double rewardHours = 2.0,
    int maxStudents = 20,
    bool certificateEligible = true,
    double? stipendAmount,
    DateTime? startDate,
    DateTime? endDate,
    String status = 'active',
  }) async {
    final created = await EventManagerRepository.createActivity(
      title: title,
      category: category,
      eventId: eventId,
      description: description,
      location: location,
      expectedWork: expectedWork,
      workInstructions: workInstructions,
      proofRequired: proofRequired,
      rewardHours: rewardHours,
      maxStudents: maxStudents,
      certificateEligible: certificateEligible,
      stipendAmount: stipendAmount,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
    _activities = [created, ..._activities];
    notifyListeners();
    return created;
  }

  Future<void> addNewEvent(NGOEvent event) async {
    await EventManagerRepository.createEvent(event);
    await load();
  }

  Future<int> addImpactPost(
    EMImpactPost post, {
    List<Map<String, dynamic>> mediaList = const [],
  }) async {
    final id = await EventManagerRepository.createStandaloneImpact(
      post,
      mediaList: mediaList,
    );
    await _refreshImpact();
    return id;
  }

  Future<void> updateImpactPost(
    int postId,
    EMImpactPost post, {
    List<Map<String, dynamic>>? mediaList,
  }) async {
    await EventManagerRepository.updateStandaloneImpact(
      postId,
      post,
      mediaList: mediaList,
    );
    await _refreshImpact();
  }
}
