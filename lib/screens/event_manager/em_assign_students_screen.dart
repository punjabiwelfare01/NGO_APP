import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../repositories/event_manager_repository.dart';

class EMAssignStudentsScreen extends StatefulWidget {
  const EMAssignStudentsScreen({
    required this.activityId,
    required this.activityTitle,
    required this.alreadyAssignedIds,
    super.key,
  });

  final int activityId;
  final String activityTitle;
  final Set<int> alreadyAssignedIds;

  @override
  State<EMAssignStudentsScreen> createState() => _EMAssignStudentsScreenState();
}

class _EMAssignStudentsScreenState extends State<EMAssignStudentsScreen> {
  final _searchCtrl = TextEditingController();
  List<EMNgoStudent> _all = [];
  List<EMNgoStudent> _filtered = [];
  final Set<int> _selected = {};
  String? _selectedInterest;
  bool _loading = true;
  bool _assigning = false;
  String? _error;

  // All distinct interests across all students
  List<String> get _allInterests {
    final seen = <String>{};
    for (final s in _all) {
      seen.addAll(s.interests);
    }
    return seen.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await EventManagerRepository.getAllNgoStudents();
      setState(() {
        _all = students;
        _filtered = students;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _all.where((s) {
        final matchesSearch = q.isEmpty ||
            s.name.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q) ||
            (s.schoolName?.toLowerCase().contains(q) ?? false) ||
            (s.location?.toLowerCase().contains(q) ?? false);

        final matchesInterest = _selectedInterest == null ||
            s.interests.contains(_selectedInterest);

        return matchesSearch && matchesInterest;
      }).toList();
    });
  }

  void _setInterestFilter(String? interest) {
    setState(() => _selectedInterest = interest);
    _filter();
  }

  Future<void> _assign() async {
    if (_selected.isEmpty) return;
    setState(() => _assigning = true);
    try {
      await EventManagerRepository.assignStudents(
        widget.activityId,
        studentIds: _selected.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selected.length} student(s) assigned successfully'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.softRed),
        );
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newlySelected = _selected.difference(widget.alreadyAssignedIds);
    final interests = _allInterests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assign Students',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(
              widget.activityTitle,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (newlySelected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _assigning
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : FilledButton.icon(
                      onPressed: _assign,
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: Text('Assign ${newlySelected.length}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, school or location…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filter();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // ── Interest filter chips ─────────────────────────────────────────
          if (!_loading && _error == null && interests.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "All" chip to clear filter
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedInterest == null,
                        onSelected: (_) => _setInterestFilter(null),
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _selectedInterest == null
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                        side: BorderSide(
                          color: _selectedInterest == null
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.muted.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                    ...interests.map((interest) {
                      final isActive = _selectedInterest == interest;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(interest),
                          selected: isActive,
                          onSelected: (_) => _setInterestFilter(
                              isActive ? null : interest),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? AppColors.primary : AppColors.muted,
                          ),
                          side: BorderSide(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : AppColors.muted.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // ── Summary bar ───────────────────────────────────────────────────
          if (!_loading && _error == null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFF0F4FF),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} student${_filtered.length == 1 ? "" : "s"}',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  if (_selectedInterest != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Interest: $_selectedInterest',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (widget.alreadyAssignedIds.isNotEmpty)
                    Text(
                      '${widget.alreadyAssignedIds.length} already assigned',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                  if (newlySelected.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${newlySelected.length} selected',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // ── Student list ──────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _load)
                    : _filtered.isEmpty
                        ? _EmptyState(
                            message: (_searchCtrl.text.isEmpty &&
                                    _selectedInterest == null)
                                ? 'No registered students found'
                                : _selectedInterest != null
                                    ? 'No students interested in "$_selectedInterest"'
                                    : 'No students match "${_searchCtrl.text}"',
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(12, 8, 12, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final s = _filtered[i];
                              final alreadyAssigned =
                                  widget.alreadyAssignedIds.contains(s.id);
                              final selected = _selected.contains(s.id);
                              return _StudentTile(
                                student: s,
                                selected: selected || alreadyAssigned,
                                alreadyAssigned: alreadyAssigned,
                                highlightInterest: _selectedInterest,
                                onChanged: alreadyAssigned
                                    ? null
                                    : (v) => setState(() {
                                          if (v == true) {
                                            _selected.add(s.id);
                                          } else {
                                            _selected.remove(s.id);
                                          }
                                        }),
                              );
                            },
                          ),
          ),
        ],
      ),

      // ── Assign bottom button ───────────────────────────────────────────────
      bottomNavigationBar: newlySelected.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _assigning ? null : _assign,
                  icon: _assigning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_add_rounded),
                  label: Text(_assigning
                      ? 'Assigning…'
                      : 'Assign ${newlySelected.length} '
                          'Student${newlySelected.length == 1 ? "" : "s"}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ── Student Tile ──────────────────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.student,
    required this.selected,
    required this.alreadyAssigned,
    required this.onChanged,
    this.highlightInterest,
  });

  final EMNgoStudent student;
  final bool selected;
  final bool alreadyAssigned;
  final void Function(bool?)? onChanged;
  final String? highlightInterest;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: alreadyAssigned
          ? const Color(0xFFF1F8E9)
          : selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alreadyAssigned
              ? const Color(0xFF81C784)
              : selected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: onChanged,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        activeColor: AppColors.primary,
        checkColor: Colors.white,
        isThreeLine: student.interests.isNotEmpty,
        secondary: CircleAvatar(
          radius: 22,
          backgroundColor: alreadyAssigned
              ? const Color(0xFF81C784).withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.12),
          child: alreadyAssigned
              ? const Icon(Icons.check_rounded,
                  color: Color(0xFF2E7D32), size: 20)
              : Text(
                  student.initials,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13),
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink),
              ),
            ),
            if (alreadyAssigned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Assigned',
                    style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // School / location row
            Row(
              children: [
                if (student.schoolName != null) ...[
                  const Icon(Icons.school_outlined,
                      size: 11, color: AppColors.muted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      student.schoolName!,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (student.location != null && student.schoolName != null)
                  const Text(' • ',
                      style:
                          TextStyle(color: AppColors.muted, fontSize: 11)),
                if (student.location != null) ...[
                  const Icon(Icons.place_rounded,
                      size: 11, color: AppColors.muted),
                  const SizedBox(width: 2),
                  Text(student.location!,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                ],
              ],
            ),
            // Interest chips
            if (student.interests.isNotEmpty) ...[
              const SizedBox(height: 5),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: student.interests.map((interest) {
                  final isHighlighted = interest == highlightInterest;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(20),
                      border: isHighlighted
                          ? Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.interests_rounded,
                          size: 9,
                          color: isHighlighted
                              ? AppColors.primary
                              : const Color(0xFF6A1B9A),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          interest,
                          style: TextStyle(
                            color: isHighlighted
                                ? AppColors.primary
                                : const Color(0xFF6A1B9A),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 56, color: AppColors.muted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.softRed, size: 40),
            const SizedBox(height: 12),
            Text(error,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
