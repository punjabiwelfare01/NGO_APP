import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../models/event_models.dart';
import '../models/quiz_models.dart';
import '../repositories/api_client.dart';
import '../repositories/event_repository.dart';
import 'view_state.dart';

class EventValidationItem {
  const EventValidationItem({
    required this.step,
    required this.label,
    required this.message,
  });

  final String step;
  final String label;
  final String message;
}

class CreateEventViewModel extends ChangeNotifier {
  bool _disposed = false;
  DateTime? _lastDraftSavedAt;

  DateTime? get lastDraftSavedAt => _lastDraftSavedAt;
  String get draftStatusLabel {
    if (_lastDraftSavedAt == null) return 'Draft auto-save ready';
    final hour = _lastDraftSavedAt!.hour.toString().padLeft(2, '0');
    final minute = _lastDraftSavedAt!.minute.toString().padLeft(2, '0');
    return 'Draft auto-saved at $hour:$minute';
  }

  void autosaveDraft() {
    _lastDraftSavedAt = DateTime.now();
    if (!_disposed) notifyListeners();
  }

  // ── Step 1: Basic Info ─────────────────────────────────────────────────────
  String _title = '';
  String _subtitle = '';
  String _description = '';
  EventType _selectedEventType = EventType.quiz;
  String _themeColor = AppConfig.defaultEventColor;

  String get title => _title;
  String get subtitle => _subtitle;
  String get description => _description;
  EventType get selectedEventType => _selectedEventType;
  String get themeColor => _themeColor;

  void setTitle(String v) {
    _title = v;
    notifyListeners();
  }

  void setSubtitle(String v) {
    _subtitle = v;
    notifyListeners();
  }

  void setDescription(String v) {
    _description = v;
    notifyListeners();
  }

  void setEventType(EventType v) {
    _selectedEventType = v;
    _quizRequired = _isQuizRequiredByType;
    notifyListeners();
  }

  void setThemeColor(String v) {
    _themeColor = v;
    notifyListeners();
  }

  // ── Step 2: Timeline ───────────────────────────────────────────────────────
  DateTime? _registrationStart;
  DateTime? _registrationEnd;
  DateTime? _eventStart;
  DateTime? _eventEnd;
  DateTime? _resultDate;
  DateTime? _counsellingDate;
  bool _autoPublish = false;
  bool _autoClose = false;
  bool _autoResultPublish = false;
  bool _autoNotification = true;

  DateTime? get registrationStart => _registrationStart;
  DateTime? get registrationEnd => _registrationEnd;
  DateTime? get eventStart => _eventStart;
  DateTime? get eventEnd => _eventEnd;
  DateTime? get resultDate => _resultDate;
  DateTime? get counsellingDate => _counsellingDate;
  bool get autoPublish => _autoPublish;
  bool get autoClose => _autoClose;
  bool get autoResultPublish => _autoResultPublish;
  bool get autoNotification => _autoNotification;

  void setRegistrationStart(DateTime? v) {
    _registrationStart = v;
    notifyListeners();
  }

  void setRegistrationEnd(DateTime? v) {
    _registrationEnd = v;
    notifyListeners();
  }

  void setEventStart(DateTime? v) {
    _eventStart = v;
    notifyListeners();
  }

  void setEventEnd(DateTime? v) {
    _eventEnd = v;
    notifyListeners();
  }

  void setResultDate(DateTime? v) {
    _resultDate = v;
    notifyListeners();
  }

  void setCounsellingDate(DateTime? v) {
    _counsellingDate = v;
    notifyListeners();
  }

  void setAutoPublish(bool v) {
    _autoPublish = v;
    notifyListeners();
  }

  void setAutoClose(bool v) {
    _autoClose = v;
    notifyListeners();
  }

  void setAutoResultPublish(bool v) {
    _autoResultPublish = v;
    notifyListeners();
  }

  void setAutoNotification(bool v) {
    _autoNotification = v;
    notifyListeners();
  }

  // ── Step 3: Rules ──────────────────────────────────────────────────────────
  int? _ageMin;
  int? _ageMax;
  double? _minQuizScore;
  int _requiredChallenges = 0;
  int? _maxParticipants;

  int? get ageMin => _ageMin;
  int? get ageMax => _ageMax;
  double? get minQuizScore => _minQuizScore;
  int get requiredChallenges => _requiredChallenges;
  int? get maxParticipants => _maxParticipants;

  void setAgeMin(int? v) {
    _ageMin = v;
    notifyListeners();
  }

  void setAgeMax(int? v) {
    _ageMax = v;
    notifyListeners();
  }

  void setMinQuizScore(double? v) {
    _minQuizScore = v;
    notifyListeners();
  }

  void setRequiredChallenges(int v) {
    _requiredChallenges = v;
    notifyListeners();
  }

  void setMaxParticipants(int? v) {
    _maxParticipants = v;
    notifyListeners();
  }

  // ── Step 4: Quiz ───────────────────────────────────────────────────────────
  String _quizTitle = '';
  String _quizAttachmentMethod = 'create';
  bool _hasQuiz = false;
  bool _quizRequired = false;
  QuizSummary? _createdQuiz;

  // Upload-specific state
  List<int>? _uploadFileBytes;
  String? _uploadFileName;
  int? _uploadedQuizId;
  bool _uploadingFile = false;
  String? _uploadError;

  String get quizTitle => _quizTitle;
  String get quizAttachmentMethod => _quizAttachmentMethod;
  bool get hasQuiz => _hasQuiz;
  bool get quizRequired => _isQuizRequiredByType || _quizRequired;
  bool get quizCanBeSkipped => !_isQuizRequiredByType;
  bool get quizReady {
    if (!quizRequired) return true;
    return switch (_quizAttachmentMethod) {
      'create' => _createdQuiz != null && _createdQuiz!.questionCount >= 3,
      'existing' => int.tryParse(_quizTitle.trim()) != null,
      'upload' => _uploadedQuizId != null,
      _ => false,
    };
  }

  QuizSummary? get createdQuiz => _createdQuiz;
  int? get createdQuizId => _createdQuiz?.id;
  String? get uploadFileName => _uploadFileName;
  int? get uploadedQuizId => _uploadedQuizId;
  bool get uploadingFile => _uploadingFile;
  String? get uploadError => _uploadError;
  bool get uploadReady => _uploadedQuizId != null;

  bool get _isQuizRequiredByType =>
      _selectedEventType == EventType.quiz ||
      _selectedEventType == EventType.dailyChallenge;

  void setQuizTitle(String v) {
    _quizTitle = v;
    _createdQuiz = null;
    notifyListeners();
  }

  void setQuizAttachmentMethod(String v) {
    _quizAttachmentMethod = v;
    if (v != 'create') {
      _createdQuiz = null;
    }
    notifyListeners();
  }

  void setCreatedQuiz(QuizSummary quiz) {
    _createdQuiz = quiz;
    _quizTitle = quiz.title;
    _hasQuiz = true;
    notifyListeners();
  }

  void setHasQuiz(bool v) {
    _hasQuiz = v;
    notifyListeners();
  }

  void setQuizRequired(bool v) {
    if (_isQuizRequiredByType) return;
    _quizRequired = v;
    if (!v) {
      _hasQuiz = false;
      _createdQuiz = null;
      _uploadedQuizId = null;
      _minQuizScore = null;
    }
    notifyListeners();
  }

  void setPickedFile(List<int> bytes, String name) {
    _uploadFileBytes = bytes;
    _uploadFileName = name;
    _uploadedQuizId = null;
    _uploadError = null;
    notifyListeners();
  }

  Future<void> uploadQuizFile() async {
    if (_uploadFileBytes == null || _uploadFileName == null) return;
    final title = _title.isNotEmpty ? '$_title Quiz' : 'Imported Quiz';
    _uploadingFile = true;
    _uploadError = null;
    if (!_disposed) notifyListeners();
    try {
      final json =
          await ApiClient.postMultipart(
                '/quizzes/import',
                fields: {
                  'title': title,
                  'difficulty': AppConfig.defaultQuizDifficulty,
                },
                fileBytes: _uploadFileBytes!,
                fileName: _uploadFileName!,
              )
              as Map<String, dynamic>;
      _uploadedQuizId = json['id'] as int;
      _uploadingFile = false;
    } catch (_) {
      _uploadingFile = false;
      _uploadError = 'Upload failed. Check file format and try again.';
    }
    if (!_disposed) notifyListeners();
  }

  // ── Step 5: Selection ──────────────────────────────────────────────────────
  SelectionMethod _selectedSelectionMethod = SelectionMethod.luckyDraw;
  int? _maxSelections;

  SelectionMethod get selectedSelectionMethod => _selectedSelectionMethod;
  int? get maxSelections => _maxSelections;

  void setSelectionMethod(SelectionMethod v) {
    _selectedSelectionMethod = v;
    if (v == SelectionMethod.scoreBased) {
      _quizRequired = true;
    }
    notifyListeners();
  }

  void setMaxSelections(int? v) {
    _maxSelections = v;
    notifyListeners();
  }

  // ── Step 6: Rewards ────────────────────────────────────────────────────────
  bool _counsellingEnabled = false;
  bool _certificateEnabled = false;
  bool _scholarshipEnabled = false;
  bool _mentorshipEnabled = false;

  bool get counsellingEnabled => _counsellingEnabled;
  bool get certificateEnabled => _certificateEnabled;
  bool get scholarshipEnabled => _scholarshipEnabled;
  bool get mentorshipEnabled => _mentorshipEnabled;

  void setCounsellingEnabled(bool v) {
    _counsellingEnabled = v;
    notifyListeners();
  }

  void setCertificateEnabled(bool v) {
    _certificateEnabled = v;
    notifyListeners();
  }

  void setScholarshipEnabled(bool v) {
    _scholarshipEnabled = v;
    notifyListeners();
  }

  void setMentorshipEnabled(bool v) {
    _mentorshipEnabled = v;
    notifyListeners();
  }

  // ── Step 7: Notifications ──────────────────────────────────────────────────
  bool _pushNotification = true;
  bool _inAppNotification = true;
  bool _emailNotification = false;

  bool get pushNotification => _pushNotification;
  bool get inAppNotification => _inAppNotification;
  bool get emailNotification => _emailNotification;

  void setPushNotification(bool v) {
    _pushNotification = v;
    notifyListeners();
  }

  void setInAppNotification(bool v) {
    _inAppNotification = v;
    notifyListeners();
  }

  void setEmailNotification(bool v) {
    _emailNotification = v;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────────────────────
  Map<String, String> getTimelineErrors() {
    final now = DateTime.now();
    final errors = <String, String>{};

    if (_registrationStart == null) {
      errors['registrationStart'] = 'Registration start is required';
    } else if (!_registrationStart!.isAfter(now)) {
      errors['registrationStart'] = 'Must be a future date and time';
    }

    if (_registrationEnd == null) {
      errors['registrationEnd'] = 'Registration end is required';
    } else if (_registrationStart != null &&
        !_registrationEnd!.isAfter(_registrationStart!)) {
      errors['registrationEnd'] = 'Must be after registration start';
    }

    if (_eventStart == null) {
      errors['eventStart'] = 'Event start is required';
    } else if (!_eventStart!.isAfter(now)) {
      errors['eventStart'] = 'Must be a future date and time';
    } else if (_registrationEnd != null &&
        !_eventStart!.isAfter(_registrationEnd!)) {
      errors['eventStart'] = 'Must be after registration end';
    }

    if (_eventEnd == null) {
      errors['eventEnd'] = 'Event end is required';
    } else if (_eventStart != null && !_eventEnd!.isAfter(_eventStart!)) {
      errors['eventEnd'] = 'Must be after event start';
    }

    if (_resultDate != null &&
        _eventEnd != null &&
        !_resultDate!.isAfter(_eventEnd!)) {
      errors['resultDate'] = 'Must be after event end';
    }

    if (_counsellingDate != null &&
        _eventEnd != null &&
        !_counsellingDate!.isAfter(_eventEnd!)) {
      errors['counsellingDate'] = 'Must be after event end';
    }

    return errors;
  }

  List<EventValidationItem> getValidationItems() {
    final items = <EventValidationItem>[];

    if (_title.trim().isEmpty) {
      items.add(
        const EventValidationItem(
          step: 'Basic Info',
          label: 'Event title',
          message: 'Add an event title.',
        ),
      );
    }

    for (final entry in getTimelineErrors().entries) {
      items.add(
        EventValidationItem(
          step: 'Timeline',
          label: _timelineFieldLabel(entry.key),
          message: entry.value,
        ),
      );
    }

    if (_ageMin == null) {
      items.add(
        const EventValidationItem(
          step: 'Rules',
          label: 'Min age',
          message: 'Minimum age is required.',
        ),
      );
    }
    if (_ageMax == null) {
      items.add(
        const EventValidationItem(
          step: 'Rules',
          label: 'Max age',
          message: 'Maximum age is required.',
        ),
      );
    }
    if (_ageMin != null && _ageMax != null && _ageMin! > _ageMax!) {
      items.add(
        const EventValidationItem(
          step: 'Rules',
          label: 'Age range',
          message: 'Minimum age must be lower than maximum age.',
        ),
      );
    }
    if (quizRequired && _minQuizScore == null) {
      items.add(
        const EventValidationItem(
          step: 'Rules',
          label: 'Minimum quiz score',
          message: 'Minimum quiz score is required.',
        ),
      );
    }
    if (_minQuizScore != null && (_minQuizScore! < 0 || _minQuizScore! > 100)) {
      items.add(
        const EventValidationItem(
          step: 'Rules',
          label: 'Minimum quiz score',
          message: 'Use a score between 0 and 100.',
        ),
      );
    }
    if (_maxParticipants == null) {
      items.add(
        const EventValidationItem(
          step: 'Rules',
          label: 'Max participants',
          message: 'Max participants is required. Use 0 for unlimited.',
        ),
      );
    } else if (_maxParticipants! < 0) {
      items.add(
        const EventValidationItem(
          step: 'Rules',
          label: 'Max participants',
          message: 'Use 0 for unlimited or a positive number.',
        ),
      );
    }

    if (quizRequired && !quizReady) {
      items.add(
        EventValidationItem(
          step: 'Quiz',
          label: 'Quiz attachment',
          message: _quizMissingMessage(),
        ),
      );
    }

    if (_maxSelections != null && _maxSelections! < 1) {
      items.add(
        const EventValidationItem(
          step: 'Selection',
          label: 'Max selections',
          message: 'Use a positive number, or leave it blank for unlimited.',
        ),
      );
    }

    if (!_pushNotification && !_inAppNotification && !_emailNotification) {
      items.add(
        const EventValidationItem(
          step: 'Notifications',
          label: 'Notification channel',
          message: 'Keep at least one notification channel enabled.',
        ),
      );
    }

    return items;
  }

  bool get canPublish => getValidationItems().isEmpty;

  String _timelineFieldLabel(String key) => switch (key) {
    'registrationStart' => 'Registration start',
    'registrationEnd' => 'Registration end',
    'eventStart' => 'Event start',
    'eventEnd' => 'Event end',
    'resultDate' => 'Result date',
    'counsellingDate' => 'Counselling date',
    _ => key,
  };

  String _quizMissingMessage() {
    return switch (_quizAttachmentMethod) {
      'existing' => 'Enter a valid numeric quiz ID.',
      'upload' => 'Upload a CSV or JSON quiz file.',
      _ => 'Build and save a quiz with at least 3 questions.',
    };
  }

  // ── Submission ─────────────────────────────────────────────────────────────
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  EventModel? _createdEvent;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  EventModel? get createdEvent => _createdEvent;

  Map<String, dynamic> toApiBody() {
    final effectiveQuizId = quizRequired
        ? _quizAttachmentMethod == 'create' && _createdQuiz != null
              ? _createdQuiz!.id
              : _quizAttachmentMethod == 'existing'
              ? int.tryParse(_quizTitle.trim())
              : _quizAttachmentMethod == 'upload'
              ? _uploadedQuizId
              : null
        : null;

    return {
      'title': _title,
      'subtitle': _subtitle.isEmpty ? null : _subtitle,
      'description': _description.isEmpty ? null : _description,
      'event_type': _selectedEventType.apiValue,
      'is_daily_challenge': _selectedEventType == EventType.dailyChallenge,
      'quiz_id': effectiveQuizId,
      'quiz_title': null,
      'theme_color': _themeColor,
      'registration_start': _registrationStart?.toIso8601String(),
      'registration_end': _registrationEnd?.toIso8601String(),
      'event_start': _eventStart?.toIso8601String(),
      'event_end': _eventEnd?.toIso8601String(),
      'result_date': _resultDate?.toIso8601String(),
      'counselling_date': _counsellingDate?.toIso8601String(),
      'auto_publish': _autoPublish,
      'auto_close': _autoClose,
      'auto_result_publish': _autoResultPublish,
      'auto_notification': _autoNotification,
      'age_min': _ageMin,
      'age_max': _ageMax,
      'min_quiz_score': quizRequired ? _minQuizScore : null,
      'required_challenges': _requiredChallenges,
      'max_participants': _maxParticipants == 0 ? null : _maxParticipants,
      'selection_method': _selectedSelectionMethod.apiValue,
      'max_selections': _maxSelections,
      'counselling_enabled': _counsellingEnabled,
      'certificate_enabled': _certificateEnabled,
      'scholarship_enabled': _scholarshipEnabled,
      'mentorship_enabled': _mentorshipEnabled,
      'push_notification': _pushNotification,
      'in_app_notification': _inAppNotification,
      'email_notification': _emailNotification,
    };
  }

  Future<bool> submit() async {
    if (!canPublish) {
      _state = ViewState.error;
      _errorMessage = 'Fix the missing fields checklist before publishing.';
      if (!_disposed) notifyListeners();
      return false;
    }
    _state = ViewState.loading;
    _errorMessage = null;
    if (!_disposed) notifyListeners();
    try {
      final body = toApiBody();
      _createdEvent = await EventRepository.createEvent(body);
      if (!_isPublicStatus(_createdEvent!.status)) {
        _createdEvent = await EventRepository.publishEvent(_createdEvent!.id);
      }
      _state = ViewState.idle;
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _state = ViewState.error;
      _errorMessage = 'Failed to publish event. Please try again.';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  bool _isPublicStatus(EventStatus status) =>
      status == EventStatus.published ||
      status == EventStatus.registrationOpen ||
      status == EventStatus.live;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
