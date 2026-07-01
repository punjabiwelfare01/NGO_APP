import '../app_state.dart';
import '../models/event_manager_models.dart';
import 'api_client.dart';


class EventManagerRepository {
  const EventManagerRepository._();
  static Future<
    ({
      EventManagerStats stats,
      List<NGOEvent> events,
      List<EMStudentAssignment> assignments,
      List<EMImpactPost> impacts,
    })
  >
  dashboard() async {
    final data =
        await ApiClient.get('/event-manager/dashboard') as Map<String, dynamic>;
    return (
      stats: EventManagerStats.fromJson(data['stats'] as Map<String, dynamic>),
      events: (data['events'] as List<dynamic>)
          .map((e) => NGOEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignments: (data['assignments'] as List<dynamic>)
          .map((e) => EMStudentAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      impacts: (data['impact_posts'] as List<dynamic>)
          .map((e) => EMImpactPost.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<void> updateAssignment(
    int id,
    AssignmentStatus status, {
    String? notes,
    String? instructions,
  }) async => ApiClient.patch('/event-manager/assignments/$id', {
    'status': status.name,
    'reviewer_notes': ?notes,
    'instructions': ?instructions,
  });
  static Future<Map<String, dynamic>> generateReport(int eventId) async =>
      await ApiClient.post('/events/$eventId/reports/generate', const {})
          as Map<String, dynamic>;
  static Future<int> ensureReport(int eventId) async {
    final items =
        await ApiClient.get('/events/$eventId/reports') as List<dynamic>;
    if (items.isNotEmpty) {
      return (items.first as Map<String, dynamic>)['id'] as int;
    }
    return (await generateReport(eventId))['id'] as int;
  }

  static String reportDownloadUrl(
    int eventId,
    int reportId,
  ) => ApiClient.resolveUrl(
    '/events/$eventId/reports/$reportId/download?token=${Uri.encodeQueryComponent(AppState.token ?? '')}',
  );
  static Future<String> shareReport(int eventId, int reportId) async =>
      (await ApiClient.post(
                '/events/$eventId/reports/$reportId/share',
                const {},
              )
              as Map<String, dynamic>)['public_url']
          as String;
  static Future<void> finalizeReport(int eventId, int reportId) async =>
      ApiClient.patch('/events/$eventId/reports/$reportId/finalize', const {});
  static Future<int> createImpact(EMStudentAssignment assignment) async {
    final submission = assignment.submission;
    final data =
        await ApiClient.post('/impact/posts', {
              'category': 'achievement',
              'title': 'Work Completed: ${assignment.activity.title}',
              'description':
                  submission?.description ??
                  '${assignment.student.name} completed ${assignment.activity.title}.',
              'event_id': assignment.event.id,
              'activity_id': assignment.activity.id,
              'student_names': assignment.student.name,
              'location': assignment.event.location,
              'people_reached': submission?.peopleReached ?? 0,
              'donation_collected': submission?.donationCollected ?? 0,
              'hours_served': submission?.hoursWorked ?? 0,
              'media': (submission?.photoUrls ?? const [])
                  .map((url) => {'media_type': 'image', 'url': url})
                  .toList(),
            })
            as Map<String, dynamic>;
    return data['id'] as int;
  }

  static Future<void> submitImpact(int postId) async =>
      ApiClient.patch('/impact/posts/$postId', {'status': 'pending_review'});
  static Future<void> publishImpact(int postId) async =>
      ApiClient.post('/impact/posts/$postId/publish', const {});
  static Future<void> deleteImpact(int postId) async =>
      ApiClient.delete('/impact/posts/$postId');
  static Future<void> createEvent(NGOEvent event) async {
    final eventType = switch (event.category) {
      EventCategory.talentHunt => 'talent_hunt',
      EventCategory.awarenessCampaign => 'awareness_campaign',
      EventCategory.counsellingDrive => 'counselling_drive',
      EventCategory.cyberSecurity => 'cyber_security',
      EventCategory.competition => 'competition',
      _ => 'workshop',
    };
    final created =
        await ApiClient.post('/events/create', {
              'title': event.title,
              'description': event.description,
              'event_type': eventType,
              'event_start': event.date.toIso8601String(),
              'max_participants': event.maxVolunteers,
              'certificate_enabled': event.certificateEligible,
              'status': 'draft',
            })
            as Map<String, dynamic>;
    final eventId = created['id'] as int;
    for (final activity in event.activities) {
      await ApiClient.post('/volunteer/activities', {
        'event_id': eventId,
        'title': activity.title,
        'category': 'event_organization',
        'description': activity.description,
        'location': event.location,
        'max_students': activity.maxStudents,
        'certificate_eligible': event.certificateEligible,
        'stipend_amount': event.stipendAmount,
      });
    }
  }

  static Future<void> createStandaloneActivity({
    required String title,
    required String category,
    required int? eventId,
    String? description,
    int? maxStudents,
  }) async {
    await ApiClient.post('/volunteer/activities', {
      'title': title,
      'category': category,
      'event_id': eventId,
      'description': description?.isNotEmpty == true ? description : null,
      'max_students': maxStudents,
      'certificate_eligible': true,
      'reward_hours': 2.0,
    });
  }

  /// Upload a single impact media file immediately; returns its server URL.
  static Future<String> uploadImpactMedia({
    required List<int> bytes,
    required String fileName,
    String mediaType = 'image',
  }) async {
    final json = await ApiClient.postMultipart(
      '/impact/upload-media',
      fields: {'media_type': mediaType},
      fileBytes: bytes,
      fileName: fileName,
      timeout: const Duration(seconds: 60),
    ) as Map<String, dynamic>;
    return json['url'] as String;
  }

  static Future<int> createStandaloneImpact(
    EMImpactPost post, {
    List<Map<String, dynamic>> mediaList = const [],
  }) async {
    final result = await ApiClient.post('/impact/posts', {
      'category': post.type.name,
      'title': post.title.isEmpty ? 'Untitled Draft' : post.title,
      'description': post.description.isEmpty ? 'Draft' : post.description,
      if (post.studentName != null) 'student_names': post.studentName,
      if (post.teamName != null) 'team_name': post.teamName,
      'location': post.location,
      'people_reached': post.studentsHelped ?? 0,
      'hours_served': post.hoursServed ?? 0,
      'donation_collected': post.donationRaised ?? 0,
      'media': mediaList,
    }) as Map<String, dynamic>;
    return result['id'] as int;
  }

  static Future<void> updateStandaloneImpact(
    int postId,
    EMImpactPost post, {
    List<Map<String, dynamic>>? mediaList,
  }) async =>
      ApiClient.patch('/impact/posts/$postId', {
        'category': post.type.name,
        'title': post.title,
        'description': post.description,
        if (post.studentName != null) 'student_names': post.studentName,
        'location': post.location,
        'people_reached': post.studentsHelped ?? 0,
        'hours_served': post.hoursServed ?? 0,
        'donation_collected': post.donationRaised ?? 0,
        'media': ?mediaList,
      });

  static Future<EMActivityTracking> getActivityTracking(
      int activityId) async {
    final data = await ApiClient.get(
        '/event-manager/activities/$activityId/tracking');
    return EMActivityTracking.fromJson(data as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> reviewSubmission(
    int submissionId, {
    required String status,
    String? reviewerNotes,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (reviewerNotes != null) body['reviewer_notes'] = reviewerNotes;
    final data = await ApiClient.patch(
        '/event-manager/submissions/$submissionId/review', body);
    return data as Map<String, dynamic>;
  }

  // ── NGO Student Listing ────────────────────────────────────────────────────

  static Future<List<EMNgoStudent>> getAllNgoStudents({String? search}) async {
    final path = (search != null && search.isNotEmpty)
        ? '/event-manager/students?search=${Uri.encodeComponent(search)}'
        : '/event-manager/students';
    final data = await ApiClient.get(path) as List<dynamic>;
    return data
        .map((e) => EMNgoStudent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Activity Management ────────────────────────────────────────────────────

  /// POST /event-manager/activities — create a new activity (optionally linked to an event).
  static Future<EMActivity> createActivity({
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
    final body = <String, dynamic>{
      'title': title,
      'category': category,
      'reward_hours': rewardHours,
      'max_students': maxStudents,
      'certificate_eligible': certificateEligible,
      'status': status,
    };
    if (eventId != null) body['event_id'] = eventId;
    if (description?.isNotEmpty == true) body['description'] = description;
    if (location?.isNotEmpty == true) body['location'] = location;
    if (expectedWork?.isNotEmpty == true) body['expected_work'] = expectedWork;
    if (workInstructions?.isNotEmpty == true) body['work_instructions'] = workInstructions;
    if (proofRequired?.isNotEmpty == true) body['proof_required'] = proofRequired;
    if (stipendAmount != null) body['stipend_amount'] = stipendAmount;
    if (startDate != null) body['start_date'] = startDate.toIso8601String().split('T').first;
    if (endDate != null) body['end_date'] = endDate.toIso8601String().split('T').first;

    final data = await ApiClient.post('/event-manager/activities', body) as Map<String, dynamic>;
    return EMActivity.fromJson(data);
  }

  static Future<List<EMActivity>> getMyActivities({String? status}) async {
    final path = status != null
        ? '/event-manager/activities?status=$status'
        : '/event-manager/activities';
    final data = await ApiClient.get(path) as List<dynamic>;
    return data
        .map((e) => EMActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<EMActivity> editActivity(
    int activityId,
    Map<String, dynamic> payload,
  ) async {
    final data = await ApiClient.put(
      '/event-manager/activities/$activityId',
      payload,
    ) as Map<String, dynamic>;
    return EMActivity.fromJson(data);
  }

  static Future<List<EMActivityStudent>> getActivityStudents(
      int activityId) async {
    final data = await ApiClient.get(
        '/event-manager/activities/$activityId/students') as List<dynamic>;
    return data
        .map((e) => EMActivityStudent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> assignStudents(
    int activityId, {
    required List<int> studentIds,
    String? notes,
  }) async {
    final data = await ApiClient.post(
      '/event-manager/activities/$activityId/assign-students',
      {'student_ids': studentIds, 'notes': ?notes},
    ) as Map<String, dynamic>;
    return data;
  }

  static Future<List<EMActivityWorkLog>> getActivityWorkLogs(
      int activityId) async {
    final data = await ApiClient.get(
        '/event-manager/activities/$activityId/work-logs') as List<dynamic>;
    return data
        .map((e) => EMActivityWorkLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Admin Activity Management ──────────────────────────────────────────────

  static Future<List<EMActivity>> adminGetAllActivities({
    String? status,
    int? eventManagerId,
    String? category,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (eventManagerId != null) params['event_manager_id'] = '$eventManagerId';
    if (category != null) params['category'] = category;
    final query =
        params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final data = await ApiClient.get(
        '/event-manager/admin/all-activities$query') as List<dynamic>;
    return data
        .map((e) => EMActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> adminGetActivitiesSummary() async {
    return await ApiClient.get('/event-manager/admin/activities-summary')
        as Map<String, dynamic>;
  }
}
