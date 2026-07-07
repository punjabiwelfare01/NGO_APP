import 'package:flutter/foundation.dart';

import '../models/certificate_models.dart';
import '../models/donation_models.dart';
import '../models/volunteer_models.dart';
import '../repositories/certificate_repository.dart';
import '../repositories/donation_repository.dart';
import '../repositories/volunteer_repository.dart';

enum VolunteerLoadState { idle, loading, error }

class VolunteerViewModel extends ChangeNotifier {
  VolunteerLoadState _state = VolunteerLoadState.idle;
  String? _error;

  VolunteerStats _stats = VolunteerStats.empty;
  List<VolunteerActivity> _activities = [];
  List<ActivityAssignment> _assignments = [];
  List<WorkSubmission> _submissions = [];
  List<DailyLog> _logs = [];
  List<ImpactStory> _impactStories = [];
  List<Certificate> _certificates = [];
  List<Donation> _donations = [];
  List<StipendRecord> _stipends = [];
  NGOPaymentDetails? _paymentDetails;

  VolunteerLoadState get state => _state;
  String? get error => _error;
  VolunteerStats get stats => _stats;
  List<VolunteerActivity> get activities => _activities;
  List<ActivityAssignment> get assignments => _assignments;
  List<WorkSubmission> get submissions => _submissions;
  List<DailyLog> get logs => _logs;
  List<ImpactStory> get impactStories => _impactStories;
  List<Certificate> get certificates => _certificates;
  List<Donation> get donations => _donations;
  List<StipendRecord> get stipends => _stipends;
  NGOPaymentDetails? get paymentDetails => _paymentDetails;

  int get pendingSubmissions => _submissions
      .where(
        (s) =>
            s.status == SubmissionStatus.submitted ||
            s.status == SubmissionStatus.under_review,
      )
      .length;

  // ── Load everything for the volunteer dashboard ───────────────────────────

  Future<void> load() async {
    _state = VolunteerLoadState.loading;
    _error = null;
    notifyListeners();

    // Run each call independently so one failure doesn't wipe out all data.
    await Future.wait([
      VolunteerRepository.getMyStats()
          .then<void>((v) => _stats = v)
          .catchError((_) {}),
      VolunteerRepository.getActivities()
          .then<void>((v) => _activities = v)
          .catchError((_) {}),
      VolunteerRepository.getMyAssignments()
          .then<void>((v) => _assignments = v)
          .catchError((_) {}),
      VolunteerRepository.getMySubmissions()
          .then<void>((v) => _submissions = v)
          .catchError((_) {}),
      VolunteerRepository.getMyLogs()
          .then<void>((v) => _logs = v)
          .catchError((_) {}),
      VolunteerRepository.getImpactStories()
          .then<void>((v) => _impactStories = v)
          .catchError((_) {}),
      CertificateRepository.getMyCertificates()
          .then<void>((v) => _certificates = v)
          .catchError((_) {}),
      DonationRepository.getMyDonations()
          .then<void>((v) => _donations = v)
          .catchError((_) {}),
      DonationRepository.getNGOPaymentDetails()
          .then<void>((v) => _paymentDetails = v)
          .catchError((_) {}),
    ]);

    _state = VolunteerLoadState.idle;
    notifyListeners();
  }

  // ── Load only what's needed for specific screens ──────────────────────────

  Future<void> loadActivities({ActivityCategory? category}) async {
    try {
      _activities = await VolunteerRepository.getActivities(category: category);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> applyForActivity(int activityId, {String? note}) async {
    try {
      await VolunteerRepository.applyForActivity(activityId, note: note);
      await Future.wait([
        loadActivities(),
        _reloadAssignments(),
        _refreshStats(),
      ]);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _reloadAssignments() async {
    _assignments = await VolunteerRepository.getMyAssignments();
  }

  Future<void> loadImpactStories() async {
    try {
      _impactStories = await VolunteerRepository.getImpactStories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadCertificates() async {
    try {
      _certificates = await CertificateRepository.getMyCertificates();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadDonations() async {
    try {
      _donations = await DonationRepository.getMyDonations();
      _stipends = await DonationRepository.getMyStipends();
      _paymentDetails = await DonationRepository.getNGOPaymentDetails();
      notifyListeners();
    } catch (_) {}
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<WorkSubmission?> submitWork({
    required int activityId,
    int? assignmentId,
    required String title,
    required String description,
    required double hoursWorked,
    int peopleReached = 0,
    double donationCollected = 0,
    String? transactionId,
    String? remarks,
    String? proofFiles,
    String? reviewTarget,
  }) async {
    try {
      final sub = await VolunteerRepository.submitWork(
        activityId: activityId,
        assignmentId: assignmentId,
        title: title,
        description: description,
        hoursWorked: hoursWorked,
        peopleReached: peopleReached,
        donationCollected: donationCollected,
        transactionId: transactionId,
        remarks: remarks,
        proofFiles: proofFiles,
        reviewTarget: reviewTarget,
      );
      _submissions = [sub, ..._submissions];
      await _refreshStats();
      notifyListeners();
      return sub;
    } catch (_) {
      return null;
    }
  }

  Future<DailyLog?> createLog({
    required DateTime date,
    String? title,
    String? content,
    String? reflection,
    int? submissionId,
  }) async {
    try {
      final log = await VolunteerRepository.createLog(
        date: date,
        title: title,
        content: content,
        reflection: reflection,
        submissionId: submissionId,
      );
      _logs = [log, ..._logs];
      notifyListeners();
      return log;
    } catch (_) {
      return null;
    }
  }

  Future<Donation?> submitDonation({
    String? donorName,
    String? donorMobile,
    required DonationType donationType,
    double amount = 0,
    String? category,
    String? itemsDesc,
    String? purpose,
    String? transactionId,
  }) async {
    try {
      final donation = await DonationRepository.submitDonation(
        donorName: donorName,
        donorMobile: donorMobile,
        donationType: donationType,
        amount: amount,
        category: category,
        itemsDesc: itemsDesc,
        purpose: purpose,
        transactionId: transactionId,
      );
      _donations = [donation, ..._donations];
      notifyListeners();
      return donation;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshStats() async {
    try {
      _stats = await VolunteerRepository.getMyStats();
    } catch (_) {}
  }

  // ── Admin actions ─────────────────────────────────────────────────────────

  Future<List<WorkSubmission>> getPendingSubmissions() async {
    return VolunteerRepository.getPendingSubmissions();
  }

  Future<List<WorkSubmission>> getApprovedSubmissions() async {
    return VolunteerRepository.getApprovedSubmissions();
  }

  Future<bool> reviewSubmission(
    int submissionId, {
    required String status,
    String? notes,
  }) async {
    try {
      await VolunteerRepository.reviewSubmission(
        submissionId,
        status: status,
        reviewerNotes: notes,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
