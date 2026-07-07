import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../models/impact_post.dart';
import '../repositories/api_client.dart';
import '../repositories/impact_repository.dart';
import '../screens/internship/wall_of_impact_view.dart';
import 'section_header.dart';

/// "Our Achievements" preview — shows the NGO's official recognition
/// certificates (ImpactPost category "certificate") with a "View All" link
/// into the Wall of Impact filtered to that category. Meant to be dropped
/// into every role's home screen to build trust/credibility, especially for
/// school partners deciding whether to work with the NGO.
///
/// Renders nothing while loading and nothing if there are no certificate
/// posts yet, so it never shows an empty placeholder on a home screen.
class AchievementCertificatesSection extends StatefulWidget {
  const AchievementCertificatesSection({super.key});

  @override
  State<AchievementCertificatesSection> createState() =>
      _AchievementCertificatesSectionState();
}

class _AchievementCertificatesSectionState
    extends State<AchievementCertificatesSection> {
  List<ImpactPost> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await ImpactRepository.getPublished(category: 'certificate');
      if (mounted) setState(() { _posts = posts; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _viewAll() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WallOfImpactView(initialCategory: 'certificate'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _posts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Our Achievements',
            action: 'View All',
            onTap: _viewAll,
          ),
          const SizedBox(height: 4),
          const Text(
            'Recognised by institutions and partners for our community work.',
            style: TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: _posts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) =>
                  _CertificateCard(post: _posts[i], onTap: _viewAll),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.post, required this.onTap});
  final ImpactPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverUrl = post.media.isNotEmpty ? post.media.first.url : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 144,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: 144,
                height: 96,
                child: coverUrl != null
                    ? Image.network(
                        ApiClient.resolveUrl(coverUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.primary.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: const Icon(
          Icons.workspace_premium_rounded,
          color: AppColors.primary,
          size: 30,
        ),
      );
}
