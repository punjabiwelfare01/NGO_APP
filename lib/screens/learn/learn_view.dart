import 'package:flutter/material.dart';

import '../../viewmodels/learn_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/filter_chip_label.dart';
import '../../widgets/search_box.dart';
import '../../widgets/top_header.dart';
import 'widgets/course_card.dart';

class LearnView extends StatefulWidget {
  const LearnView({super.key});

  @override
  State<LearnView> createState() => _LearnViewState();
}

class _LearnViewState extends State<LearnView> {
  late final LearnViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = LearnViewModel();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScrollView(
      children: [
        const TopHeader(
          title: 'Skill Courses',
          subtitle: 'Build confidence one tiny win at a time.',
          actionIcon: Icons.search_rounded,
        ),
        const SearchBox(hint: 'Search skills...'),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilterChipLabel(label: 'Web devlopement course', selected: true),
            FilterChipLabel(label: 'Communication'),
            FilterChipLabel(label: 'Cyber Safety'),
            FilterChipLabel(label: 'Drawing'),
            FilterChipLabel(label: 'Public Speaking'),
          ],
        ),
        const SizedBox(height: 4),
        ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            if (_vm.state == ViewState.loading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (_vm.state == ViewState.error) {
              return Center(
                child: Column(
                  children: [
                    Text(_vm.errorMessage ?? 'Error',
                        style: const TextStyle(color: Colors.grey)),
                    TextButton(
                        onPressed: _vm.load, child: const Text('Retry')),
                  ],
                ),
              );
            }
            return Column(
              children:
                  _vm.courses.map((c) => CourseCard(course: c)).toList(),
            );
          },
        ),
      ],
    );
  }
}
