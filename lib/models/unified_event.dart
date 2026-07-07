import 'package:flutter/material.dart';

import 'event_manager_models.dart';

/// The 8 statuses shown to users, replacing both the admin's old 4-state
/// "Events & Activities" filter and the old 12-stage (mostly fictional)
/// Event Pipeline. Derived entirely from the real 6-value [EventStatus]
/// (`event_manager_models.dart`) plus real assignment/impact-post state —
/// [scheduled] and [reviewPending] are the only two buckets that don't map
/// 1:1 to a raw backend status; they're computed from registration
/// capacity and submission/impact completeness respectively.
enum EventUiStatus {
  draft,
  published,
  registrationOpen,
  scheduled,
  live,
  reviewPending,
  completed,
  archived;

  String get label => switch (this) {
        draft => 'Draft',
        published => 'Published',
        registrationOpen => 'Registration Open',
        scheduled => 'Scheduled',
        live => 'Live',
        reviewPending => 'Review Pending',
        completed => 'Completed',
        archived => 'Archived',
      };

  Color get color => switch (this) {
        draft => const Color(0xFF757575),
        published => const Color(0xFF1565C0),
        registrationOpen => const Color(0xFF2E7D32),
        scheduled => const Color(0xFF6A1B9A),
        live => const Color(0xFFE65100),
        reviewPending => const Color(0xFFF57F17),
        completed => const Color(0xFF2E7D32),
        archived => const Color(0xFF9E9E9E),
      };

  IconData get icon => switch (this) {
        draft => Icons.edit_outlined,
        published => Icons.public_rounded,
        registrationOpen => Icons.app_registration_rounded,
        scheduled => Icons.event_rounded,
        live => Icons.play_circle_rounded,
        reviewPending => Icons.pending_actions_rounded,
        completed => Icons.check_circle_rounded,
        archived => Icons.archive_rounded,
      };
}

/// What a [NextAction] actually requires the caller to do — lets UI code
/// wire a real callback per event without string-matching the display label.
enum ActionKind {
  reviewSubmissions,
  approveVolunteers,
  createImpactPost,
  submitImpactForApproval,
  approveAndPublishImpact,
  publishEvent,
  assignVolunteers,
  markCompleted,
  none,
}

/// A single actionable (or informational) call-to-action surfaced on an
/// event's card and Overview tab — "what should I do next", not "what stage
/// is this in".
class NextAction {
  const NextAction(this.label, this.kind, {this.enabled = true});
  final String label;
  final ActionKind kind;
  /// False for purely informational states (e.g. "Awaiting Admin Approval"
  /// shown to an Event Manager who has no action left to take).
  final bool enabled;
}

/// Wraps one [NGOEvent] (already the real backend `Event` row, enriched
/// server-side with its linked volunteer-activity fields — see
/// `event_manager.py`'s `_event_json`) together with its assignments and
/// impact post, both scoped by event id from the same
/// `/event-manager/dashboard` response. This replaces `PipelineEvent`
/// (`event_pipeline_models.dart`), which built an equivalent shape but
/// against a mostly-fictional 12-stage status.
class UnifiedEvent {
  const UnifiedEvent({
    required this.event,
    this.assignments = const [],
    this.impactPost,
  });

  final NGOEvent event;
  final List<EMStudentAssignment> assignments;
  final EMImpactPost? impactPost;

  int get assignedCount => assignments.length;

  int get pendingSubmissionsCount => assignments
      .where((a) => a.status == AssignmentStatus.workSubmitted)
      .length;

  /// EM has already verified these; only an Admin can act on them next.
  int get verifiedAwaitingAdminCount =>
      assignments.where((a) => a.status == AssignmentStatus.verified).length;

  bool get hasImpactDraft => impactPost != null;

  /// Backend's `is_published` actually conflates `pending_review` +
  /// `published` (see `event_manager.py` dashboard serialization) — i.e.
  /// "submitted for approval, in some form". Use [impactFullyPublished] for
  /// "truly done".
  bool get impactSubmittedForApproval => impactPost?.isPublished ?? false;

  bool get impactFullyPublished => impactPost?.adminApproved ?? false;

  EventUiStatus get uiStatus {
    switch (event.status) {
      case EventStatus.draft:
        return EventUiStatus.draft;
      case EventStatus.published:
        return EventUiStatus.published;
      case EventStatus.registrationOpen:
        return assignedCount >= event.maxVolunteers
            ? EventUiStatus.scheduled
            : EventUiStatus.registrationOpen;
      case EventStatus.ongoing:
        return EventUiStatus.live;
      case EventStatus.completed:
        final reviewOutstanding = pendingSubmissionsCount > 0 ||
            verifiedAwaitingAdminCount > 0 ||
            !impactFullyPublished;
        return reviewOutstanding
            ? EventUiStatus.reviewPending
            : EventUiStatus.completed;
      case EventStatus.archived:
        return EventUiStatus.archived;
    }
  }

  /// Drives the dashboard's "Needs Attention" bucket.
  bool get needsAttention =>
      pendingSubmissionsCount > 0 ||
      verifiedAwaitingAdminCount > 0 ||
      (event.status == EventStatus.completed &&
          (!hasImpactDraft || !impactFullyPublished));

  /// Ordered priority chain — highest-priority actionable item wins.
  /// [isAdmin] gates admin-only actions (approving EM-verified work,
  /// approving/publishing impact) vs. what an Event Manager can do
  /// (submit impact for approval, but not approve their own).
  NextAction? nextAction({required bool isAdmin}) {
    if (pendingSubmissionsCount > 0) {
      final n = pendingSubmissionsCount;
      return NextAction(
          'Review $n submission${n == 1 ? '' : 's'}', ActionKind.reviewSubmissions);
    }
    if (isAdmin && verifiedAwaitingAdminCount > 0) {
      final n = verifiedAwaitingAdminCount;
      return NextAction(
          'Approve $n volunteer${n == 1 ? '' : 's'}', ActionKind.approveVolunteers);
    }
    if (event.status == EventStatus.completed) {
      if (!hasImpactDraft) {
        return const NextAction('Create Impact Post', ActionKind.createImpactPost);
      }
      if (!impactSubmittedForApproval) {
        return isAdmin
            ? const NextAction('Awaiting Impact Draft', ActionKind.none, enabled: false)
            : const NextAction(
                'Submit Impact for Approval', ActionKind.submitImpactForApproval);
      }
      if (!impactFullyPublished) {
        return isAdmin
            ? const NextAction(
                'Approve & Publish Impact', ActionKind.approveAndPublishImpact)
            : const NextAction('Awaiting Admin Approval', ActionKind.none, enabled: false);
      }
      return null;
    }
    if (event.status == EventStatus.draft) {
      return const NextAction('Publish Event', ActionKind.publishEvent);
    }
    if ((event.status == EventStatus.published ||
            event.status == EventStatus.registrationOpen) &&
        assignedCount < event.maxVolunteers) {
      return const NextAction('Assign Volunteers', ActionKind.assignVolunteers);
    }
    if (event.status == EventStatus.ongoing) {
      // /events/{id}/status (used to mark an event completed/archived) is
      // admin/super_admin only on the backend — an Event Manager has no
      // action to take here even though the event is theirs.
      return isAdmin
          ? const NextAction('Mark Completed', ActionKind.markCompleted)
          : const NextAction('Event is Live', ActionKind.none, enabled: false);
    }
    return null;
  }
}
