import 'package:flutter/foundation.dart';

import '../models/counsellor_models.dart';
import '../models/counsellor_session_models.dart';
import '../models/school_partner_models.dart';
import '../repositories/counselling_repository.dart';
import '../repositories/school_partner_repository.dart';

enum CounsellorLoadState { idle, loading, error }

class CounsellorViewModel extends ChangeNotifier {
  static final CounsellorViewModel shared = CounsellorViewModel();

  CounsellorLoadState _state = CounsellorLoadState.idle;
  List<CounsellorProfile> _counsellors = [];
  final List<CounsellingRequest> _requests = [];
  List<SchoolBookingRequest> _schoolRequests = [];
  CounsellorFilter _filter = const CounsellorFilter();
  bool _disposed = false;
  bool _loaded = false;
  bool _schoolRequestsLoaded = false;
  SchoolPartnerProfile? _schoolProfile;
  SchoolStats _schoolStats = SchoolStats.empty;
  bool _schoolStatsLoaded = false;

  CounsellorLoadState get state => _state;
  CounsellorFilter get filter => _filter;
  List<CounsellingRequest> get requests => List.unmodifiable(_requests);
  List<SchoolBookingRequest> get schoolRequests =>
      List.unmodifiable(_schoolRequests);
  SchoolPartnerProfile? get schoolProfile => _schoolProfile;
  SchoolStats get schoolStats => _schoolStats;

  List<CounsellorProfile> get allCounsellors =>
      _counsellors.where((c) => c.isActive && c.isVerified).toList();

  List<CounsellorProfile> get adminCounsellors =>
      List.unmodifiable(_counsellors);

  List<CounsellorProfile> get featuredCounsellors =>
      allCounsellors.where((c) => c.isFeatured).toList();

  List<CounsellorProfile> get filtered {
    var list = allCounsellors;
    final f = _filter;

    if (f.searchQuery.isNotEmpty) {
      final q = f.searchQuery.toLowerCase();
      list = list
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.designation.toLowerCase().contains(q) ||
                c.expertiseAreas.any((e) => e.toLowerCase().contains(q)) ||
                c.category.label.toLowerCase().contains(q),
          )
          .toList();
    }
    if (f.category != null) {
      list = list.where((c) => c.category == f.category).toList();
    }
    if (f.sessionMode != null) {
      list = list
          .where(
            (c) =>
                c.sessionMode == f.sessionMode ||
                c.sessionMode == SessionMode.both,
          )
          .toList();
    }
    if (f.language != null) {
      list = list
          .where(
            (c) => c.languages.any(
              (l) => l.toLowerCase() == f.language!.toLowerCase(),
            ),
          )
          .toList();
    }
    if (f.availableThisWeek) {
      list = list.where((c) => c.availableThisWeek).toList();
    }
    if (f.featuredOnly) {
      list = list.where((c) => c.isFeatured).toList();
    }
    return list;
  }

  List<String> get allLanguages {
    final langs = <String>{};
    for (final c in allCounsellors) {
      langs.addAll(c.languages);
    }
    return langs.toList()..sort();
  }

  List<CounsellingRequest> get pendingRequests =>
      _requests.where((r) => r.status == RequestStatus.pending).toList();

  List<CounsellingRequest> get activeRequests => _requests
      .where(
        (r) =>
            r.status == RequestStatus.reviewed ||
            r.status == RequestStatus.assigned,
      )
      .toList();

  // Admin-fetched list of ALL school requests across all counsellors
  List<SchoolBookingRequest> _allAdminRequests = [];
  List<SchoolBookingRequest> get allAdminRequests =>
      List.unmodifiable(_allAdminRequests);

  List<SchoolBookingRequest> requestsForCounsellor(int counsellorUserId) =>
      _allAdminRequests
          .where((r) => r.counsellorUserId == counsellorUserId)
          .toList();

  CounsellorProfile? findById(int id) {
    try {
      return _counsellors.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_loaded) return;
    _state = CounsellorLoadState.loading;
    notifyListeners();
    try {
      _counsellors = await CounsellingRepository.getCounsellors();
      _loaded = true;
      _state = CounsellorLoadState.idle;
    } catch (_) {
      _state = CounsellorLoadState.error;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> loadSchoolRequests({bool force = false}) async {
    if (_schoolRequestsLoaded && !force) return;
    try {
      _schoolRequests = await CounsellingRepository.getMySchoolRequests();
      _schoolRequestsLoaded = true;
    } catch (_) {}
    if (!_disposed) notifyListeners();
  }

  Future<void> loadSchoolProfile({bool force = false}) async {
    if (_schoolProfile != null && !force) return;
    try {
      _schoolProfile = await SchoolPartnerRepository.getProfile();
    } catch (_) {}
    if (!_disposed) notifyListeners();
  }

  Future<void> loadSchoolStats({bool force = false}) async {
    if (_schoolStatsLoaded && !force) return;
    try {
      _schoolStats = await SchoolPartnerRepository.getMyStats();
      _schoolStatsLoaded = true;
    } catch (_) {}
    if (!_disposed) notifyListeners();
  }

  /// Admin-only: fetch ALL school counsellor requests across every counsellor.
  /// Uses GET /counsellor/requests which returns all rows for admin/super_admin.
  Future<void> loadAllAdminRequests() async {
    try {
      _allAdminRequests = await CounsellingRepository.getCounsellorRequests();
    } catch (_) {}
    if (!_disposed) notifyListeners();
  }

  Future<SchoolBookingRequest> confirmTime(int requestId) async {
    final updated =
        await CounsellingRepository.confirmSchoolRequestTime(requestId);
    _updateSchoolRequest(updated);
    return updated;
  }

  Future<SchoolBookingRequest> cancelSchoolRequest(int requestId) async {
    final updated = await CounsellingRepository.cancelSchoolRequest(requestId);
    _updateSchoolRequest(updated);
    return updated;
  }

  void _updateSchoolRequest(SchoolBookingRequest updated) {
    final idx = _schoolRequests.indexWhere((r) => r.id == updated.id);
    if (idx >= 0) {
      _schoolRequests[idx] = updated;
    } else {
      _schoolRequests.insert(0, updated);
    }
    if (!_disposed) notifyListeners();
  }

  void applyFilter(CounsellorFilter f) {
    _filter = f;
    if (!_disposed) notifyListeners();
  }

  void clearFilters() {
    _filter = const CounsellorFilter();
    if (!_disposed) notifyListeners();
  }

  Future<void> submitRequest(CounsellingRequest req) async {
    await CounsellingRepository.submitSchoolRequest({
      'counsellor_id': req.counsellorId,
      'school_name': req.schoolName,
      'coordinator_name': req.principalName,
      'coordinator_email': req.schoolEmail,
      'topic': req.topic,
      'preferred_at': req.preferredDate.toIso8601String(),
      'mode': req.sessionMode.name,
      'expected_students': req.studentCount,
      'class_group': req.gradeLevel,
      if (req.specialRequirements.isNotEmpty)
        'special_requirements': req.specialRequirements,
    });
    _requests.insert(0, req);
    await loadSchoolRequests(force: true);
  }

  void updateRequestStatus(
    int requestId,
    RequestStatus status, {
    String? notes,
    List<String>? volunteers,
  }) {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx < 0) return;
    _requests[idx] = _requests[idx].copyWith(
      status: status,
      eventManagerNotes: notes,
      assignedVolunteers: volunteers,
      confirmedAt: status == RequestStatus.confirmed ? DateTime.now() : null,
    );
    if (!_disposed) notifyListeners();
  }

  void addCounsellor(CounsellorProfile c) {
    _counsellors.insert(0, c);
    if (!_disposed) notifyListeners();
  }

  Future<void> toggleFeatured(int counsellorId) async {
    final idx = _counsellors.indexWhere((c) => c.id == counsellorId);
    if (idx < 0) return;
    final c = _counsellors[idx];
    final next = !c.isFeatured;
    // Optimistic update, rolled back if the persist call fails.
    _counsellors[idx] = c.copyWith(isFeatured: next);
    if (!_disposed) notifyListeners();
    try {
      await CounsellingRepository.updateCounsellorByUserId(
        counsellorId,
        {'featured': next},
      );
    } catch (_) {
      _counsellors[idx] = c;
      if (!_disposed) notifyListeners();
    }
  }

  void updateCounsellor(CounsellorProfile profile) {
    final index = _counsellors.indexWhere((c) => c.id == profile.id);
    if (index < 0) return;
    _counsellors[index] = profile;
    if (!_disposed) notifyListeners();
  }

  void assignCounsellor(int requestId, CounsellorProfile counsellor) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index < 0) return;
    _requests[index] = _requests[index].copyWith(
      counsellorId: counsellor.id,
      counsellorName: counsellor.name,
      counsellorCategory: counsellor.category,
      status: RequestStatus.assigned,
    );
    if (!_disposed) notifyListeners();
  }

}
