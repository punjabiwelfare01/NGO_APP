import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../models/impact_post.dart';
import '../../repositories/api_client.dart';
import '../../repositories/impact_repository.dart';
import '../../widgets/app_card.dart';

class WallOfImpactView extends StatefulWidget {
  const WallOfImpactView({super.key});

  @override
  State<WallOfImpactView> createState() => _WallOfImpactViewState();
}

class _WallOfImpactViewState extends State<WallOfImpactView> {
  static const _categories = <String?>[
    null,
    'certificate',
    'donation',
    'awareness',
    'distribution',
    'achievement',
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
      backgroundColor: AppColors.background,
      appBar: canPop
          ? AppBar(
              title: const Text('Wall of Impact'),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.ink,
              elevation: 0,
            )
          : null,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: AppColors.muted,
            ),
            const SizedBox(height: 10),
            const Text(
              'Could not load the Wall of Impact',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          const Text(
            'Wall of Impact',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verified stories published by Punjabi Welfare Trust',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          if (_metrics != null) _Metrics(metrics: _metrics!),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final value = _categories[index];
                return ChoiceChip(
                  label: Text(value == null ? 'All' : _label(value)),
                  selected: _category == value,
                  onSelected: (_) {
                    setState(() => _category = value);
                    _load();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_posts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: Center(
                child: Text(
                  'No published impact posts in this category.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ..._posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PostCard(
                  post: post,
                  onAppreciate: () => _appreciate(post),
                  onShare: () => _share(post),
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
      setState(
        () => _posts = _posts
            .map((item) => item.id == updated.id ? updated : item)
            .toList(),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save appreciation: $error')),
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
          const SnackBar(content: Text('Verified post link copied.')),
        );
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create share link: $error')),
        );
      }
    }
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.metrics});
  final ImpactMetrics metrics;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _metric('People', '${metrics.peopleReached}'),
      const SizedBox(width: 7),
      _metric('Hours', metrics.hoursServed.toStringAsFixed(0)),
      const SizedBox(width: 7),
      _metric('Donations', '₹${metrics.donationCollected.toStringAsFixed(0)}'),
    ],
  );
  Widget _metric(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onAppreciate,
    required this.onShare,
  });
  final ImpactPost post;
  final VoidCallback onAppreciate;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assests/ngo_logo.jpeg',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Punjabi Welfare Trust',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Admin approved',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(_label(post.category)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (post.media.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              ApiClient.resolveUrl(post.media.first.url),
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          post.title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          post.description,
          style: const TextStyle(color: AppColors.muted, height: 1.45),
        ),
        if (post.studentNames != null || post.teamName != null) ...[
          const SizedBox(height: 8),
          Text(
            post.studentNames ?? post.teamName!,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            if (post.peopleReached > 0)
              _pill(Icons.people_rounded, '${post.peopleReached} reached'),
            if (post.hoursServed > 0)
              _pill(
                Icons.schedule_rounded,
                '${post.hoursServed.toStringAsFixed(0)} hours',
              ),
            if (post.donationCollected > 0)
              _pill(
                Icons.currency_rupee_rounded,
                post.donationCollected.toStringAsFixed(0),
              ),
            if (post.location != null)
              _pill(Icons.location_on_outlined, post.location!),
          ],
        ),
        const Divider(height: 24),
        Row(
          children: [
            TextButton.icon(
              onPressed: onAppreciate,
              icon: Icon(
                post.appreciatedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              label: Text('${post.appreciationCount} Appreciate'),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded),
              label: Text('${post.shareCount} Share'),
            ),
          ],
        ),
      ],
    ),
  );

  static Widget _pill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

String _label(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
