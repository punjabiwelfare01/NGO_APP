import 'package:flutter/foundation.dart';

import '../models/event_models.dart';
import '../repositories/event_repository.dart';
import 'view_state.dart';

class EventListViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  List<EventModel> _events = [];
  String? _filterStatus;
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<EventModel> get events => _events;
  String? get filterStatus => _filterStatus;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load({
    bool keepExistingOnEmpty = false,
    bool showLoading = true,
  }) async {
    if (showLoading) _state = ViewState.loading;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      final events = await EventRepository.getEvents(status: _filterStatus);
      if (events.isNotEmpty || !keepExistingOnEmpty) {
        _events = events;
      }
      _state = ViewState.idle;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Failed to load events.';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setFilter(String? status) async {
    _filterStatus = status;
    await load();
  }

  void addOrUpdate(EventModel event) {
    if (_filterStatus != null && event.status.apiValue != _filterStatus) {
      return;
    }
    _events = [event, ..._events.where((existing) => existing.id != event.id)];
    if (!_disposed) notifyListeners();
  }
}
