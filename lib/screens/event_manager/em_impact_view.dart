import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../repositories/api_client.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import '../../widgets/app_card.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kMaxImages = 10;
const _kMaxVideos = 2;
const _kMaxImageBytes = 5 * 1024 * 1024;   // 5 MB
const _kMaxVideoBytes = 50 * 1024 * 1024;  // 50 MB
const _kMaxDocBytes = 10 * 1024 * 1024;    // 10 MB
const _kPurple = Color(0xFF6A1B9A);

// ─── Media enums & model ──────────────────────────────────────────────────────

enum _MediaType { image, video, document }

enum _UploadStatus { pending, uploading, success, failed }

class _ImpactMedia {
  _ImpactMedia({
    required this.localId,
    required this.filePath,
    this.bytes,
    required this.fileName,
    required this.mediaType,
    required this.fileSize,
    this.isCover = false,
    required this.displayOrder,
  });

  final String localId;
  final String filePath;    // local path (non-web)
  final Uint8List? bytes;   // in-memory bytes (web)
  final String fileName;
  final _MediaType mediaType;
  final int fileSize;
  _UploadStatus status = _UploadStatus.pending;
  double progress = 0.0;
  String? caption;
  String? remoteUrl;
  bool isCover;
  int displayOrder;
  String? errorMessage;

  bool get isImage => mediaType == _MediaType.image;
  bool get isVideo => mediaType == _MediaType.video;
  bool get isDocument => mediaType == _MediaType.document;

  String get sizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─── Root view ────────────────────────────────────────────────────────────────

class EMImpactView extends StatefulWidget {
  const EMImpactView({required this.vm, super.key});
  final EventManagerViewModel vm;

  @override
  State<EMImpactView> createState() => _EMImpactViewState();
}

class _EMImpactViewState extends State<EMImpactView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final drafts = widget.vm.draftPosts;
        final published = widget.vm.publishedPosts;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _Header(vm: widget.vm),
              TabBar(
                controller: _tabs,
                labelColor: _kPurple,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: _kPurple,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Drafts'),
                        if (drafts.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CountBadge(count: drafts.length, color: _kPurple),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Published'),
                        if (published.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CountBadge(
                            count: published.length,
                            color: const Color(0xFF2E7D32),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _DraftsTab(posts: drafts, vm: widget.vm),
                    _PublishedTab(posts: published),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreatePost(context),
            backgroundColor: _kPurple,
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: const Text(
              'Create Impact Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCreatePost(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateImpactPostSheet(vm: widget.vm),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.vm});
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wall of Impact',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vm.draftPosts.length} drafts · ${vm.publishedPosts.length} published',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kPurple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: _kPurple, size: 14),
                SizedBox(width: 5),
                Text(
                  'NGO Verified',
                  style: TextStyle(
                    color: _kPurple,
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

// ─── Drafts Tab ───────────────────────────────────────────────────────────────

class _DraftsTab extends StatelessWidget {
  const _DraftsTab({required this.posts, required this.vm});
  final List<EMImpactPost> posts;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyTab(
        icon: Icons.auto_awesome_outlined,
        message: 'No draft posts yet',
        sub:
            'Approve student submissions to auto-create impact posts,\nor tap + Create Impact Post',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _DraftPostCard(post: posts[i], vm: vm),
    );
  }
}

class _DraftPostCard extends StatelessWidget {
  const _DraftPostCard({required this.post, required this.vm});
  final EMImpactPost post;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: post.type.color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                  color: post.type.color.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: post.type.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(post.type.icon, color: post.type.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.type.label,
                        style: TextStyle(
                          color: post.type.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        post.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _DraftChip(isSubmitted: post.isPublished),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _MetaItem(
                      icon: Icons.location_on_rounded,
                      label: post.location,
                    ),
                    _MetaItem(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${post.date.day}/${post.date.month}/${post.date.year}',
                    ),
                    if (post.studentName != null)
                      _MetaItem(
                        icon: Icons.person_rounded,
                        label: post.studentName!,
                      ),
                    if (post.photoUrls.isNotEmpty)
                      _MetaItem(
                        icon: Icons.photo_library_rounded,
                        label: '${post.photoUrls.length} media',
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (post.studentsHelped != null ||
                    post.hoursServed != null ||
                    post.donationRaised != null)
                  _ImpactNumbers(post: post),
                const SizedBox(height: 10),
                Text(
                  post.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: post.type.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: post.type.color.withValues(alpha: 0.5),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.appreciationMessage,
                          style: TextStyle(
                            color: post.type.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: _kPurple,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Verified by ${post.verifiedByName}',
                      style: const TextStyle(
                        color: _kPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (AppState.role.isAdmin && !post.adminApproved)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await vm.approveAndPublishImpactPost(post.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Impact post approved and published.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.verified_rounded),
                      label: const Text('Approve & Publish'),
                    ),
                  )
                else if (!post.isPublished)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        vm.submitImpactPostForApproval(post.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sent to Admin for approval. It will be published once approved.',
                            ),
                            backgroundColor: _kPurple,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text(
                        'Submit for Admin Approval',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPurple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.pending_rounded,
                          color: Color(0xFF1565C0),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sent for Admin Approval — awaiting review',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

// ─── Published Tab ────────────────────────────────────────────────────────────

class _PublishedTab extends StatelessWidget {
  const _PublishedTab({required this.posts});
  final List<EMImpactPost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyTab(
        icon: Icons.public_off_rounded,
        message: 'No published posts yet',
        sub: 'Posts approved by Admin will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _PublishedPostCard(post: posts[i]),
    );
  }
}

class _PublishedPostCard extends StatelessWidget {
  const _PublishedPostCard({required this.post});
  final EMImpactPost post;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  post.type.color,
                  post.type.color.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(post.type.icon, color: Colors.white, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            post.type.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Colors.white, size: 10),
                          SizedBox(width: 4),
                          Text(
                            'PUBLISHED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.location} · ${post.date.day}/${post.date.month}/${post.date.year}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.photoUrls.isNotEmpty) ...[
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.photoUrls.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          post.photoUrls[i],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 80,
                            height: 80,
                            color: _kPurple.withValues(alpha: 0.08),
                            child: const Icon(Icons.image_rounded,
                                color: _kPurple),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (post.studentsHelped != null ||
                    post.hoursServed != null ||
                    post.donationRaised != null)
                  _ImpactNumbers(post: post),
                const SizedBox(height: 10),
                Text(
                  post.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  post.appreciationMessage,
                  style: TextStyle(
                    color: post.type.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sharing impact post...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 14),
                        label: const Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Viewing full impact post...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon:
                            const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text(
                          'View Post',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: post.type.color,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Impact Numbers ───────────────────────────────────────────────────────────

class _ImpactNumbers extends StatelessWidget {
  const _ImpactNumbers({required this.post});
  final EMImpactPost post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (post.studentsHelped != null)
          Expanded(
            child: _ImpactNum(
              icon: Icons.people_rounded,
              value: '${post.studentsHelped}',
              label: 'Reached',
              color: const Color(0xFF1565C0),
            ),
          ),
        if (post.hoursServed != null) ...[
          if (post.studentsHelped != null) const SizedBox(width: 8),
          Expanded(
            child: _ImpactNum(
              icon: Icons.access_time_rounded,
              value: '${post.hoursServed!.toStringAsFixed(0)}h',
              label: 'Hours',
              color: const Color(0xFFE65100),
            ),
          ),
        ],
        if (post.donationRaised != null && post.donationRaised! > 0) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ImpactNum(
              icon: Icons.payments_rounded,
              value: post.donationRaised! >= 1000
                  ? '₹${(post.donationRaised! / 1000).toStringAsFixed(1)}K'
                  : '₹${post.donationRaised!.toStringAsFixed(0)}',
              label: 'Raised',
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ],
    );
  }
}

class _ImpactNum extends StatelessWidget {
  const _ImpactNum({
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _DraftChip extends StatelessWidget {
  const _DraftChip({required this.isSubmitted});
  final bool isSubmitted;

  @override
  Widget build(BuildContext context) {
    final color =
        isSubmitted ? const Color(0xFF1565C0) : const Color(0xFF757575);
    final label = isSubmitted ? 'Pending Approval' : 'Draft';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.muted, size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.color});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.message,
    required this.sub,
  });
  final IconData icon;
  final String message;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.muted.withValues(alpha: 0.35), size: 52),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              sub,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Create Impact Post Sheet ─────────────────────────────────────────────────

class _CreateImpactPostSheet extends StatefulWidget {
  const _CreateImpactPostSheet({required this.vm});
  final EventManagerViewModel vm;

  @override
  State<_CreateImpactPostSheet> createState() => _CreateImpactPostSheetState();
}

class _CreateImpactPostSheetState extends State<_CreateImpactPostSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _appreciationCtrl = TextEditingController();

  EMImpactPostType _type = EMImpactPostType.eventSuccessReport;
  NGOEvent? _selectedEvent;

  final List<_ImpactMedia> _mediaItems = [];
  bool _isUploading = false;
  bool _draftCreated = false;
  int? _draftPostId;

  int get _imageCount => _mediaItems.where((m) => m.isImage).length;
  int get _videoCount => _mediaItems.where((m) => m.isVideo).length;

  bool get _hasPendingUploads => _mediaItems.any(
        (m) =>
            m.status == _UploadStatus.pending ||
            m.status == _UploadStatus.failed,
      );

  bool get _allUploaded =>
      _mediaItems.isNotEmpty &&
      _mediaItems.every((m) => m.status == _UploadStatus.success);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _appreciationCtrl.dispose();
    super.dispose();
  }

  // ── File picking ──────────────────────────────────────────────────────────

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg', 'jpeg', 'png', 'webp',
        'mp4', 'mov', 'webm',
        'pdf',
      ],
      withData: kIsWeb,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final errors = <String>[];

    for (final file in result.files) {
      final ext = (file.extension ?? '').toLowerCase();
      final isImg = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
      final isVid = ['mp4', 'mov', 'webm'].contains(ext);
      final isDoc = ext == 'pdf';

      if (!isImg && !isVid && !isDoc) {
        errors.add('${file.name}: unsupported file type');
        continue;
      }

      if (isImg && _imageCount >= _kMaxImages) {
        errors.add('Max $_kMaxImages images — ${file.name} skipped');
        continue;
      }
      if (isVid && _videoCount >= _kMaxVideos) {
        errors.add('Max $_kMaxVideos videos — ${file.name} skipped');
        continue;
      }

      final maxBytes = isVid
          ? _kMaxVideoBytes
          : isDoc
              ? _kMaxDocBytes
              : _kMaxImageBytes;
      if (file.size > maxBytes) {
        final mb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
        errors.add('${file.name}: exceeds $mb MB limit');
        continue;
      }

      final type = isImg
          ? _MediaType.image
          : isVid
              ? _MediaType.video
              : _MediaType.document;

      final isFirstMedia = _mediaItems.isEmpty && isImg;

      setState(() {
        _mediaItems.add(
          _ImpactMedia(
            localId:
                '${DateTime.now().microsecondsSinceEpoch}_${_mediaItems.length}',
            filePath: file.path ?? '',
            bytes: file.bytes,
            fileName: file.name,
            mediaType: type,
            fileSize: file.size,
            isCover: isFirstMedia,
            displayOrder: _mediaItems.length,
          ),
        );
      });
    }

    if (errors.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errors.join('\n'),
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<void> _uploadSingleItem(_ImpactMedia item, int postId) async {
    if (item.status == _UploadStatus.success) return;

    setState(() {
      item.status = _UploadStatus.uploading;
      item.progress = 0.0;
      item.errorMessage = null;
    });

    try {
      dynamic result;

      if (kIsWeb && item.bytes != null) {
        result = await ApiClient.postMultipart(
          '/impact/posts/$postId/media',
          fields: {
            'caption': item.caption ?? '',
            'is_cover': item.isCover.toString(),
            'display_order': item.displayOrder.toString(),
            'media_type': item.mediaType.name,
            if (_selectedEvent != null)
              'event_id': _selectedEvent!.id.toString(),
          },
          fileBytes: item.bytes!,
          fileName: item.fileName,
        );
        if (mounted) setState(() => item.progress = 1.0);
      } else if (item.filePath.isNotEmpty) {
        result = await ApiClient.uploadFileWithProgress(
          '/impact/posts/$postId/media',
          filePath: item.filePath,
          fileName: item.fileName,
          fields: {
            'caption': item.caption ?? '',
            'is_cover': item.isCover.toString(),
            'display_order': item.displayOrder.toString(),
            'media_type': item.mediaType.name,
            if (_selectedEvent != null)
              'event_id': _selectedEvent!.id.toString(),
          },
          onProgress: (sent, total) {
            if (!mounted) return;
            setState(() {
              item.progress = total > 0 ? sent / total : 0.5;
            });
          },
        );
      } else {
        throw Exception('No file data available for upload');
      }

      if (!mounted) return;
      setState(() {
        item.remoteUrl =
            result is Map ? result['media_url'] as String? : null;
        item.status = _UploadStatus.success;
        item.progress = 1.0;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        item.status = _UploadStatus.failed;
        item.errorMessage =
            (msg.contains('404') || msg.contains('SocketException'))
                ? 'Media endpoint unavailable — tap Retry when connected'
                : 'Upload failed — tap Retry';
      });
    }
  }

  Future<void> _uploadAllPending(int postId) async {
    final pending = _mediaItems
        .where(
          (m) =>
              m.status == _UploadStatus.pending ||
              m.status == _UploadStatus.failed,
        )
        .toList();
    if (pending.isEmpty) return;

    setState(() => _isUploading = true);
    for (final item in pending) {
      await _uploadSingleItem(item, postId);
      if (!mounted) return;
    }
    setState(() => _isUploading = false);
  }

  Future<void> _onUploadMediaPressed() async {
    if (_isUploading) return;
    final postId = _ensureDraft();
    await _uploadAllPending(postId);
  }

  // ── Draft management ──────────────────────────────────────────────────────

  int _ensureDraft() {
    if (_draftCreated && _draftPostId != null) return _draftPostId!;

    _draftPostId = DateTime.now().millisecondsSinceEpoch;
    _draftCreated = true;

    widget.vm.addImpactPost(
      EMImpactPost(
        id: _draftPostId!,
        type: _type,
        title: _titleCtrl.text.trim().isEmpty
            ? 'Untitled Draft'
            : _titleCtrl.text.trim(),
        eventName: _selectedEvent?.title ?? 'NGO Event',
        location: _selectedEvent?.location ?? '',
        date: DateTime.now(),
        description: _descCtrl.text.trim(),
        appreciationMessage: _appreciationCtrl.text.trim(),
        isPublished: false,
        adminApproved: false,
        verifiedByName: AppState.studentName ?? 'Event Manager',
      ),
    );
    return _draftPostId!;
  }

  // ── Media list operations ─────────────────────────────────────────────────

  void _removeMedia(String localId) {
    setState(() {
      _mediaItems.removeWhere((m) => m.localId == localId);
      final hasNoCover = !_mediaItems.any((m) => m.isCover);
      if (hasNoCover) {
        final firstImg = _mediaItems.where((m) => m.isImage).firstOrNull;
        if (firstImg != null) firstImg.isCover = true;
      }
      for (var i = 0; i < _mediaItems.length; i++) {
        _mediaItems[i].displayOrder = i;
      }
    });
  }

  void _setCover(String localId) {
    setState(() {
      for (final m in _mediaItems) {
        m.isCover = m.localId == localId;
      }
    });
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final tmp = _mediaItems[index];
      _mediaItems[index] = _mediaItems[index - 1];
      _mediaItems[index - 1] = tmp;
      _mediaItems[index].displayOrder = index;
      _mediaItems[index - 1].displayOrder = index - 1;
    });
  }

  void _moveDown(int index) {
    if (index >= _mediaItems.length - 1) return;
    setState(() {
      final tmp = _mediaItems[index];
      _mediaItems[index] = _mediaItems[index + 1];
      _mediaItems[index + 1] = tmp;
      _mediaItems[index].displayOrder = index;
      _mediaItems[index + 1].displayOrder = index + 1;
    });
  }

  // ── Save / Submit ─────────────────────────────────────────────────────────

  void _saveDraft(BuildContext ctx) {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and description'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _ensureDraft();

    final uploaded =
        _mediaItems.where((m) => m.status == _UploadStatus.success).length;
    final total = _mediaItems.length;

    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          total == 0
              ? 'Impact post saved as Draft'
              : 'Draft saved — $uploaded/$total files uploaded',
        ),
        backgroundColor: _kPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitForApproval(BuildContext ctx) {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and description'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final postId = _ensureDraft();
    widget.vm.submitImpactPostForApproval(postId);

    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text(
          'Sent to Admin for approval. It will be published once approved.',
        ),
        backgroundColor: _kPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.90,
      maxChildSize: 0.97,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: _kPurple,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Impact Post',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Punjabi Welfare Trust · Wall of Impact',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                children: [
                  // ── Post category ──────────────────────────────────────
                  _SheetLabel(
                    icon: Icons.category_outlined,
                    text: 'Post Category *',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: EMImpactPostType.values
                        .map(
                          (t) => ChoiceChip(
                            label: Text(
                              t.label,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _type == t,
                            onSelected: (_) => setState(() => _type = t),
                            avatar: Icon(t.icon, size: 12),
                            selectedColor: _kPurple.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: _type == t ? _kPurple : AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Post title ─────────────────────────────────────────
                  _SheetLabel(icon: Icons.title_rounded, text: 'Post Title *'),
                  const SizedBox(height: 8),
                  _sheetField(
                    _titleCtrl,
                    'e.g. Stationery Drive — 150 Kits Distributed',
                  ),
                  const SizedBox(height: 16),

                  // ── Linked event ───────────────────────────────────────
                  _SheetLabel(
                    icon: Icons.event_rounded,
                    text: 'Linked Event',
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<NGOEvent>(
                    initialValue: _selectedEvent,
                    hint: const Text(
                      'Select event (optional)',
                      style: TextStyle(fontSize: 13),
                    ),
                    items: widget.vm.events
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e.title,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedEvent = v),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Upload Photos & Videos ─────────────────────────────
                  _MediaUploadSectionHeader(
                    imageCount: _imageCount,
                    videoCount: _videoCount,
                  ),
                  const SizedBox(height: 10),
                  _UploadZone(
                    onTap: _pickMedia,
                    compact: _mediaItems.isNotEmpty,
                  ),

                  // Media preview cards
                  if (_mediaItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...List.generate(_mediaItems.length, (i) {
                      final item = _mediaItems[i];
                      return _MediaPreviewCard(
                        key: ValueKey(item.localId),
                        item: item,
                        index: i,
                        total: _mediaItems.length,
                        onRemove: () => _removeMedia(item.localId),
                        onCover: () => _setCover(item.localId),
                        onMoveUp: () => _moveUp(i),
                        onMoveDown: () => _moveDown(i),
                        onRetry: () {
                          final pid = _draftPostId;
                          if (pid != null) _uploadSingleItem(item, pid);
                        },
                      );
                    }),
                    const SizedBox(height: 4),

                    // Overall upload progress
                    if (_isUploading)
                      _OverallProgressBar(mediaItems: _mediaItems),

                    // Upload Media button
                    if (_hasPendingUploads || _isUploading) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isUploading ? null : _onUploadMediaPressed,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _kPurple,
                                  ),
                                )
                              : const Icon(
                                  Icons.cloud_upload_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            _isUploading ? 'Uploading…' : 'Upload Media',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPurple,
                            side: const BorderSide(color: _kPurple),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ] else if (_allUploaded) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2E7D32)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF2E7D32),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'All ${_mediaItems.length} file${_mediaItems.length == 1 ? '' : 's'} uploaded successfully',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),

                  // ── Description ────────────────────────────────────────
                  _SheetLabel(
                    icon: Icons.description_outlined,
                    text: 'Description *',
                  ),
                  const SizedBox(height: 8),
                  _sheetField(
                    _descCtrl,
                    'Describe what happened and the impact made…',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // ── Appreciation message ───────────────────────────────
                  _SheetLabel(
                    icon: Icons.format_quote_rounded,
                    text: 'Appreciation Message *',
                  ),
                  const SizedBox(height: 8),
                  _sheetField(
                    _appreciationCtrl,
                    'e.g. Punjabi Welfare Trust salutes the dedication…',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // ── Action buttons ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _saveDraft(context),
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text(
                        'Save as Draft',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: BorderSide(
                          color: AppColors.muted.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _submitForApproval(context),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text(
                        'Submit for Admin Approval',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.muted.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.muted.withValues(alpha: 0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.muted.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kPurple, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

// ─── Media section header ─────────────────────────────────────────────────────

class _MediaUploadSectionHeader extends StatelessWidget {
  const _MediaUploadSectionHeader({
    required this.imageCount,
    required this.videoCount,
  });

  final int imageCount;
  final int videoCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.photo_library_rounded,
                color: _kPurple,
                size: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Upload Photos & Videos',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.muted.withValues(alpha: 0.18)),
              ),
              child: Text(
                '$imageCount/$_kMaxImages photos · $videoCount/$_kMaxVideos videos',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.only(left: 30),
          child: Text(
            'Add verified activity photos, certificate images, appreciation\n'
            'letters, or short videos to support this impact post.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Upload zone ──────────────────────────────────────────────────────────────

class _UploadZone extends StatelessWidget {
  const _UploadZone({
    required this.onTap,
    this.compact = false,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
          decoration: BoxDecoration(
            color: _kPurple.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _kPurple.withValues(alpha: 0.22),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded,
                  color: _kPurple, size: 17),
              SizedBox(width: 8),
              Text(
                'Add more photos or videos',
                style: TextStyle(
                  color: _kPurple,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        decoration: BoxDecoration(
          color: _kPurple.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _kPurple.withValues(alpha: 0.28),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: _kPurple,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tap to upload photos or videos',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'JPG, PNG, WEBP, MP4, MOV, WEBM, PDF supported',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 10,
              children: [
                _UploadHint(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                ),
                _UploadHint(
                  icon: Icons.folder_open_rounded,
                  label: 'Browse Files',
                ),
                if (!kIsWeb)
                  _UploadHint(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                  ),
                if (kIsWeb)
                  _UploadHint(
                    icon: Icons.drag_indicator_rounded,
                    label: 'Drag & Drop',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 6,
              children: const [
                _LimitChip(label: '10 photos max · 5 MB each'),
                _LimitChip(label: '2 videos max · 50 MB each'),
                _LimitChip(label: 'PDF proof supported · 10 MB'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadHint extends StatelessWidget {
  const _UploadHint({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: _kPurple, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LimitChip extends StatelessWidget {
  const _LimitChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.muted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Overall upload progress bar ──────────────────────────────────────────────

class _OverallProgressBar extends StatelessWidget {
  const _OverallProgressBar({required this.mediaItems});
  final List<_ImpactMedia> mediaItems;

  @override
  Widget build(BuildContext context) {
    final total = mediaItems.length;
    final done =
        mediaItems.where((m) => m.status == _UploadStatus.success).length;
    final avgPct = total == 0
        ? 0.0
        : mediaItems.fold(0.0, (sum, m) => sum + m.progress) / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Uploading — $done/$total done',
                style: const TextStyle(
                  color: _kPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(avgPct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: _kPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: avgPct,
              backgroundColor: _kPurple.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(_kPurple),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Media preview card ───────────────────────────────────────────────────────

class _MediaPreviewCard extends StatefulWidget {
  const _MediaPreviewCard({
    required this.item,
    required this.index,
    required this.total,
    required this.onRemove,
    required this.onCover,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRetry,
    super.key,
  });

  final _ImpactMedia item;
  final int index;
  final int total;
  final VoidCallback onRemove;
  final VoidCallback onCover;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRetry;

  @override
  State<_MediaPreviewCard> createState() => _MediaPreviewCardState();
}

class _MediaPreviewCardState extends State<_MediaPreviewCard> {
  late final TextEditingController _captionCtrl;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.item.caption);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Color get _borderColor {
    return switch (widget.item.status) {
      _UploadStatus.pending => AppColors.muted.withValues(alpha: 0.22),
      _UploadStatus.uploading => _kPurple.withValues(alpha: 0.45),
      _UploadStatus.success =>
        const Color(0xFF2E7D32).withValues(alpha: 0.4),
      _UploadStatus.failed =>
        AppColors.softRed.withValues(alpha: 0.45),
    };
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MediaThumbnail(item: item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.isCover) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kPurple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'COVER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              item.fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _MediaTypeBadge(item.mediaType),
                          const SizedBox(width: 8),
                          Text(
                            item.sizeLabel,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _ItemUploadStatus(
                        item: item,
                        onRetry: widget.onRetry,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.muted,
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Per-item progress bar ──────────────────────────────────────
          if (item.status == _UploadStatus.uploading) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(item.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: _kPurple,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      backgroundColor: _kPurple.withValues(alpha: 0.12),
                      valueColor:
                          const AlwaysStoppedAnimation(_kPurple),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          Divider(
            height: 1,
            color: AppColors.muted.withValues(alpha: 0.09),
          ),

          // ── Caption + action row ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: [
                TextField(
                  controller: _captionCtrl,
                  decoration: InputDecoration(
                    hintText: 'Add caption (optional)',
                    hintStyle: TextStyle(
                      color: AppColors.muted.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _kPurple, width: 1.2),
                    ),
                  ),
                  style: const TextStyle(fontSize: 12.5),
                  onChanged: (v) => widget.item.caption = v,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Order controls
                    if (widget.total > 1) ...[
                      _OrderBtn(
                        icon: Icons.arrow_upward_rounded,
                        enabled: widget.index > 0,
                        onTap: widget.onMoveUp,
                        tooltip: 'Move up',
                      ),
                      const SizedBox(width: 4),
                      _OrderBtn(
                        icon: Icons.arrow_downward_rounded,
                        enabled: widget.index < widget.total - 1,
                        onTap: widget.onMoveDown,
                        tooltip: 'Move down',
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Cover toggle (images only)
                    if (item.isImage)
                      Expanded(
                        child: item.isCover
                            ? Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _kPurple.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _kPurple.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 13, color: _kPurple),
                                    SizedBox(width: 5),
                                    Text(
                                      'Cover Image',
                                      style: TextStyle(
                                        color: _kPurple,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: widget.onCover,
                                icon: const Icon(
                                    Icons.star_outline_rounded,
                                    size: 13),
                                label: const Text(
                                  'Set as Cover',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kPurple,
                                  side:
                                      const BorderSide(color: _kPurple),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
                                ),
                              ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: widget.onRemove,
                      icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 14),
                      label: const Text(
                        'Remove',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.softRed,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Media thumbnail ──────────────────────────────────────────────────────────

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.item});
  final _ImpactMedia item;

  static const double _sz = 60;
  static final _radius = BorderRadius.circular(10);

  @override
  Widget build(BuildContext context) {
    if (item.isDocument) {
      return _shell(
        const Color(0xFFFFF3E0),
        const Icon(Icons.picture_as_pdf_rounded,
            color: Color(0xFFBF360C), size: 28),
      );
    }

    if (item.isVideo) {
      return Stack(
        children: [
          _shell(
            AppColors.ink.withValues(alpha: 0.08),
            const Icon(Icons.videocam_rounded,
                color: AppColors.muted, size: 28),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      );
    }

    // Image preview
    if (kIsWeb && item.bytes != null) {
      return ClipRRect(
        borderRadius: _radius,
        child: Image.memory(
          item.bytes!,
          width: _sz,
          height: _sz,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _shell(
            _kPurple.withValues(alpha: 0.08),
            const Icon(Icons.broken_image_rounded,
                color: _kPurple, size: 24),
          ),
        ),
      );
    }

    if (!kIsWeb && item.filePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: _radius,
        child: Image.file(
          File(item.filePath),
          width: _sz,
          height: _sz,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _shell(
            _kPurple.withValues(alpha: 0.08),
            const Icon(Icons.broken_image_rounded,
                color: _kPurple, size: 24),
          ),
        ),
      );
    }

    return _shell(
      _kPurple.withValues(alpha: 0.08),
      const Icon(Icons.image_rounded, color: _kPurple, size: 28),
    );
  }

  Widget _shell(Color bg, Widget child) => Container(
        width: _sz,
        height: _sz,
        decoration: BoxDecoration(color: bg, borderRadius: _radius),
        child: Center(child: child),
      );
}

// ─── Item upload status ───────────────────────────────────────────────────────

class _ItemUploadStatus extends StatelessWidget {
  const _ItemUploadStatus({required this.item, required this.onRetry});
  final _ImpactMedia item;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (item.status) {
      _UploadStatus.pending => const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: AppColors.muted),
            SizedBox(width: 4),
            Text(
              'Ready to upload',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      _UploadStatus.uploading => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: _kPurple,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Uploading — ${(item.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: _kPurple,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      _UploadStatus.success => const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 13, color: Color(0xFF2E7D32)),
            SizedBox(width: 5),
            Text(
              'Uploaded successfully',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      _UploadStatus.failed => GestureDetector(
          onTap: onRetry,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_rounded,
                  size: 13, color: AppColors.softRed),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  item.errorMessage ?? 'Upload failed',
                  style: const TextStyle(
                      color: AppColors.softRed, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: _kPurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
    };
  }
}

// ─── Media type badge ─────────────────────────────────────────────────────────

class _MediaTypeBadge extends StatelessWidget {
  const _MediaTypeBadge(this.type);
  final _MediaType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      _MediaType.image => ('IMAGE', const Color(0xFF1565C0)),
      _MediaType.video => ('VIDEO', const Color(0xFFBF360C)),
      _MediaType.document => ('PDF', const Color(0xFF2E7D32)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Order button ─────────────────────────────────────────────────────────────

class _OrderBtn extends StatelessWidget {
  const _OrderBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.ink.withValues(alpha: 0.07)
                : AppColors.muted.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 14,
            color: enabled
                ? AppColors.ink
                : AppColors.muted.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

// ─── Sheet section label ──────────────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kPurple),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
