import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/api_models.dart';
import '../models/counselling_models.dart';
import '../models/counsellor_models.dart';
import '../models/counsellor_session_models.dart';
import '../repositories/counselling_repository.dart';
import '../repositories/user_repository.dart';

enum CounsellorHomeLoadState { idle, loading }

class CounsellorHomeViewModel extends ChangeNotifier {
  CounsellorHomeLoadState _state = CounsellorHomeLoadState.idle;
  bool _disposed = false;
  List<SchoolBookingRequest> _requests = [];
  List<MeetingReminder> _reminders = [];
  List<AvailabilitySlot> _slots = [];
  AppUser? _user;
  MentorProfile? _mentorProfile;
  bool _savingProfile = false;
  String? _profileError;
  CounsellorStats _stats = const CounsellorStats(
    todayScheduled: 0,
    newRequests: 0,
    pendingConfirmation: 0,
    completedThisMonth: 0,
    avgRating: 0,
    totalStudentsGuided: 0,
  );

  CounsellorHomeLoadState get state => _state;
  CounsellorStats get stats => _stats;
  AppUser? get user => _user;
  MentorProfile? get mentorProfile => _mentorProfile;
  bool get savingProfile => _savingProfile;
  String? get profileError => _profileError;
  CounsellorProfile get profile => CounsellorProfile(
    id: AppState.userId,
    ngoVerificationId: 'PWT-COUN-${AppState.userId}',
    name:
        _mentorProfile?.displayName ??
        _user?.name ??
        AppState.studentName ??
        'Counsellor',
    photoUrl: _mentorProfile?.profileImageUrl ?? _user?.photoUrl,
    category:
        CounsellorCategory.fromLabel(_mentorProfile?.category ?? '') ??
        CounsellorCategory.educationCounsellor,
    designation: 'Verified NGO Counsellor',
    serviceBackground: _mentorProfile?.expertise?.trim().isNotEmpty == true
        ? _mentorProfile!.expertise!.trim()
        : 'Add your professional background and areas of expertise.',
    shortBio: _mentorProfile?.bio?.trim().isNotEmpty == true
        ? _mentorProfile!.bio!.trim()
        : 'Counsellor serving Punjabi Welfare Trust school and community programs.',
    qualifications: const [],
    expertiseAreas: _splitValues(_mentorProfile?.expertise),
    sessionTopics: const [],
    languages: const [],
    sessionMode: SessionMode.both,
    availableSlots: _slots.map((slot) => slot.timeLabel).toList(),
    yearsOfExperience: 0,
    schoolSessionsCompleted: completedSessions.length,
    studentsGuided: _stats.totalStudentsGuided,
    recognitionProof: const [],
    verificationStatus: VerificationStatus.verified,
    availableThisWeek: _slots.any((slot) => !slot.isBlocked && !slot.isBooked),
  );

  List<String> _splitValues(String? value) =>
      value
          ?.split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList() ??
      const [];
  List<SchoolBookingRequest> get allRequests => List.unmodifiable(_requests);
  List<SchoolBookingRequest> get newRequests => _requests
      .where((item) => item.status == SchoolRequestStatus.newRequest)
      .toList();
  List<SchoolBookingRequest> get activeRequests =>
      _requests.where((item) => item.isActive).toList();
  List<SchoolBookingRequest> get upcomingMeetings =>
      _requests.where((item) => item.isUpcoming).toList();
  List<SchoolBookingRequest> get todayMeetings =>
      upcomingMeetings.where((item) => item.isToday).toList();
  List<SchoolBookingRequest> get completedSessions => _requests
      .where((item) => item.status == SchoolRequestStatus.completed)
      .toList();
  List<SchoolBookingRequest> get cancelledSessions => _requests
      .where(
        (item) =>
            item.status == SchoolRequestStatus.cancelled ||
            item.status == SchoolRequestStatus.declined,
      )
      .toList();
  List<SchoolBookingRequest> get rescheduledRequests => _requests
      .where((item) => item.status == SchoolRequestStatus.rescheduled)
      .toList();
  List<MeetingReminder> get upcomingReminders =>
      _reminders.where((item) => item.isUpcoming).toList()
        ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  List<ImpactReport> get impactReports => const [];
  List<AvailabilitySlot> get slots => List.unmodifiable(_slots);
  List<AvailabilitySlot> slotsForDate(DateTime date) => _slots
      .where(
        (slot) =>
            slot.date.year == date.year &&
            slot.date.month == date.month &&
            slot.date.day == date.day,
      )
      .toList();
  SchoolBookingRequest? requestById(int id) {
    try {
      return _requests.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    _state = CounsellorHomeLoadState.loading;
    if (!_disposed) notifyListeners();
    try {
      final results = await Future.wait([
        CounsellingRepository.getCounsellorRequests(),
        CounsellingRepository.getMyAvailability(),
        UserRepository.getUser(AppState.userId),
        CounsellingRepository.getMyMentorProfile(),
      ]);
      _requests = results[0] as List<SchoolBookingRequest>;
      _slots = results[1] as List<AvailabilitySlot>;
      _user = results[2] as AppUser;
      _mentorProfile = results[3] as MentorProfile?;
      AppState.updateStudentName(_user!.name);
      _reminders = _buildReminders();
      _stats = _buildStats();
    } finally {
      _state = CounsellorHomeLoadState.idle;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? location,
    String? bio,
    String? expertise,
    required CounsellorCategory category,
    List<int>? photoBytes,
    String? photoPath,
    String? photoFileName,
  }) async {
    _savingProfile = true;
    _profileError = null;
    if (!_disposed) notifyListeners();
    try {
      if (photoBytes != null || photoPath != null) {
        _user = await UserRepository.uploadProfilePhoto(
          bytes: photoBytes,
          filePath: photoBytes == null ? photoPath : null,
          fileName: photoFileName ?? 'profile.jpg',
        );
      }
      _user = await UserRepository.updateProfile(
        name: name,
        phone: phone,
        location: location,
      );
      _mentorProfile = await CounsellingRepository.updateMyMentorProfile({
        'display_name': name,
        'bio': bio,
        'expertise': expertise,
        'category': category.label,
        if (_user?.photoUrl != null) 'profile_image_url': _user!.photoUrl,
      });
      AppState.updateStudentName(name);
      return true;
    } catch (_) {
      _profileError = 'Could not save your profile. Please try again.';
      return false;
    } finally {
      _savingProfile = false;
      if (!_disposed) notifyListeners();
    }
  }

  CounsellorStats _buildStats() {
    final completed = completedSessions;
    final ratings = completed
        .where((item) => item.feedbackRating != null)
        .map((item) => item.feedbackRating!)
        .toList();
    return CounsellorStats(
      todayScheduled: todayMeetings.length,
      newRequests: newRequests.length,
      pendingConfirmation: _requests
          .where(
            (item) =>
                item.status == SchoolRequestStatus.accepted ||
                item.status == SchoolRequestStatus.pendingConfirmation,
          )
          .length,
      completedThisMonth: completed
          .where((item) => item.completedAt?.month == DateTime.now().month)
          .length,
      avgRating: ratings.isEmpty
          ? 0
          : ratings.reduce((a, b) => a + b) / ratings.length,
      totalStudentsGuided: completed.fold(
        0,
        (sum, item) => sum + item.expectedStudents,
      ),
    );
  }

  List<MeetingReminder> _buildReminders() {
    final result = <MeetingReminder>[];
    for (final request in _requests.where((item) => item.isUpcoming)) {
      final base = DateTime(
        request.effectiveDate.year,
        request.effectiveDate.month,
        request.effectiveDate.day,
        request.effectiveTime.hour,
        request.effectiveTime.minute,
      );
      final entries = <(Duration, ReminderType)>[
        (const Duration(hours: 24), ReminderType.hours24),
        (const Duration(hours: 2), ReminderType.hours2),
        (const Duration(minutes: 15), ReminderType.minutes15),
      ];
      for (final entry in entries) {
        result.add(
          MeetingReminder(
            id: request.id * 10 + entry.$2.index,
            requestId: request.id,
            scheduledFor: base.subtract(entry.$1),
            type: entry.$2,
            schoolName: request.schoolName,
            mode: request.mode,
            coordinatorName: request.coordinatorName,
            meetingDate: request.effectiveDate,
            locationOrLink: request.effectiveModeDetail,
          ),
        );
      }
    }
    return result;
  }

  Future<void> acceptRequest(int id) async {
    await CounsellingRepository.acceptRequest(id);
    await load();
  }

  Future<void> rescheduleRequest(int id, DateTime date, TimeOfDay time) async {
    await CounsellingRepository.rescheduleRequest(
      id,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
    await load();
  }

  Future<void> declineRequest(
    int id,
    DeclineReason reason, {
    String note = '',
  }) async {
    await CounsellingRepository.declineRequest(id, reason.name, note);
    await load();
  }

  Future<void> markCompleted(int id) async {
    await CounsellingRepository.completeSession(id);
    await load();
  }

  Future<void> submitImpactReport(
    int id, {
    required String counsellorNotes,
    double? rating,
    String schoolFeedback = '',
  }) async {
    final request = requestById(id);
    if (request == null) return;
    await CounsellingRepository.submitSessionReport(
      id,
      notes: counsellorNotes,
      rating: rating,
      schoolFeedback: schoolFeedback,
      studentsCount: request.expectedStudents,
    );
  }

  void dismissReminder(int id) {
    final index = _reminders.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _reminders[index] = _reminders[index].copyWith(isDismissed: true);
      notifyListeners();
    }
  }

  Future<void> toggleSlotBlock(int id) async {
    final slot = _slots.firstWhere((item) => item.id == id);
    await CounsellingRepository.setAvailabilityActive(id, slot.isBlocked);
    await load();
  }

  Future<void> addSlot(AvailabilitySlot slot) async {
    await CounsellingRepository.createAvailability(slot);
    await load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
