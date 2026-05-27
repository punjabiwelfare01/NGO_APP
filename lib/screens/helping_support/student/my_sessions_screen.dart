import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../repositories/wellness_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../../../widgets/top_header.dart';
import '../widgets/session_tile.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({super.key});

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> {
  ViewState _state = ViewState.loading;
  List<ApiCounsellingSession> _sessions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = ViewState.loading;
      _error = null;
    });
    try {
      final sessions = await WellnessRepository.getCounsellingSessions(AppState.userId);
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _state = ViewState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = ViewState.error;
        _error = 'Could not load your sessions.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _sessions.where((s) => s.isUpcoming).toList();
    final past = _sessions.where((s) => !s.isUpcoming).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const TopHeader(
              title: 'My Sessions',
              subtitle: 'Your upcoming and past counselling sessions',
              actionIcon: Icons.history_rounded,
            ),
            Expanded(
              child: _buildBody(upcoming, past),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      List<ApiCounsellingSession> upcoming, List<ApiCounsellingSession> past) {
    if (_state == ViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_state == ViewState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Error', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.muted),
            SizedBox(height: 12),
            Text('No sessions yet.', style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (upcoming.isNotEmpty) ...[
          const _SectionLabel(label: 'Upcoming'),
          ...upcoming.map((s) => SessionTile(session: s)),
        ],
        if (past.isNotEmpty) ...[
          const _SectionLabel(label: 'Past Sessions'),
          ...past.map((s) => SessionTile(session: s)),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
