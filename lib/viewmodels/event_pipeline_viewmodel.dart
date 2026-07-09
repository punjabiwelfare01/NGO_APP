import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/event_manager_models.dart' hide EventReport;
import '../models/event_pipeline_models.dart';
import '../repositories/api_client.dart';
import '../repositories/event_manager_repository.dart';

class EventPipelineViewModel extends ChangeNotifier {
  bool _loaded = false;
  bool _loading = false;
  bool _disposed = false;
  String? _error;

  List<PipelineEvent> _events = [];
  PipelineStats _stats = PipelineStats.empty;

  List<PipelineEvent> get events => List.unmodifiable(_events);
  PipelineStats get stats => _stats;
  bool get isLoading => _loading;
  String? get error => _error;

  List<PipelineEvent> get activeEvents =>
      _events.where((e) => e.status.isActive).toList();
  List<PipelineEvent> get upcomingEvents => _events
      .where((e) =>
          e.status.isPreEvent && e.status != PipelineEventStatus.draft)
      .toList();
  List<PipelineEvent> get todayEvents =>
      _events.where((e) => e.isToday).toList();
  List<PipelineEvent> get completedEvents =>
      _events.where((e) => e.status.isPostEvent).toList();
  List<PipelineEvent> get pendingAdminApproval => _events
      .where((e) => e.status == PipelineEventStatus.adminApprovalPending)
      .toList();

  List<PipelineAssignment> get allPendingSubmissions =>
      _events.expand((e) => e.pendingEmReview).toList();

  List<ImpactPostDraft> get pendingImpactDrafts => _events
      .where((e) =>
          e.impactDraft != null &&
          e.impactDraft!.status != ImpactPostDraftStatus.published)
      .map((e) => e.impactDraft!)
      .toList();

  // ─── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    _loading = true;
    _error = null;
    if (!_disposed) notifyListeners();
    try {
      final result = await EventManagerRepository.dashboard();
      final byEvent = <int, List<EMStudentAssignment>>{};
      for (final a in result.assignments) {
        byEvent.putIfAbsent(a.event.id, () => []).add(a);
      }
      _events = result.events
          .map((e) => _buildPipelineEvent(e, byEvent[e.id] ?? []))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _loaded = false;
      _events = [];
    }
    _loading = false;
    _recalcStats();
    if (!_disposed) notifyListeners();
  }

  Future<void> reload() async {
    _loaded = false;
    await load();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> advanceEventStatus(int eventId) async {
    _updateEvent(eventId, (e) {
      final nextIndex = e.status.pipelineIndex + 1;
      if (nextIndex >= PipelineEventStatus.pipeline.length) return e;
      return e.copyWith(status: PipelineEventStatus.pipeline[nextIndex]);
    });
    try {
      await ApiClient.post('/events/$eventId/status', {});
    } catch (_) {}
  }

  void setEventStatus(int eventId, PipelineEventStatus newStatus) {
    _updateEvent(eventId, (e) => e.copyWith(status: newStatus));
  }

  Future<void> approveSubmission(
      int eventId, int activityId, int assignmentId) async {
    _updateAssignment(
        eventId,
        activityId,
        assignmentId,
        (a) => a.copyWith(
              status: PipelineAssignmentStatus.eventManagerVerified,
              verifiedAt: DateTime.now(),
            ));
    try {
      await EventManagerRepository.updateAssignment(
          assignmentId, AssignmentStatus.verified);
    } catch (_) {}
  }

  Future<void> requestResubmission(int eventId, int activityId,
      int assignmentId, String note) async {
    _updateAssignment(
        eventId,
        activityId,
        assignmentId,
        (a) => a.copyWith(
              status: PipelineAssignmentStatus.resubmissionRequested,
              reviewerNotes: note,
            ));
    try {
      await EventManagerRepository.updateAssignment(
          assignmentId, AssignmentStatus.assigned,
          notes: note);
    } catch (_) {}
  }

  Future<void> rejectSubmission(int eventId, int activityId, int assignmentId,
      String note) async {
    _updateAssignment(
        eventId,
        activityId,
        assignmentId,
        (a) => a.copyWith(
              status: PipelineAssignmentStatus.rejected,
              reviewerNotes: note,
            ));
    try {
      await EventManagerRepository.updateAssignment(
          assignmentId, AssignmentStatus.rejected,
          notes: note);
    } catch (_) {}
  }

  Future<void> adminApproveAssignment(
      int eventId, int activityId, int assignmentId) async {
    _updateAssignment(
        eventId,
        activityId,
        assignmentId,
        (a) => a.copyWith(
              status: PipelineAssignmentStatus.adminApproved,
              approvedAt: DateTime.now(),
            ));
    try {
      await EventManagerRepository.updateAssignment(
          assignmentId, AssignmentStatus.approved);
    } catch (_) {}
  }

  Future<void> generateCertificate(
      int eventId, int activityId, int assignmentId) async {
    _updateAssignment(eventId, activityId, assignmentId, (a) {
      final cert = PipelineCertificate(
        id: a.id * 100,
        certificateId:
            'PWT-CERT-2026-${a.id.toString().padLeft(3, '0')}',
        assignmentId: a.id,
        eventId: a.eventId,
        studentName: a.studentName,
        eventName: a.eventTitle,
        activityName: a.activityTitle,
        hoursServed: a.submission?.hoursWorked ?? 4.0,
        issueDate: DateTime.now(),
        status: PipelineCertificateStatus.pendingPhysicalSign,
      );
      return a.copyWith(
        status: PipelineAssignmentStatus.certificateGenerated,
        certificate: cert,
      );
    });
    try {
      await EventManagerRepository.updateAssignment(
          assignmentId, AssignmentStatus.certificateEligible);
    } catch (_) {}
  }

  Future<void> generateImpactDraft(int eventId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final event = _events[idx];
    final allAssignments = event.allAssignments;
    final volunteerNames =
        allAssignments.map((a) => a.studentName).toSet().toList();
    final totalHours = allAssignments.fold(
        0.0, (s, a) => s + (a.submission?.hoursWorked ?? 0.0));
    final photoUrls = allAssignments
        .expand((a) => a.submission?.photoUrls ?? <String>[])
        .toList();
    final description =
        '${event.title} was successfully conducted at ${event.location} on '
        '${_formatDate(event.date)}. ${event.totalAssigned} volunteers participated '
        'and collectively reached ${event.totalPeopleReached} beneficiaries. '
        '${event.description}';

    int postId;
    try {
      final data = await ApiClient.post('/impact/posts', {
        'category': 'eventSuccessReport',
        'title': event.title,
        'description': description,
        'event_id': eventId,
        'student_names': volunteerNames.join(', '),
        'location': event.location,
        'people_reached': event.totalPeopleReached,
        'donation_collected': event.totalDonationCollected,
        'hours_served': totalHours,
        'media': photoUrls
            .map((url) => {'media_type': 'image', 'url': url})
            .toList(),
      }) as Map<String, dynamic>;
      postId = data['id'] as int;
    } catch (_) {
      postId = eventId * 10;
    }

    final draft = ImpactPostDraft(
      id: postId,
      eventId: eventId,
      eventName: event.title,
      eventCategory: event.category,
      location: event.location,
      eventDate: event.date,
      volunteerNames: volunteerNames,
      totalVolunteers: event.totalAssigned,
      peopleReached: event.totalPeopleReached,
      donationCollected: event.totalDonationCollected,
      certificatesIssued: event.certificatesGenerated,
      partnerSchool: event.partnerSchool,
      description: description,
      appreciationMessage:
          'We extend our heartfelt gratitude to all volunteers and '
          '${event.assignedEventManagerName} for making this event a success. '
          'Together we are building a stronger community.',
      createdAt: DateTime.now(),
    );
    final updated = event.copyWith(
      impactDraft: draft,
      status: event.status == PipelineEventStatus.completed
          ? PipelineEventStatus.impactPublished
          : event.status,
    );
    _events = List.of(_events)..[idx] = updated;
    _recalcStats();
    if (!_disposed) notifyListeners();
  }

  void saveImpactDraft(int eventId,
      {required String description, required String appreciationMessage}) {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final event = _events[idx];
    if (event.impactDraft == null) return;
    final updatedDraft = event.impactDraft!.copyWith(
      description: description,
      appreciationMessage: appreciationMessage,
      status: ImpactPostDraftStatus.emEdited,
    );
    _events = List.of(_events)..[idx] =
        event.copyWith(impactDraft: updatedDraft);
    _recalcStats();
    if (!_disposed) notifyListeners();
  }

  Future<void> submitImpactDraftForApproval(int eventId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final postId = _events[idx].impactDraft?.id;
    _updateImpactDraft(
        eventId, (d) => d.copyWith(status: ImpactPostDraftStatus.emEdited));
    if (postId != null) {
      try {
        await EventManagerRepository.submitImpact(postId);
      } catch (_) {}
    }
  }

  void adminApproveImpactPost(int eventId) {
    _updateImpactDraft(eventId,
        (d) => d.copyWith(status: ImpactPostDraftStatus.adminApproved));
  }

  Future<void> publishImpactPost(int eventId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final postId = _events[idx].impactDraft?.id;
    _updateImpactDraft(
        eventId, (d) => d.copyWith(status: ImpactPostDraftStatus.published));
    if (postId != null) {
      try {
        await EventManagerRepository.publishImpact(postId);
      } catch (_) {}
    }
  }

  Future<void> generateReport(int eventId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final event = _events[idx];

    int reportId;
    try {
      reportId = await EventManagerRepository.ensureReport(eventId);
    } catch (_) {
      reportId = eventId * 10 + 1;
    }

    final report = EventReport(
      id: reportId,
      eventId: eventId,
      eventName: event.title,
      category: event.category,
      eventDate: event.date,
      location: event.location,
      isOnline: event.isOnline,
      eventManagerName: event.assignedEventManagerName,
      volunteerNames:
          event.allAssignments.map((a) => a.studentName).toSet().toList(),
      totalVolunteers: event.totalAssigned,
      studentsReached: event.totalPeopleReached,
      donationsCollected: event.totalDonationCollected,
      certificatesIssued: event.certificatesGenerated,
      activityTitles: event.activities.map((a) => a.title).toList(),
      partnerDetails: event.partnerSchool != null
          ? 'Partner: ${event.partnerSchool}'
          : null,
      counsellorDetails: event.assignedCounsellorName != null
          ? 'Counsellor: ${event.assignedCounsellorName}'
          : null,
      outcomes:
          'The event successfully engaged ${event.totalAssigned} volunteers who reached '
          '${event.totalPeopleReached} beneficiaries. ${event.certificatesGenerated} certificates '
          'were issued and ₹${event.totalDonationCollected.toStringAsFixed(0)} was collected '
          'in donations.',
      generatedAt: DateTime.now(),
    );
    final updated = event.copyWith(report: report);
    _events = List.of(_events)..[idx] = updated;
    _recalcStats();
    if (!_disposed) notifyListeners();
  }

  Future<void> finaliseReport(int eventId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final event = _events[idx];
    if (event.report == null) return;
    final updated = event.copyWith(
        report:
            event.report!.copyWith(status: EventReportStatus.finalised));
    _events = List.of(_events)..[idx] = updated;
    _recalcStats();
    if (!_disposed) notifyListeners();
    try {
      await EventManagerRepository.finalizeReport(
          eventId, event.report!.id);
    } catch (_) {}
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  void _updateEvent(int id, PipelineEvent Function(PipelineEvent) fn) {
    final idx = _events.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _events = List.of(_events)..[idx] = fn(_events[idx]);
    _recalcStats();
    if (!_disposed) notifyListeners();
  }

  void _updateAssignment(
    int eventId,
    int activityId,
    int assignmentId,
    PipelineAssignment Function(PipelineAssignment) fn,
  ) {
    _updateEvent(eventId, (event) {
      final acts = event.activities.map((act) {
        if (act.id != activityId) return act;
        final asgnList = act.assignments.map((a) {
          if (a.id != assignmentId) return a;
          return fn(a);
        }).toList();
        return act.copyWith(assignments: asgnList);
      }).toList();
      return event.copyWith(activities: acts);
    });
  }

  void _updateImpactDraft(
      int eventId, ImpactPostDraft Function(ImpactPostDraft) fn) {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final event = _events[idx];
    if (event.impactDraft == null) return;
    _events = List.of(_events)..[idx] =
        event.copyWith(impactDraft: fn(event.impactDraft!));
    _recalcStats();
    if (!_disposed) notifyListeners();
  }

  void _recalcStats() {
    final allAssignments = _events.expand((e) => e.allAssignments).toList();
    _stats = PipelineStats(
      totalEvents: _events.length,
      activeEvents: _events.where((e) => e.status.isActive).length,
      pendingEmReviews: allAssignments
          .where((a) =>
              a.status == PipelineAssignmentStatus.submitted)
          .length,
      pendingAdminApprovals: allAssignments
          .where((a) =>
              a.status == PipelineAssignmentStatus.eventManagerVerified)
          .length,
      certificatesToGenerate: allAssignments
          .where(
              (a) => a.status == PipelineAssignmentStatus.adminApproved)
          .length,
      impactDraftsPending: _events
          .where((e) =>
              e.impactDraft != null &&
              e.impactDraft!.status != ImpactPostDraftStatus.published)
          .length,
      reportsPending: _events
          .where((e) => e.status.isPostEvent && !e.hasReport)
          .length,
      studentsReachedTotal:
          _events.fold(0, (s, e) => s + e.totalPeopleReached),
      donationsTotal:
          _events.fold(0.0, (s, e) => s + e.totalDonationCollected),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ─── Data conversion ───────────────────────────────────────────────────────

  static PipelineEventStatus _mapEventStatus(EventStatus s) => switch (s) {
        EventStatus.draft => PipelineEventStatus.draft,
        EventStatus.published => PipelineEventStatus.published,
        EventStatus.registrationOpen => PipelineEventStatus.registrationOpen,
        EventStatus.ongoing => PipelineEventStatus.ongoing,
        EventStatus.completed => PipelineEventStatus.completed,
        EventStatus.archived => PipelineEventStatus.archived,
      };

  static PipelineAssignmentStatus _mapAssignmentStatus(
          AssignmentStatus s) =>
      switch (s) {
        AssignmentStatus.applied => PipelineAssignmentStatus.applied,
        AssignmentStatus.shortlisted => PipelineAssignmentStatus.applied,
        AssignmentStatus.assigned => PipelineAssignmentStatus.assigned,
        AssignmentStatus.workSubmitted => PipelineAssignmentStatus.submitted,
        AssignmentStatus.verified =>
          PipelineAssignmentStatus.eventManagerVerified,
        AssignmentStatus.approved => PipelineAssignmentStatus.adminApproved,
        AssignmentStatus.certificateEligible =>
          PipelineAssignmentStatus.certificateGenerated,
        AssignmentStatus.rejected => PipelineAssignmentStatus.rejected,
      };

  static PipelineAssignment _buildAssignment(EMStudentAssignment a) {
    final sub = a.submission;
    return PipelineAssignment(
      id: a.id,
      activityId: a.activity.id,
      eventId: a.event.id,
      studentName: a.student.name,
      studentEmail: a.student.email,
      activityTitle: a.activity.title,
      eventTitle: a.event.title,
      dueDate: a.event.date.add(const Duration(days: 7)),
      status: _mapAssignmentStatus(a.status),
      instructions: a.instructions,
      reviewerNotes: a.reviewerNotes,
      assignedAt: a.appliedAt,
      submittedAt: sub?.submittedAt,
      submission: sub == null
          ? null
          : PipelineWorkSubmission(
              id: sub.id,
              assignmentId: sub.assignmentId,
              workTitle: sub.workTitle,
              description: sub.description,
              hoursWorked: sub.hoursWorked,
              peopleReached: sub.peopleReached,
              remarks: sub.remarks,
              photoUrls: sub.photoUrls,
              donationProof: (sub.donationCollected != null &&
                      (sub.donationCollected ?? 0) > 0)
                  ? PipelineDonationProof(
                      id: sub.id,
                      assignmentId: a.id,
                      amount: sub.donationCollected!,
                      transactionId: sub.transactionId ?? '',
                      donationDate: sub.submittedAt,
                      status: DonationProofStatus.pending,
                    )
                  : null,
              submittedAt: sub.submittedAt,
            ),
    );
  }

  static PipelineActivity _buildActivity(
      EventActivity act, List<EMStudentAssignment> actAssignments) {
    return PipelineActivity(
      id: act.id,
      eventId: act.eventId,
      title: act.title,
      role: act.role,
      description: act.description,
      maxStudents: act.maxStudents,
      hasCertificate: true,
      assignments: actAssignments.map(_buildAssignment).toList(),
    );
  }

  static PipelineEvent _buildPipelineEvent(
      NGOEvent e, List<EMStudentAssignment> assignments) {
    final byActivity = <int, List<EMStudentAssignment>>{};
    for (final a in assignments) {
      byActivity.putIfAbsent(a.activity.id, () => []).add(a);
    }
    return PipelineEvent(
      id: e.id,
      title: e.title,
      category: e.category,
      status: _mapEventStatus(e.status),
      date: e.date,
      location: e.location,
      partnerSchool: e.partnerSchool,
      description: e.description,
      bannerImageUrl: e.bannerImageUrl,
      maxVolunteers: e.maxVolunteers,
      assignedEventManagerName: 'Event Manager',
      certificateEligible: e.certificateEligible,
      donationEligible: e.donationEligible,
      stipendEligible: e.stipendAmount != null,
      stipendAmount: e.stipendAmount,
      expectedWork: e.expectedWork,
      proofRequired: e.proofRequired,
      activities: e.activities
          .map((act) =>
              _buildActivity(act, byActivity[act.id] ?? []))
          .toList(),
      createdAt: e.createdAt,
    );
  }

  // ─── Shared instance ───────────────────────────────────────────────────────

  static EventPipelineViewModel? _shared;
  static EventPipelineViewModel get shared {
    if (_shared == null) {
      _shared = EventPipelineViewModel();
      AppState.registerCacheReset(_shared!._resetCache);
    }
    return _shared!;
  }

  void _resetCache() {
    _loaded = false;
    _events = [];
    _stats = PipelineStats.empty;
    if (!_disposed) notifyListeners();
  }
}
