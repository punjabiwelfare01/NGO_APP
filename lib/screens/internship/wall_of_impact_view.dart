import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../models/impact_post.dart';
import '../../repositories/api_client.dart';
import '../../repositories/impact_repository.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const _kPurple = Color(0xFF6A1B9A);

// ── Root view ────────────────────────────────────────────────────────────────

class WallOfImpactView extends StatefulWidget {
  const WallOfImpactView({super.key});

  @override
  State<WallOfImpactView> createState() => _WallOfImpactViewState();
}

class _WallOfImpactViewState extends State<WallOfImpactView> {
  static const _categories = <({String? value, String label})>[
    (value: null, label: 'All'),
    (value: 'certificate', label: 'Certificates'),
    (value: 'donation', label: 'Donations'),
    (value: 'awareness', label: 'Awareness'),
    (value: 'distribution', label: 'Distribution'),
    (value: 'achievement', label: 'Achievements'),
  ];

  String? _category;
  List<ImpactPost> _posts = [];
  ImpactMetrics? _metrics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ImpactRepository.getPublished(category: _category),
        ImpactRepository.getMetrics(),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = results[0] as List<ImpactPost>;
        _metrics = results[1] as ImpactMetrics;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: canPop
          ? AppBar(
              title: const Text(
                'Wall of Impact',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.ink,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            )
          : null,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.softRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.softRed),
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load posts',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assests/ngo_logo.jpeg',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _kPurple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.volunteer_activism_rounded,
                                color: _kPurple, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wall of Impact',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.verified_rounded,
                                    size: 13, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified by Punjabi Welfare Trust',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Platform metrics ─────────────────────────────────────────────
          if (_metrics != null)
            SliverToBoxAdapter(
              child: _MetricsBar(metrics: _metrics!),
            ),

          // ── Category filter chips ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = _category == cat.value;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ChoiceChip(
                        label: Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? _kPurple : AppColors.muted,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _category = cat.value);
                          _load();
                        },
                        selectedColor: _kPurple.withValues(alpha: 0.12),
                        backgroundColor: const Color(0xFFF0F0F0),
                        side: BorderSide(
                          color: selected
                              ? _kPurple.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Post list ────────────────────────────────────────────────────
          if (_posts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _kPurple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.auto_awesome_outlined,
                            color: _kPurple, size: 34),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No impact posts yet',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Published stories will appear here.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PostCard(
                      post: _posts[i],
                      onAppreciate: () => _appreciate(_posts[i]),
                      onShare: () => _share(_posts[i]),
                    ),
                  ),
                  childCount: _posts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _appreciate(ImpactPost post) async {
    try {
      final updated = await ImpactRepository.appreciate(post.id);
      if (!mounted) return;
      setState(() {
        _posts = _posts
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save appreciation')),
        );
      }
    }
  }

  Future<void> _share(ImpactPost post) async {
    try {
      final url = await ImpactRepository.share(post.id);
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Share link copied to clipboard'),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create share link')),
        );
      }
    }
  }
}

// ── Platform metrics bar ─────────────────────────────────────────────────────

class _MetricsBar extends StatelessWidget {
  const _MetricsBar({required this.metrics});
  final ImpactMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _MetricTile(
            icon: Icons.people_rounded,
            value: _compact(metrics.peopleReached),
            label: 'Reached',
            color: _kPurple,
          ),
          const SizedBox(width: 10),
          _MetricTile(
            icon: Icons.schedule_rounded,
            value: _compact(metrics.hoursServed.round()),
            label: 'Hours',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _MetricTile(
            icon: Icons.currency_rupee_rounded,
            value: _compact(metrics.donationCollected.round()),
            label: 'Donated',
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 10),
          _MetricTile(
            icon: Icons.auto_stories_rounded,
            value: '${metrics.posts}',
            label: 'Stories',
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.onAppreciate,
    required this.onShare,
  });
  final ImpactPost post;
  final VoidCallback onAppreciate;
  final VoidCallback onShare;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  List<ImpactMedia> get _images =>
      widget.post.media.where((m) => m.type == 'image').toList();

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Color get _categoryColor {
    final cat = widget.post.category.toLowerCase();
    if (cat.contains('certificate')) return const Color(0xFF1565C0);
    if (cat.contains('donation')) return const Color(0xFF2E7D32);
    if (cat.contains('awareness')) return const Color(0xFFE65100);
    if (cat.contains('distribution')) return const Color(0xFF4527A0);
    if (cat.contains('achievement')) return const Color(0xFF00695C);
    if (cat.contains('volunteer')) return const Color(0xFFC62828);
    if (cat.contains('school')) return const Color(0xFF00695C);
    return _kPurple;
  }

  String get _categoryLabel => widget.post.category
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String get _dateLabel {
    final dt = widget.post.publishedAt;
    if (dt == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final images = _images;
    final color = _categoryColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header: NGO identity + category ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assests/ngo_logo.jpeg',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded,
                          color: _kPurple, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Punjabi Welfare Trust',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 12, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 3),
                          Text(
                            _dateLabel.isEmpty ? 'Admin verified' : _dateLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _categoryLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Title ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              post.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                height: 1.25,
              ),
            ),
          ),

          // ── Cover image carousel (16:9, full-width) ──────────────────────
          if (images.isNotEmpty) _ImageCarousel(
            images: images,
            controller: _pageCtrl,
            currentPage: _currentPage,
            onPageChanged: (p) => setState(() => _currentPage = p),
          ),

          // ── Description / Impact story ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              post.description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.55,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── People / team ─────────────────────────────────────────────────
          if (post.studentNames != null || post.teamName != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.group_rounded, size: 14, color: AppColors.muted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      post.studentNames ?? post.teamName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Impact metrics ────────────────────────────────────────────────
          if (post.peopleReached > 0 ||
              post.hoursServed > 0 ||
              post.donationCollected > 0 ||
              post.location != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (post.peopleReached > 0)
                    _MetricChip(
                      icon: Icons.people_rounded,
                      label: '${_fmtNum(post.peopleReached)} beneficiaries',
                      color: _kPurple,
                    ),
                  if (post.hoursServed > 0)
                    _MetricChip(
                      icon: Icons.schedule_rounded,
                      label: '${post.hoursServed.toStringAsFixed(0)} hours',
                      color: AppColors.primary,
                    ),
                  if (post.donationCollected > 0)
                    _MetricChip(
                      icon: Icons.currency_rupee_rounded,
                      label: '₹${_fmtNum(post.donationCollected.round())} raised',
                      color: const Color(0xFF2E7D32),
                    ),
                  if (post.location != null)
                    _MetricChip(
                      icon: Icons.location_on_rounded,
                      label: post.location!,
                      color: AppColors.muted,
                    ),
                ],
              ),
            ),
          ],

          // ── Appreciation message ──────────────────────────────────────────
          if (post.partnerName != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        size: 18, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.partnerName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Action row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Appreciate
                _ActionButton(
                  icon: post.appreciatedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: post.appreciationCount > 0
                      ? '${post.appreciationCount}'
                      : 'Appreciate',
                  color: post.appreciatedByMe
                      ? const Color(0xFFC62828)
                      : AppColors.muted,
                  onTap: widget.onAppreciate,
                ),
                const Spacer(),
                // Share
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: post.shareCount > 0
                      ? '${post.shareCount} Shares'
                      : 'Share',
                  color: AppColors.muted,
                  onTap: widget.onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ── Image carousel with 16:9 ratio & pagination ──────────────────────────────

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({
    required this.images,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });
  final List<ImpactMedia> images;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final count = images.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 16:9 image viewer
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: controller,
                itemCount: count,
                onPageChanged: onPageChanged,
                itemBuilder: (_, i) => Image.network(
                  ApiClient.resolveUrl(images[i].url),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFF0F0F0),
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          size: 48, color: AppColors.muted),
                    ),
                  ),
                ),
              ),
              // "+N more" overlay on last image when there are many
              if (count > 1)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${currentPage + 1} / $count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Pagination dots
        if (count > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count > 5 ? 5 : count, (i) {
              final isOverflow = count > 5 && i == 4;
              final isActive = isOverflow ? currentPage >= 4 : i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? _kPurple
                      : AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: isOverflow && !isActive
                    ? null
                    : null,
              );
            }),
          ),
          if (count > 5)
            Text(
              '+${count - 4} more',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// ── Metric chip ──────────────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
