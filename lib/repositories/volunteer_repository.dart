// ignore_for_file: prefer_null_aware_elements
import '../models/volunteer_models.dart';
import 'api_client.dart';

class VolunteerRepository {
  const VolunteerRepository._();

  // ── Activities ──────────────────────────────────────────────────────────────

  static Future<List<VolunteerActivity>> getActivities({
    ActivityCategory? category,
  }) async {
    final path = category == null
        ? '/student/activities'
        : '/student/activities?category=${category.name}';
    final data = await ApiClient.get(path) as List<dynamic>;
    return data
        .map((e) => VolunteerActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<VolunteerActivity> getActivity(int id) async {
    final data = await ApiClient.get('/student/activities/$id');
    return VolunteerActivity.fromJson(data as Map<String, dynamic>);
  }

  // ── Assignments ─────────────────────────────────────────────────────────────

  static Future<List<ActivityAssignment>> getMyAssignments() async {
    final data = await ApiClient.get('/student/assignments') as List<dynamic>;
    return data
        .map((e) => ActivityAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> applyForActivity(int activityId, {String? note}) async {
    await ApiClient.post('/student/activities/$activityId/apply', {
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  // ── Work Submissions ────────────────────────────────────────────────────────

  static Future<WorkSubmission> submitWork({
    required int activityId,
    int? assignmentId,
    required String title,
    required String description,
    required double hoursWorked,
    int peopleReached = 0,
    double donationCollected = 0,
    String? transactionId,
    String? proofFiles,
    String? remarks,
    /// 'event_manager' or 'admin' to explicitly pick the reviewer; omit to
    /// let the backend auto-route based on who created the activity.
    String? reviewTarget,
  }) async {
    final body = <String, dynamic>{
      'activity_id': activityId,
      'title': title,
      'description': description,
      'hours_worked': hoursWorked,
      'people_reached': peopleReached,
      'donation_collected': donationCollected,
    };
    if (assignmentId != null) body['assignment_id'] = assignmentId;
    if (transactionId != null) body['transaction_id'] = transactionId;
    if (proofFiles != null) body['proof_files'] = proofFiles;
    if (remarks != null) body['remarks'] = remarks;
    if (reviewTarget != null) body['review_target'] = reviewTarget;

    final data = await ApiClient.post('/volunteer/work-submissions', body);
    return WorkSubmission.fromJson(data as Map<String, dynamic>);
  }

  static Future<String> uploadProofFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    final json = await ApiClient.postMultipart(
      '/student/upload-proof',
      fields: const {},
      fileBytes: bytes,
      fileName: fileName,
    ) as Map<String, dynamic>;
    return json['url'] as String;
  }

  static Future<List<WorkSubmission>> getMySubmissions() async {
    final data =
        await ApiClient.get('/volunteer/submissions/me') as List<dynamic>;
    return data
        .map((e) => WorkSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<WorkSubmission>> getPendingSubmissions() async {
    final data =
        await ApiClient.get('/volunteer/submissions/pending') as List<dynamic>;
    return data
        .map((e) => WorkSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<WorkSubmission>> getApprovedSubmissions() async {
    final data = await ApiClient.get('/volunteer/submissions/approved')
        as List<dynamic>;
    return data
        .map((e) => WorkSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<WorkSubmission> reviewSubmission(
    int submissionId, {
    required String status,
    String? reviewerNotes,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (reviewerNotes != null) body['reviewer_notes'] = reviewerNotes;
    final data = await ApiClient.patch(
      '/volunteer/submissions/$submissionId/review',
      body,
    );
    return WorkSubmission.fromJson(data as Map<String, dynamic>);
  }

  // ── Daily Logs ──────────────────────────────────────────────────────────────

  static Future<DailyLog> createLog({
    required DateTime date,
    String? title,
    String? content,
    String? reflection,
    String? mediaFiles,
    int? submissionId,
  }) async {
    final body = <String, dynamic>{
      'date': date.toIso8601String().substring(0, 10),
    };
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (reflection != null) body['reflection'] = reflection;
    if (mediaFiles != null) body['media_files'] = mediaFiles;
    if (submissionId != null) body['submission_id'] = submissionId;

    final data = await ApiClient.post('/volunteer/logs', body);
    return DailyLog.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<DailyLog>> getMyLogs() async {
    final data = await ApiClient.get('/volunteer/logs/me') as List<dynamic>;
    return data
        .map((e) => DailyLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<DailyLog>> getPublicLogs() async {
    final data = await ApiClient.get('/volunteer/logs/public') as List<dynamic>;
    return data
        .map((e) => DailyLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<DailyLog> updateLog(
    int logId, {
    String? title,
    String? content,
    String? reflection,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (reflection != null) body['reflection'] = reflection;
    if (status != null) body['status'] = status;

    final data = await ApiClient.patch('/volunteer/logs/$logId', body);
    return DailyLog.fromJson(data as Map<String, dynamic>);
  }

  // ── Wall of Impact ──────────────────────────────────────────────────────────

  static Future<List<ImpactStory>> getImpactStories({
    bool featuredOnly = false,
  }) async {
    final data =
        await ApiClient.get(
              '/volunteer/impact${featuredOnly ? "?featured_only=true" : ""}',
            )
            as List<dynamic>;
    return data
        .map((e) => ImpactStory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Volunteer Stats ─────────────────────────────────────────────────────────

  static Future<VolunteerStats> getMyStats() async {
    final data = await ApiClient.get('/volunteer/stats/me');
    return VolunteerStats.fromJson(data as Map<String, dynamic>);
  }
}
