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

  static Future<void> createStandaloneImpact(EMImpactPost post) async =>
      ApiClient.post('/impact/posts', {
        'category': post.type.name,
        'title': post.title,
        'description': post.description,
        if (post.studentName != null) 'student_names': post.studentName,
        if (post.teamName != null) 'team_name': post.teamName,
        'location': post.location,
        'people_reached': post.studentsHelped ?? 0,
        'hours_served': post.hoursServed ?? 0,
        'donation_collected': post.donationRaised ?? 0,
        'media': post.photoUrls
            .map((url) => {'media_type': 'image', 'url': url})
            .toList(),
      });
}
