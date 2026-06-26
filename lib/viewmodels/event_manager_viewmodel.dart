import 'package:flutter/foundation.dart';

import '../models/event_manager_models.dart';
import '../repositories/event_manager_repository.dart';

enum EMLoadState { idle, loading, error }

class EventManagerViewModel extends ChangeNotifier {
  EMLoadState _state = EMLoadState.idle;
  String? _error;
  EventManagerStats _stats = EventManagerStats.empty;
  List<NGOEvent> _events = [];
  List<EMStudentAssignment> _assignments = [];
  List<EMImpactPost> _impactPosts = [];

  EMLoadState get state => _state;
  String? get error => _error;
  EventManagerStats get stats => _stats;
  List<NGOEvent> get events => List.unmodifiable(_events);
  List<EMStudentAssignment> get assignments => List.unmodifiable(_assignments);
  List<EMImpactPost> get impactPosts => List.unmodifiable(_impactPosts);
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
    await load();
  }

  Future<void> approveAndPublishImpactPost(int postId) async {
    await EventManagerRepository.publishImpact(postId);
    await load();
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

  Future<void> addNewEvent(NGOEvent event) async {
    await EventManagerRepository.createEvent(event);
    await load();
  }

  Future<void> addImpactPost(EMImpactPost post) async {
    await EventManagerRepository.createStandaloneImpact(post);
    await load();
  }
}
