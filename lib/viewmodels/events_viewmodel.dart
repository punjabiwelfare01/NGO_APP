import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/event_manager_models.dart';
import '../models/unified_event.dart';
import '../repositories/api_client.dart';
import '../repositories/event_manager_repository.dart';
import '../repositories/event_repository.dart';
import 'event_manager_viewmodel.dart';
import 'view_state.dart';

/// Single view model behind the unified "Events" module, replacing
/// `EventListViewModel` (old admin "Events & Activities") and
/// `EventPipelineViewModel` (old admin "Event Pipeline"). Used by both the
/// Admin Manage tab and the Event Manager's own Events tab — [isAdmin] gates
/// which actions/next-steps are exposed rather than needing a second class.
class EventsViewModel extends ChangeNotifier {
  EventsViewModel({required this.isAdmin});

  final bool isAdmin;

  // Two singletons (not one) since Admin and Event Manager need independent
  // `isAdmin` gating — they otherwise both wrap the same dashboard() data.
  static EventsViewModel? _sharedAdmin;
  static EventsViewModel? _sharedEventManager;

  static EventsViewModel shared({required bool isAdmin}) {
    if (isAdmin) {
      if (_sharedAdmin == null) {
        _sharedAdmin = EventsViewModel(isAdmin: true);
        AppState.registerCacheReset(_sharedAdmin!._resetCache);
      }
      return _sharedAdmin!;
    }
    if (_sharedEventManager == null) {
      _sharedEventManager = EventsViewModel(isAdmin: false);
      AppState.registerCacheReset(_sharedEventManager!._resetCache);
    }
    return _sharedEventManager!;
  }

  void _resetCache() {
    _loaded = false;
    _events = [];
    _search = '';
    notifyListeners();
  }

  /// Marks both cached dashboard instances stale without an immediate
  /// refetch — called by [EventManagerViewModel] when it mutates event data
  /// via its own cached instance, so an already-open Events tab doesn't keep
  /// serving a now-outdated events list.
  static void invalidateCaches() {
    _sharedAdmin?._loaded = false;
    _sharedEventManager?._loaded = false;
  }

  bool _loaded = false;
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  List<UnifiedEvent> _events = [];
  String _search = '';

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;

  List<UnifiedEvent> get all => _filtered(_events);

  List<UnifiedEvent> get needsAttention =>
      _filtered(_events.where((e) => e.needsAttention).toList());

  List<UnifiedEvent> get upcoming => _filtered(_events
      .where((e) =>
          e.uiStatus == EventUiStatus.published ||
          e.uiStatus == EventUiStatus.registrationOpen ||
          e.uiStatus == EventUiStatus.scheduled)
      .toList());

  List<UnifiedEvent> get live =>
      _filtered(_events.where((e) => e.uiStatus == EventUiStatus.live).toList());

  List<UnifiedEvent> get completed => _filtered(_events
      .where((e) =>
          e.uiStatus == EventUiStatus.completed ||
          e.uiStatus == EventUiStatus.reviewPending)
      .toList());

  List<UnifiedEvent> get archived =>
      _filtered(_events.where((e) => e.uiStatus == EventUiStatus.archived).toList());

  int get needsAttentionCount =>
      _events.where((e) => e.needsAttention).length;

  void search(String query) {
    _search = query.trim().toLowerCase();
    notifyListeners();
  }

  List<UnifiedEvent> _filtered(List<UnifiedEvent> source) {
    if (_search.isEmpty) return source;
    return source.where((u) {
      final e = u.event;
      return e.title.toLowerCase().contains(_search) ||
          e.location.toLowerCase().contains(_search) ||
          (e.partnerSchool?.toLowerCase().contains(_search) ?? false);
    }).toList();
  }

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await EventManagerRepository.dashboard();
      final assignmentsByEvent = <int, List<EMStudentAssignment>>{};
      for (final a in result.assignments) {
        assignmentsByEvent.putIfAbsent(a.event.id, () => []).add(a);
      }
      final impactByEvent = <int, EMImpactPost>{};
      for (final post in result.impacts) {
        if (post.eventId != null) impactByEvent[post.eventId!] = post;
      }
      _events = result.events
          .map((e) => UnifiedEvent(
                event: e,
                assignments: assignmentsByEvent[e.id] ?? const [],
                impactPost: impactByEvent[e.id],
              ))
          .toList();
      _state = ViewState.idle;
      _loaded = true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ViewState.error;
    }
    notifyListeners();
  }

  // ── Actions — all delegate to existing, already-working repository calls.

  Future<void> reviewSubmission(
    EMStudentAssignment assignment, {
    required AssignmentStatus status,
    String? notes,
  }) async {
    await EventManagerRepository.updateAssignment(
      assignment.id,
      status,
      notes: notes,
    );
    await load(force: true);
  }

  /// Creates one event-level impact post aggregating all of this event's
  /// assignments — mirrors the aggregation the old
  /// `EventPipelineViewModel.generateImpactDraft` used (title/description/
  /// volunteer names/totals/photos rolled up across every assignment),
  /// rather than the repository's `createImpact(assignment)` which is
  /// scoped to a single assignment.
  Future<void> createImpactDraftForEvent(UnifiedEvent unified) async {
    final event = unified.event;
    final assignments = unified.assignments;
    final volunteerNames =
        assignments.map((a) => a.student.name).toSet().toList();
    final totalHours = assignments.fold(
        0.0, (sum, a) => sum + (a.submission?.hoursWorked ?? 0.0));
    final totalPeopleReached = assignments.fold(
        0, (sum, a) => sum + (a.submission?.peopleReached ?? 0));
    final totalDonation = assignments.fold(
        0.0, (sum, a) => sum + (a.submission?.donationCollected ?? 0.0));
    final photoUrls = assignments
        .expand((a) => a.submission?.photoUrls ?? const <String>[])
        .toList();
    final description =
        '${event.title} was successfully conducted at ${event.location}. '
        '${assignments.length} volunteers participated and collectively '
        'reached $totalPeopleReached beneficiaries. ${event.description}';

    await ApiClient.post('/impact/posts', {
      'category': 'achievement',
      'title': event.title,
      'description': description,
      'event_id': event.id,
      'student_names': volunteerNames.join(', '),
      'location': event.location,
      'people_reached': totalPeopleReached,
      'donation_collected': totalDonation,
      'hours_served': totalHours,
      'media': photoUrls.map((url) => {'media_type': 'image', 'url': url}).toList(),
    });
    await load(force: true);
  }

  Future<void> submitImpactForApproval(int postId) async {
    await EventManagerRepository.submitImpact(postId);
    await load(force: true);
  }

  Future<void> approveAndPublishImpact(int postId) async {
    await EventManagerRepository.publishImpact(postId);
    await load(force: true);
  }

  Future<void> generateReport(int eventId) async {
    await EventManagerRepository.ensureReport(eventId);
    await load(force: true);
  }

  Future<void> publish(UnifiedEvent event) async {
    await EventRepository.publishEvent(event.event.id);
    await load(force: true);
    EventManagerViewModel.invalidateCache();
  }

  /// Admin/super_admin only on the backend (`/events/{id}/status`) — callers
  /// must check `isAdmin` before offering this (see
  /// `UnifiedEvent.nextAction`'s "Mark Completed" gating).
  Future<void> advanceStatus(UnifiedEvent event, String newStatus) async {
    await EventRepository.advanceStatus(event.event.id, newStatus);
    await load(force: true);
    EventManagerViewModel.invalidateCache();
  }

  /// Admin/super_admin only on the backend (`DELETE /events/{id}`).
  Future<void> deleteEvent(UnifiedEvent event) async {
    await EventRepository.deleteEvent(event.event.id);
    await load(force: true);
    EventManagerViewModel.invalidateCache();
  }

  Future<void> createEvent(NGOEvent event) async {
    await EventManagerRepository.createEvent(event);
    await load(force: true);
    EventManagerViewModel.invalidateCache();
  }
}
