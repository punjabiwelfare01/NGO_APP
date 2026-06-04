import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/creator_content.dart';
import '../../repositories/creator_repository.dart';

class ContentAnalyticsView extends StatefulWidget {
  const ContentAnalyticsView({super.key});

  @override
  State<ContentAnalyticsView> createState() => _ContentAnalyticsViewState();
}

class _ContentAnalyticsViewState extends State<ContentAnalyticsView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  List<_ContentPerformance> _items = [];
  bool _loading = true;

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
    try {
      final items = await CreatorRepository.getContent();
      if (!mounted) return;
      setState(() {
        _items = items.map(_ContentPerformance.fromCreator).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where(_matchesQuery).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        const _AnalyticsHeader(),
        const SizedBox(height: 18),
        const _StatCardGrid(),
        const SizedBox(height: 16),
        const _ViewsTrendCard(),
        const SizedBox(height: 16),
        const _ContentBreakdownCard(),
        const SizedBox(height: 20),
        _PerformanceSearch(
          controller: _searchCtrl,
          onChanged: (value) => setState(() => _query = value.trim()),
          onClear: _query.isEmpty
              ? null
              : () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
        ),
        const SizedBox(height: 12),
        if (_loading)
          const _SoftCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else
          _ContentPerformanceList(items: filteredItems),
        const SizedBox(height: 16),
        const _TopContentCard(),
      ],
    );
  }

  bool _matchesQuery(_ContentPerformance item) {
    if (_query.isEmpty) return true;
    final text = '${item.title} ${item.type.label} ${item.status.label}'
        .toLowerCase();
    return text.contains(_query.toLowerCase());
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Track learning content performance',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              onPressed: () {},
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.softRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _StatCardGrid extends StatelessWidget {
  const _StatCardGrid();

  @override
  Widget build(BuildContext context) {
    final stats = [
      const _StatData(
        icon: Icons.description_rounded,
        label: 'Total Content',
        value: '24',
        helper: 'Videos, PDFs, quizzes, notes',
        color: AppColors.primary,
      ),
      const _StatData(
        icon: Icons.task_alt_rounded,
        label: 'Published',
        value: '16',
        helper: '67% of total',
        color: AppColors.secondary,
      ),
      const _StatData(
        icon: Icons.visibility_rounded,
        label: 'Total Views',
        value: '12.4K',
        helper: 'All time',
        color: Color(0xFF2E7CF6),
      ),
      const _StatData(
        icon: Icons.donut_large_rounded,
        label: 'Completion',
        value: '68%',
        helper: 'Average across content',
        color: Color(0xFF7F5AF0),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 650 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 4 ? 1.18 : 1.08,
          ),
          itemBuilder: (context, index) => _StatCard(data: stats[index]),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const Spacer(),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: TextStyle(
                color: data.color,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.helper,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewsTrendCard extends StatelessWidget {
  const _ViewsTrendCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Views Trend',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '7 Days',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.ink,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SizedBox(
            height: 170,
            child: _TrendLineChart(
              points: [180, 420, 760, 1050, 920, 1420, 1560],
              labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  const _TrendLineChart({required this.points, required this.labels});

  final List<double> points;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(points: points, labels: labels),
      child: const SizedBox.expand(),
    );
  }
}

class _ContentBreakdownCard extends StatelessWidget {
  const _ContentBreakdownCard();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _BreakdownData('Video', '6.2K', 50, AppColors.primary),
      _BreakdownData('PDF', '2.8K', 23, AppColors.secondary),
      _BreakdownData('Quiz', '1.9K', 15, AppColors.accent),
      _BreakdownData('Notes', '1.5K', 12, Color(0xFF7F5AF0)),
    ];

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Breakdown',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              final chart = SizedBox(
                width: compact ? 150 : 138,
                height: compact ? 150 : 138,
                child: CustomPaint(
                  painter: _DonutPainter(items: items),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '12.4K',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Views',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              final legend = Column(
                children: items
                    .map((item) => _BreakdownRow(item: item))
                    .toList(),
              );

              if (compact) {
                return Column(
                  children: [
                    Center(child: chart),
                    const SizedBox(height: 16),
                    legend,
                  ],
                );
              }

              return Row(
                children: [
                  chart,
                  const SizedBox(width: 18),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item});

  final _BreakdownData item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${item.views} (${item.percent}%)',
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceSearch extends StatelessWidget {
  const _PerformanceSearch({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Content Performance',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Search content...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: onClear == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: () {},
              tooltip: 'Filter',
              icon: const Icon(Icons.filter_alt_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContentPerformanceList extends StatelessWidget {
  const _ContentPerformanceList({required this.items});

  final List<_ContentPerformance> items;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'No content found',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _PerformanceRow(item: items[index]),
                  if (index != items.length - 1)
                    Divider(
                      height: 1,
                      color: AppColors.ink.withValues(alpha: 0.08),
                    ),
                ],
              ],
            ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.item});

  final _ContentPerformance item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.type.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.type.icon, color: item.type.color, size: 23),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SmallBadge(
                      label: item.type.label,
                      color: item.type.color,
                      light: item.type.color.withValues(alpha: 0.10),
                    ),
                    _SmallBadge(
                      label: item.status.label,
                      color: item.status.color,
                      light: item.status.color.withValues(alpha: 0.10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _shortNumber(item.views),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${item.completion}%',
                style: TextStyle(
                  color: _completionColor(item.completion),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopContentCard extends StatelessWidget {
  const _TopContentCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.accent,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Performing',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Communication Skills Basics',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 9),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _InlineMetric(
                      icon: Icons.visibility_rounded,
                      label: '2.4K',
                    ),
                    _InlineMetric(icon: Icons.task_alt_rounded, label: '78%'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: () {},
            tooltip: 'View details',
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    required this.color,
    required this.light,
  });

  final String label;
  final Color color;
  final Color light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: light,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
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

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.points, required this.labels});

  final List<double> points;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const left = 34.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 24.0;
    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );
    final maxValue = (points.reduce(math.max) / 500).ceil() * 500.0;
    final minValue = 0.0;
    final gridPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: AppColors.muted.withValues(alpha: 0.9),
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    for (var i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final value = (maxValue - ((maxValue - minValue) * i / 4)).round();
      _drawText(
        canvas,
        _axisLabel(value),
        Offset(0, y - 7),
        labelStyle,
        width: left - 6,
        align: TextAlign.right,
      );
    }

    final spots = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = chart.left + chart.width * i / (points.length - 1);
      final normalized = (points[i] - minValue) / (maxValue - minValue);
      final y = chart.bottom - chart.height * normalized;
      spots.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(spots.first.dx, chart.bottom);
    for (final spot in spots) {
      fillPath.lineTo(spot.dx, spot.dy);
    }
    fillPath.lineTo(spots.last.dx, chart.bottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.20),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(chart);
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(spots.first.dx, spots.first.dy);
    for (var i = 1; i < spots.length; i++) {
      final previous = spots[i - 1];
      final current = spots[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    final dotBorderPaint = Paint()..color = Colors.white;
    for (final spot in spots) {
      canvas.drawCircle(spot, 5, dotBorderPaint);
      canvas.drawCircle(spot, 3.5, dotPaint);
    }

    for (var i = 0; i < labels.length; i++) {
      final x = chart.left + chart.width * i / (labels.length - 1);
      _drawText(
        canvas,
        labels[i],
        Offset(x - 18, chart.bottom + 7),
        labelStyle,
        width: 36,
        align: TextAlign.center,
      );
    }
  }

  String _axisLabel(int value) {
    if (value == 0) return '0';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double width,
    required TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.labels != labels;
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.items});

  final List<_BreakdownData> items;

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold<double>(0, (sum, item) => sum + item.percent);
    final rect = Offset.zero & size;
    final strokeWidth = size.shortestSide * 0.24;
    var start = -math.pi / 2;
    for (final item in items) {
      final sweep = (item.percent / total) * math.pi * 2;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start,
        sweep - 0.025,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}

class _StatData {
  const _StatData({
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

class _BreakdownData {
  const _BreakdownData(this.label, this.views, this.percent, this.color);

  final String label;
  final String views;
  final int percent;
  final Color color;
}

class _ContentPerformance {
  const _ContentPerformance({
    required this.title,
    required this.type,
    required this.status,
    required this.views,
    required this.completion,
    required this.trend,
  });

  final String title;
  final _ContentType type;
  final _ContentStatus status;
  final int views;
  final int completion;
  final int trend;

  factory _ContentPerformance.fromCreator(CreatorContentItem item) {
    return _ContentPerformance(
      title: item.title,
      type: _ContentType.fromCreator(item),
      status: _ContentStatus.fromCreator(item.status),
      views: item.views,
      completion: item.completionRate ?? 0,
      trend: 0,
    );
  }
}

enum _ContentType {
  course,
  video,
  pdf,
  quiz,
  notes,
  event;

  static _ContentType fromCreator(CreatorContentItem item) {
    if (item.type == 'course') return _ContentType.course;
    if (item.type == 'quiz') return _ContentType.quiz;
    if (item.type == 'event') return _ContentType.event;
    final lessonType = item.meta['lesson_type'] as String?;
    return switch (lessonType) {
      'video' || 'mixed' => _ContentType.video,
      'pdf' => _ContentType.pdf,
      'notes' || 'text' => _ContentType.notes,
      _ => _ContentType.notes,
    };
  }

  String get label => switch (this) {
    _ContentType.course => 'Course',
    _ContentType.video => 'Video',
    _ContentType.pdf => 'PDF',
    _ContentType.quiz => 'Quiz',
    _ContentType.notes => 'Notes',
    _ContentType.event => 'Event',
  };

  IconData get icon => switch (this) {
    _ContentType.course => Icons.school_rounded,
    _ContentType.video => Icons.play_circle_rounded,
    _ContentType.pdf => Icons.picture_as_pdf_rounded,
    _ContentType.quiz => Icons.quiz_rounded,
    _ContentType.notes => Icons.sticky_note_2_rounded,
    _ContentType.event => Icons.calendar_month_rounded,
  };

  Color get color => switch (this) {
    _ContentType.course => AppColors.secondary,
    _ContentType.video => AppColors.primary,
    _ContentType.pdf => AppColors.softRed,
    _ContentType.quiz => AppColors.secondary,
    _ContentType.notes => AppColors.accent,
    _ContentType.event => const Color(0xFF7F5AF0),
  };
}

enum _ContentStatus {
  published,
  review,
  draft,
  rejected;

  static _ContentStatus fromCreator(String status) => switch (status) {
    'published' || 'completed' => _ContentStatus.published,
    'pending_review' => _ContentStatus.review,
    'rejected' => _ContentStatus.rejected,
    _ => _ContentStatus.draft,
  };

  String get label => switch (this) {
    _ContentStatus.published => 'Published',
    _ContentStatus.review => 'Review',
    _ContentStatus.draft => 'Draft',
    _ContentStatus.rejected => 'Rejected',
  };

  Color get color => switch (this) {
    _ContentStatus.published => AppColors.secondary,
    _ContentStatus.review => AppColors.accent,
    _ContentStatus.draft => AppColors.muted,
    _ContentStatus.rejected => AppColors.softRed,
  };
}

String _shortNumber(int value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

Color _completionColor(int value) {
  if (value >= 70) return AppColors.secondary;
  if (value >= 60) return AppColors.accent;
  return AppColors.softRed;
}
