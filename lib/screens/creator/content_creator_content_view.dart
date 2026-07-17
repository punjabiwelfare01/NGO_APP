import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/creator_content.dart';
import '../../repositories/creator_repository.dart';

class ContentCreatorContentView extends StatefulWidget {
  const ContentCreatorContentView({super.key});

  @override
  State<ContentCreatorContentView> createState() =>
      _ContentCreatorContentViewState();
}

class _ContentCreatorContentViewState extends State<ContentCreatorContentView> {
  final TextEditingController _searchCtrl = TextEditingController();
  _ContentFilter _selectedFilter = _ContentFilter.all;
  List<CreatorContentItem> _items = [];
  bool _loading = true;
  String? _error;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _load();
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
      final items = await CreatorRepository.getContent(
        status: _selectedFilter.apiValue,
        search: _searchCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load creator content.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          _ContentHeader(
            showSearch: _showSearch,
            searchCtrl: _searchCtrl,
            onSearchTap: () => setState(() => _showSearch = !_showSearch),
            onSearchChanged: (_) => _load(),
            onClearSearch: () {
              _searchCtrl.clear();
              _load();
            },
          ),
          const SizedBox(height: 18),
          _FilterTabs(
            selected: _selectedFilter,
            onSelected: (filter) {
              setState(() => _selectedFilter = filter);
              _load();
            },
          ),
          const SizedBox(height: 16),
          _ContentSummaryCards(items: _items),
          const SizedBox(height: 16),
          if (_loading)
            const _LoadingCard()
          else if (_error != null)
            _ErrorCard(message: _error!, onRetry: _load)
          else if (_items.isEmpty)
            const _EmptyCard()
          else
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ContentItemCard(
                  item: item,
                  onAction: (action) => _handleAction(action, item),
                ),
              ),
            ),
          _QuickActionsCard(onRefresh: _load),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    _ContentAction action,
    CreatorContentItem item,
  ) async {
    try {
      switch (action) {
        case _ContentAction.viewDetails:
        case _ContentAction.preview:
          await _showDetails(item);
          return;
        case _ContentAction.edit:
          await _showEditTitle(item);
          break;
        case _ContentAction.submitReview:
          await CreatorRepository.submitReview(type: item.type, id: item.id);
          _showSnack('Submitted for review.');
          break;
        case _ContentAction.publish:
          await CreatorRepository.publish(type: item.type, id: item.id);
          _showSnack('Published.');
          break;
        case _ContentAction.unpublish:
          await CreatorRepository.unpublish(type: item.type, id: item.id);
          _showSnack('Moved to draft.');
          break;
        case _ContentAction.delete:
          final confirmed = await _confirmDelete(item);
          if (confirmed != true) return;
          await CreatorRepository.deleteContent(type: item.type, id: item.id);
          _showSnack('Content deleted.');
          break;
      }
      await _load();
    } catch (_) {
      _showSnack('Action failed. Please try again.', isError: true);
    }
  }

  Future<void> _showDetails(CreatorContentItem item) async {
    final detail = await CreatorRepository.getContentDetail(
      type: item.type,
      id: item.id,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(item: detail),
    );
  }

  Future<void> _showEditTitle(CreatorContentItem item) async {
    final ctrl = TextEditingController(text: item.title);
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final title = ctrl.text.trim();
    ctrl.dispose();
    if (updated == true && title.isNotEmpty) {
      await CreatorRepository.updateContent(
        type: item.type,
        id: item.id,
        data: {'title': title},
      );
      _showSnack('Content updated.');
    }
  }

  Future<bool?> _confirmDelete(CreatorContentItem item) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.softRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.softRed : AppColors.secondary,
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  const _ContentHeader({
    required this.showSearch,
    required this.searchCtrl,
    required this.onSearchTap,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final bool showSearch;
  final TextEditingController searchCtrl;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage learning materials',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onSearchTap,
              tooltip: 'Search content',
              icon: const Icon(Icons.search_rounded, size: 28),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () {},
              tooltip: 'Content filters',
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        if (showSearch) ...[
          const SizedBox(height: 14),
          TextField(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search content...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: onClearSearch,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Clear search',
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AppColors.ink.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AppColors.ink.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelected});

  final _ContentFilter selected;
  final ValueChanged<_ContentFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _ContentFilter.values) ...[
            _FilterButton(
              label: filter.label,
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 118,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : AppColors.ink.withValues(alpha: 0.10),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentSummaryCards extends StatelessWidget {
  const _ContentSummaryCards({required this.items});

  final List<CreatorContentItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final published = items.where((item) => item.status == 'published').length;
    final drafts = items.where((item) => item.status == 'draft').length;
    final cards = [
      _SummaryData(
        icon: Icons.description_rounded,
        label: 'Total',
        value: '$total',
        helper: 'All content',
        color: AppColors.primary,
      ),
      _SummaryData(
        icon: Icons.task_alt_rounded,
        label: 'Published',
        value: '$published',
        helper: '${_percent(published, total)}% of total',
        color: AppColors.secondary,
      ),
      _SummaryData(
        icon: Icons.article_rounded,
        label: 'Drafts',
        value: '$drafts',
        helper: '${_percent(drafts, total)}% of total',
        color: const Color(0xFF7F5AF0),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 3 ? 1.55 : 3.6,
          ),
          itemBuilder: (context, index) => _SummaryCard(data: cards[index]),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 27),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentItemCard extends StatelessWidget {
  const _ContentItemCard({required this.item, required this.onAction});

  final CreatorContentItem item;
  final ValueChanged<_ContentAction> onAction;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(item);
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_typeIcon(item), color: typeColor, size: 31),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 9),
                _MetaLine(icon: _typeMetaIcon(item), label: item.typeLabel),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaLine(
                      icon: item.type == 'quiz'
                          ? Icons.groups_2_outlined
                          : Icons.visibility_rounded,
                      label: item.metricLabel,
                      iconColor: item.type == 'quiz'
                          ? AppColors.muted
                          : AppColors.primary,
                    ),
                    if (item.completionRate != null)
                      _CompletionMeta(value: item.completionRate!),
                    if (item.completionRate == null)
                      _MetaLine(
                        icon: Icons.schedule_rounded,
                        label: item.lastEditedLabel,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              _StatusBadge(status: item.status),
              const SizedBox(height: 18),
              PopupMenuButton<_ContentAction>(
                tooltip: 'More options',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.muted,
                ),
                onSelected: onAction,
                itemBuilder: (_) => _ContentAction.values
                    .map(
                      (action) => PopupMenuItem(
                        value: action,
                        child: Text(action.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.muted,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CompletionMeta extends StatelessWidget {
  const _CompletionMeta({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: value / 100,
            strokeWidth: 3,
            backgroundColor: AppColors.ink.withValues(alpha: 0.08),
            color: _completionColor(value),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value% completion',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh Content'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.item});

  final CreatorContentItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _MetaLine(icon: _typeMetaIcon(item), label: item.typeLabel),
            const SizedBox(height: 8),
            _MetaLine(icon: Icons.visibility_rounded, label: item.metricLabel),
            const SizedBox(height: 8),
            _MetaLine(
              icon: Icons.schedule_rounded,
              label: item.lastEditedLabel,
            ),
            const SizedBox(height: 14),
            _StatusBadge(status: item.status),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _SoftCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.muted, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const _SoftCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Text(
            'No content found',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final Color color;
}

enum _ContentFilter {
  all,
  published,
  draft,
  pending,
  rejected;

  String get label => switch (this) {
    _ContentFilter.all => 'All',
    _ContentFilter.published => 'Published',
    _ContentFilter.draft => 'Draft',
    _ContentFilter.pending => 'Pending',
    _ContentFilter.rejected => 'Rejected',
  };

  String? get apiValue => switch (this) {
    _ContentFilter.all => null,
    _ContentFilter.published => 'published',
    _ContentFilter.draft => 'draft',
    _ContentFilter.pending => 'pending_review',
    _ContentFilter.rejected => 'rejected',
  };
}

enum _ContentAction {
  viewDetails,
  edit,
  preview,
  submitReview,
  publish,
  unpublish,
  delete;

  String get label => switch (this) {
    _ContentAction.viewDetails => 'View Details',
    _ContentAction.edit => 'Edit',
    _ContentAction.preview => 'Preview',
    _ContentAction.submitReview => 'Submit Review',
    _ContentAction.publish => 'Publish',
    _ContentAction.unpublish => 'Unpublish',
    _ContentAction.delete => 'Delete',
  };
}

int _percent(int value, int total) {
  if (total == 0) return 0;
  return ((value / total) * 100).round();
}

IconData _typeIcon(CreatorContentItem item) => switch (item.type) {
  'course' => Icons.school_rounded,
  'lesson' => _lessonIcon(item),
  'quiz' => Icons.help_rounded,
  'event' => Icons.calendar_month_rounded,
  _ => Icons.description_rounded,
};

IconData _lessonIcon(CreatorContentItem item) {
  final lessonType = item.meta['lesson_type'] as String?;
  return switch (lessonType) {
    'video' || 'mixed' => Icons.play_circle_rounded,
    'pdf' => Icons.picture_as_pdf_rounded,
    'notes' || 'text' => Icons.sticky_note_2_rounded,
    _ => Icons.description_rounded,
  };
}

IconData _typeMetaIcon(CreatorContentItem item) => switch (item.type) {
  'course' => Icons.school_outlined,
  'lesson' => Icons.description_outlined,
  'quiz' => Icons.help_outline_rounded,
  'event' => Icons.calendar_month_outlined,
  _ => Icons.description_outlined,
};

Color _typeColor(CreatorContentItem item) => switch (item.type) {
  'course' => AppColors.secondary,
  'lesson' => const Color(0xFF7F5AF0),
  'quiz' => AppColors.accent,
  'event' => AppColors.primary,
  _ => AppColors.muted,
};

String _statusLabel(String status) => switch (status) {
  'published' => 'Published',
  'pending_review' => 'Pending Review',
  'rejected' => 'Rejected',
  'completed' => 'Completed',
  'archived' => 'Archived',
  _ => 'Draft',
};

Color _statusColor(String status) => switch (status) {
  'published' => AppColors.secondary,
  'pending_review' => AppColors.accent,
  'rejected' => AppColors.softRed,
  'completed' => AppColors.primary,
  _ => AppColors.muted,
};

Color _completionColor(int value) {
  if (value >= 70) return AppColors.secondary;
  if (value >= 60) return AppColors.accent;
  return AppColors.softRed;
}
