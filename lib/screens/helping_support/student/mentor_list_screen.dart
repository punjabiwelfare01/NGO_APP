import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/counselling_models.dart';
import '../../../repositories/counselling_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../../../widgets/top_header.dart';
import '../widgets/mentor_card.dart';
import 'mentor_detail_screen.dart';

class MentorListScreen extends StatefulWidget {
  const MentorListScreen({super.key});

  @override
  State<MentorListScreen> createState() => _MentorListScreenState();
}

class _MentorListScreenState extends State<MentorListScreen> {
  ViewState _state = ViewState.loading;
  List<MentorProfile> _mentors = [];
  String? _selectedCategory;
  String _search = '';
  String? _error;

  static const _categories = ['Academic', 'Career', 'Wellness', 'Mental Health', 'Life Skills'];

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
      final mentors = await CounsellingRepository.getMentors(category: _selectedCategory);
      if (!mounted) return;
      setState(() {
        _mentors = mentors;
        _state = ViewState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = ViewState.error;
        _error = 'Could not load mentors.';
      });
    }
  }

  List<MentorProfile> get _filtered {
    if (_search.isEmpty) return _mentors;
    final q = _search.toLowerCase();
    return _mentors.where((m) =>
        m.displayName.toLowerCase().contains(q) ||
        (m.expertise?.toLowerCase().contains(q) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const TopHeader(
              title: 'Browse Mentors',
              subtitle: 'Find the right mentor for your needs',
              actionIcon: Icons.person_search_rounded,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or expertise',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () {
                      setState(() => _selectedCategory = null);
                      _load();
                    },
                  ),
                  ..._categories.map((c) => _CategoryChip(
                    label: c,
                    selected: _selectedCategory == c,
                    onTap: () {
                      setState(() => _selectedCategory = c);
                      _load();
                    },
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
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
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return const Center(
        child: Text('No mentors found.', style: TextStyle(color: AppColors.muted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final mentor = filtered[i];
        return MentorCard(
          mentor: mentor,
          onTap: () => Navigator.of(ctx).push(
            MaterialPageRoute(builder: (_) => MentorDetailScreen(mentor: mentor)),
          ),
          onBook: () => Navigator.of(ctx).push(
            MaterialPageRoute(builder: (_) => MentorDetailScreen(mentor: mentor)),
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.muted,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
