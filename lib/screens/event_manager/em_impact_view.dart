import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../repositories/api_client.dart';
import '../../repositories/event_manager_repository.dart';
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
    this.bytes,
    required this.fileName,
    required this.mediaType,
    required this.fileSize,
    this.isCover = false,
    required this.displayOrder,
    _UploadStatus status = _UploadStatus.pending,
    String? remoteUrl,
  })  : status = status,
        remoteUrl = remoteUrl;

  /// Creates an item pre-populated from a URL that already exists on the server
  /// (used when editing a draft that already has media).
  factory _ImpactMedia.existing(String url, int displayOrder) {
    final lower = url.toLowerCase();
    final mediaType = lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.webm')
        ? _MediaType.video
        : lower.endsWith('.pdf')
            ? _MediaType.document
            : _MediaType.image;
    return _ImpactMedia(
      localId: url,
      fileName: url.split('/').last,
      mediaType: mediaType,
      fileSize: 0,
      isCover: displayOrder == 0,
      displayOrder: displayOrder,
      status: _UploadStatus.success,
      remoteUrl: url,
    );
  }

  final String localId;
  final Uint8List? bytes;
  final String fileName;
  final _MediaType mediaType;
  final int fileSize;
  _UploadStatus status;
  String? remoteUrl;
  bool isCover;
  int displayOrder;
  String? caption;
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

  /// Serialises this item for the `media` list in POST /impact/posts or
  /// PATCH /impact/posts/{id}.
  Map<String, dynamic> toApiMap(int position) => {
        'url': remoteUrl!,
        'media_type': mediaType == _MediaType.video
            ? 'video'
            : mediaType == _MediaType.document
                ? 'document'
                : 'image',
        if (caption != null) 'caption': caption,
        'position': position,
      };
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
                    _PublishedTab(posts: published, vm: widget.vm),
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
      itemBuilder: (context, i) => _DraftPostCard(
        post: posts[i],
        vm: vm,
        onEdit: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _CreateImpactPostSheet(
            vm: vm,
            existingPost: posts[i],
          ),
        ),
      ),
    );
  }
}

// ─── Draft Post Card ──────────────────────────────────────────────────────────

// ─── Draft Post Card ──────────────────────────────────────────────────────────

class _DraftPostCard extends StatefulWidget {
  const _DraftPostCard({required this.post, required this.vm, this.onEdit});
  final EMImpactPost post;
  final EventManagerViewModel vm;
  final VoidCallback? onEdit;

  @override
  State<_DraftPostCard> createState() => _DraftPostCardState();
}

class _DraftPostCardState extends State<_DraftPostCard> {
  bool _expanded = false;

  String get _dateLabel {
    final d = widget.post.date;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final vm = widget.vm;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category badge + draft status ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: post.type.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(post.type.icon,
                          color: Colors.white, size: 11),
                      const SizedBox(width: 5),
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
                _DraftChip(isSubmitted: post.isPublished),
              ],
            ),
          ),
          // ── Title + date / location ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      _dateLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500),
                    ),
                    const Text('  ·  ',
                        style: TextStyle(color: AppColors.muted)),
                    const Icon(Icons.location_on_rounded,
                        size: 12, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        post.location,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Full-width cover image ─────────────────────────────────────
          if (post.photoUrls.isNotEmpty)
            _FullWidthCoverImage(photoUrls: post.photoUrls),
          // ── Description ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.55,
                  ),
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
                if (!_expanded)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = true),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Read more',
                        style: TextStyle(
                          color: _kPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── 4-metric grid ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: _ImpactMetricsGrid(post: post),
          ),
          // ── Appreciation message ───────────────────────────────────────
          if (post.appreciationMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2E7D32)
                          .withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.appreciationMessage,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // ── Verified by ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded,
                    color: _kPurple, size: 13),
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
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 14, endIndent: 14),
          // ── Action buttons ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: [
                if (!post.adminApproved && widget.onEdit != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: const Text('Edit Draft',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPurple,
                        side: const BorderSide(color: _kPurple),
                        padding:
                            const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
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
                                    'Impact post approved and published.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.verified_rounded, size: 15),
                      label: const Text('Approve & Publish',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding:
                            const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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
                                'Sent to Admin for approval.'),
                            backgroundColor: _kPurple,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const Text('Submit for Approval',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPurple,
                        padding:
                            const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.pending_rounded,
                            color: Color(0xFF1565C0), size: 15),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sent for Admin Approval — awaiting review',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
  const _PublishedTab({required this.posts, required this.vm});
  final List<EMImpactPost> posts;
  final EventManagerViewModel vm;

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
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PublishedPostCard(post: posts[i], vm: vm),
    );
  }
}

// ─── Published Post Card ──────────────────────────────────────────────────────

class _PublishedPostCard extends StatefulWidget {
  const _PublishedPostCard({required this.post, required this.vm});
  final EMImpactPost post;
  final EventManagerViewModel vm;

  @override
  State<_PublishedPostCard> createState() => _PublishedPostCardState();
}

class _PublishedPostCardState extends State<_PublishedPostCard> {
  bool _expanded = false;
  bool _deleting = false;

  String get _dateLabel {
    final d = widget.post.date;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category badge + PUBLISHED chip ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: post.type.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(post.type.icon,
                          color: Colors.white, size: 11),
                      const SizedBox(width: 5),
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
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF2E7D32)
                            .withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: Color(0xFF2E7D32), size: 11),
                      SizedBox(width: 4),
                      Text(
                        'PUBLISHED',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
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
          ),
          // ── Title + date / location ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      _dateLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500),
                    ),
                    const Text('  ·  ',
                        style: TextStyle(color: AppColors.muted)),
                    const Icon(Icons.location_on_rounded,
                        size: 12, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        post.location,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Full-width 16:9 cover image with +N More ──────────────────
          if (post.photoUrls.isNotEmpty)
            _FullWidthCoverImage(photoUrls: post.photoUrls),
          // ── Description + Read more ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.55,
                  ),
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
                if (!_expanded)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = true),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text(
                        'Read more',
                        style: TextStyle(
                          color: _kPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── 4-metric grid ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: _ImpactMetricsGrid(post: post),
          ),
          // ── Appreciation message ───────────────────────────────────────
          if (post.appreciationMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2E7D32)
                          .withValues(alpha: 0.18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.appreciationMessage,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 14, endIndent: 14),
          // ── Share + View Details + Admin Delete ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sharing impact post…'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 14),
                        label: const Text('Share',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPurple,
                          side: const BorderSide(color: _kPurple),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _PostDetailSheet(post: post),
                        ),
                        icon: const Icon(Icons.remove_red_eye_rounded,
                            size: 14),
                        label: const Text('View Details',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPurple,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                // Admin-only delete button
                if (AppState.role.isAdmin) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _deleting
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFFC62828),
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _confirmDelete(context),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 15),
                            label: const Text('Delete Post',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC62828),
                              side: const BorderSide(
                                  color: Color(0xFFC62828)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 22),
            SizedBox(width: 10),
            Text('Delete Post?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          'This will permanently delete "${widget.post.title}" and all its media. This cannot be undone.',
          style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.muted,
              side: BorderSide(color: AppColors.muted.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.vm.deleteImpactPost(widget.post.id);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Impact post deleted.',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          backgroundColor: Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to delete. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── Full-width cover image with +N More overlay ──────────────────────────────

class _FullWidthCoverImage extends StatelessWidget {
  const _FullWidthCoverImage({required this.photoUrls});
  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    final extra = photoUrls.length - 1;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            ApiClient.resolveUrl(photoUrls.first),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: const Color(0xFFF0F0F0),
              child: const Center(
                child: Icon(Icons.image_rounded,
                    size: 48, color: AppColors.muted),
              ),
            ),
          ),
        ),
        if (extra > 0)
          Positioned(
            bottom: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+$extra More',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── 4-tile impact metrics grid ───────────────────────────────────────────────

class _ImpactMetricsGrid extends StatelessWidget {
  const _ImpactMetricsGrid({required this.post});
  final EMImpactPost post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricTile(
          icon: Icons.group_rounded,
          value: '0',
          label: 'Volunteers',
          color: _kPurple,
        ),
        const SizedBox(width: 7),
        _MetricTile(
          icon: Icons.people_rounded,
          value: '${post.studentsHelped ?? 0}',
          label: 'Children\nHelped',
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 7),
        _MetricTile(
          icon: Icons.access_time_rounded,
          value: post.hoursServed != null
              ? post.hoursServed!.toStringAsFixed(0)
              : '0',
          label: 'Hours',
          color: const Color(0xFFE65100),
        ),
        const SizedBox(width: 7),
        _MetricTile(
          icon: Icons.workspace_premium_rounded,
          value: '0',
          label: 'Certificates',
          color: const Color(0xFF2E7D32),
        ),
      ],
    );
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

// ─── Create Impact Post — 4-step wizard ──────────────────────────────────────

class _CreateImpactPostSheet extends StatefulWidget {
  const _CreateImpactPostSheet({required this.vm, this.existingPost});
  final EventManagerViewModel vm;
  final EMImpactPost? existingPost;

  @override
  State<_CreateImpactPostSheet> createState() => _CreateImpactPostSheetState();
}

// Step labels used in the progress indicator
const _kStepLabels = ['Basic Info', 'Media', 'Story', 'Review'];

class _CreateImpactPostSheetState extends State<_CreateImpactPostSheet> {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _appreciationCtrl;
  late final TextEditingController _summaryCtrl;
  late final PageController _pageCtrl;

  // ── Step state ────────────────────────────────────────────────────────────
  int _step = 0;

  // ── Step 1: Basic Info ────────────────────────────────────────────────────
  late EMImpactPostType _type;
  NGOEvent? _selectedEvent;

  // ── Step 2: Media ─────────────────────────────────────────────────────────
  final List<_ImpactMedia> _mediaItems = [];
  bool _isUploading = false;

  int get _imageCount => _mediaItems.where((m) => m.isImage).length;
  int get _videoCount => _mediaItems.where((m) => m.isVideo).length;


  List<Map<String, dynamic>> get _uploadedMediaList {
    final uploaded =
        _mediaItems.where((m) => m.remoteUrl != null).toList();
    return List.generate(uploaded.length, (i) => uploaded[i].toApiMap(i));
  }

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    final p = widget.existingPost;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _appreciationCtrl = TextEditingController(text: p?.appreciationMessage ?? '');
    _summaryCtrl = TextEditingController(
      text: p != null
          ? 'We reached ${p.studentsHelped ?? 0} beneficiaries in ${p.hoursServed?.toStringAsFixed(0) ?? '0'} hours.'
          : '',
    );
    _type = p?.type ?? EMImpactPostType.eventSuccessReport;
    if (p != null) {
      for (var i = 0; i < p.photoUrls.length; i++) {
        _mediaItems.add(_ImpactMedia.existing(p.photoUrls[i], i));
      }
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _appreciationCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  EMImpactPost _buildPost(int id) => EMImpactPost(
        id: id,
        type: _type,
        title: _titleCtrl.text.trim(),
        eventName: _selectedEvent?.title ?? 'NGO Event',
        location: _selectedEvent?.location ?? '',
        date: DateTime.now(),
        description: _descCtrl.text.trim(),
        appreciationMessage: _appreciationCtrl.text.trim().isEmpty
            ? 'Thank you to everyone who made this impact possible.'
            : _appreciationCtrl.text.trim(),
        isPublished: false,
        adminApproved: false,
        verifiedByName: AppState.studentName ?? 'Event Manager',
      );

  // ── Navigation ─────────────────────────────────────────────────────────────

  bool _canGoNext() {
    if (_step == 0) return _titleCtrl.text.trim().isNotEmpty;
    if (_step == 2) return _descCtrl.text.trim().isNotEmpty;
    return true;
  }

  void _next() {
    if (!_canGoNext()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please complete all required fields.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_step < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _step--);
    }
  }

  // ── File picking ─────────────────────────────────────────────────────────

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'webm', 'pdf'],
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final errors = <String>[];
    final newItems = <_ImpactMedia>[];

    for (final file in result.files) {
      if (file.bytes == null) continue;
      final ext = (file.extension ?? '').toLowerCase();
      final isImg = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
      final isVid = ['mp4', 'mov', 'webm'].contains(ext);
      final isDoc = ext == 'pdf';

      if (!isImg && !isVid && !isDoc) {
        errors.add('${file.name}: unsupported type');
        continue;
      }
      if (isImg && _imageCount + newItems.where((m) => m.isImage).length >= _kMaxImages) {
        errors.add('Max $_kMaxImages images — ${file.name} skipped');
        continue;
      }
      if (isVid && _videoCount + newItems.where((m) => m.isVideo).length >= _kMaxVideos) {
        errors.add('Max $_kMaxVideos videos — ${file.name} skipped');
        continue;
      }
      final maxBytes = isVid ? _kMaxVideoBytes : isDoc ? _kMaxDocBytes : _kMaxImageBytes;
      if (file.size > maxBytes) {
        errors.add('${file.name}: exceeds ${(maxBytes / (1024 * 1024)).toStringAsFixed(0)} MB limit');
        continue;
      }

      final type = isImg ? _MediaType.image : isVid ? _MediaType.video : _MediaType.document;
      final isCover = _mediaItems.isEmpty && newItems.isEmpty && isImg;
      newItems.add(_ImpactMedia(
        localId: '${DateTime.now().microsecondsSinceEpoch}_${_mediaItems.length + newItems.length}',
        bytes: file.bytes,
        fileName: file.name,
        mediaType: type,
        fileSize: file.size,
        isCover: isCover,
        displayOrder: _mediaItems.length + newItems.length,
      ));
    }

    if (errors.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errors.join('\n'), style: const TextStyle(fontSize: 12)),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
      ));
    }

    if (newItems.isEmpty) return;

    setState(() => _mediaItems.addAll(newItems));

    // Upload immediately (like Submit Work) — one file at a time.
    setState(() => _isUploading = true);
    for (final item in newItems) {
      if (!mounted) break;
      await _uploadSingleItem(item);
    }
    if (mounted) setState(() => _isUploading = false);

    if (!mounted) return;
    final failed = newItems.where((m) => m.status == _UploadStatus.failed).length;
    final ok = newItems.where((m) => m.status == _UploadStatus.success).length;
    if (failed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$ok uploaded · $failed failed — tap Retry on failed files'),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('$ok file${ok == 1 ? '' : 's'} uploaded',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  /// Upload one item to the generic /impact/upload-media endpoint immediately
  /// (no post ID required). Sets remoteUrl on success, errorMessage on failure.
  Future<void> _uploadSingleItem(_ImpactMedia item) async {
    if (item.status == _UploadStatus.success) return;
    if (item.bytes == null) {
      setState(() {
        item.status = _UploadStatus.failed;
        item.errorMessage = 'No file data';
      });
      return;
    }

    setState(() {
      item.status = _UploadStatus.uploading;
      item.errorMessage = null;
    });

    try {
      final mediaTypeStr = item.mediaType == _MediaType.video
          ? 'video'
          : item.mediaType == _MediaType.document
              ? 'document'
              : 'image';
      final url = await EventManagerRepository.uploadImpactMedia(
        bytes: item.bytes!,
        fileName: item.fileName,
        mediaType: mediaTypeStr,
      );
      if (!mounted) return;
      setState(() {
        item.remoteUrl = url;
        item.status = _UploadStatus.success;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final shortMsg = msg.length > 80 ? '${msg.substring(0, 80)}…' : msg;
      setState(() {
        item.status = _UploadStatus.failed;
        item.errorMessage = msg.contains('404')
            ? 'Endpoint not found (404)'
            : msg.contains('SocketException') || msg.contains('Connection refused')
                ? 'Cannot reach server'
                : msg.contains('TimeoutException') || msg.contains('timed out')
                    ? 'Timed out — tap Retry'
                    : 'Failed: $shortMsg';
      });
    }
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

  Future<void> _saveDraft(BuildContext ctx) async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and description'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If any uploads are still in progress, wait for them.
    if (_isUploading) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Please wait for uploads to finish…'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final media = _uploadedMediaList;
    if (widget.existingPost != null) {
      await widget.vm.updateImpactPost(
        widget.existingPost!.id,
        _buildPost(widget.existingPost!.id),
        mediaList: media,
      );
    } else {
      await widget.vm.addImpactPost(_buildPost(0), mediaList: media);
    }

    if (!ctx.mounted) return;
    final failed = _mediaItems.where((m) => m.status == _UploadStatus.failed).length;
    if (failed > 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(
          'Draft saved — $failed file${failed == 1 ? '' : 's'} still failed. Tap Retry then save again.',
        ),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    final messenger = ScaffoldMessenger.of(ctx);
    Navigator.pop(ctx);
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.existingPost != null ? 'Impact post updated' : 'Impact post saved as Draft',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ]),
      backgroundColor: _kPurple,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _submitForApproval(BuildContext ctx) async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Please fill in title and description'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_isUploading) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Please wait for uploads to finish…'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final failed = _mediaItems.where((m) => m.status == _UploadStatus.failed).length;
    if (failed > 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(
          '$failed file${failed == 1 ? '' : 's'} failed — tap Retry before submitting.',
        ),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    final media = _uploadedMediaList;
    int postId;
    if (widget.existingPost != null) {
      postId = widget.existingPost!.id;
      await widget.vm.updateImpactPost(postId, _buildPost(postId), mediaList: media);
    } else {
      postId = await widget.vm.addImpactPost(_buildPost(0), mediaList: media);
    }
    if (!ctx.mounted) return;

    widget.vm.submitImpactPostForApproval(postId);
    final messenger = ScaffoldMessenger.of(ctx);
    Navigator.pop(ctx);
    messenger.showSnackBar(const SnackBar(
      content: Text('Sent to Admin for approval. It will be published once approved.'),
      backgroundColor: _kPurple,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Sheet header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _kPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: _kPurple, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingPost != null
                              ? 'Edit Impact Post'
                              : 'Create Impact Post',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Step ${_step + 1} of 4 · ${_kStepLabels[_step]}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            // Step progress indicator
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
              child: Row(
                children: List.generate(_kStepLabels.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    final stepIdx = i ~/ 2;
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: stepIdx < _step
                            ? _kPurple
                            : AppColors.muted.withValues(alpha: 0.2),
                      ),
                    );
                  }
                  final stepIdx = i ~/ 2;
                  final done = stepIdx < _step;
                  final active = stepIdx == _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done || active ? _kPurple : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done || active
                            ? _kPurple
                            : AppColors.muted.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : Text(
                              '${stepIdx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: active ? Colors.white : AppColors.muted,
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ),
            const Divider(height: 1),
            // Step pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(scrollCtrl),
                  _buildStep2(scrollCtrl),
                  _buildStep3(scrollCtrl),
                  _buildStep4(scrollCtrl),
                ],
              ),
            ),
            // Bottom navigation bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPurple,
                          side: const BorderSide(color: _kPurple),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  if (_step < 3)
                    Expanded(
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Continue',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _saveDraft(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPurple,
                          side: const BorderSide(color: _kPurple),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save Draft',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _submitForApproval(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Submit',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Basic Info ──────────────────────────────────────────────────────

  Widget _buildStep1(ScrollController ctrl) {
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      children: [
        _StepSectionTitle(
          icon: Icons.category_outlined,
          title: 'Post Category',
          subtitle: 'Choose the type of impact story',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EMImpactPostType.values.map((t) {
            final selected = _type == t;
            return GestureDetector(
              onTap: () => setState(() => _type = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? t.color.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? t.color
                        : AppColors.muted.withValues(alpha: 0.25),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    if (!selected)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon,
                        size: 14,
                        color: selected ? t.color : AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                        color: selected ? t.color : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _StepSectionTitle(
          icon: Icons.title_rounded,
          title: 'Post Title *',
          subtitle: 'A compelling headline for the story',
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _titleCtrl,
          onChanged: (_) => setState(() {}),
          decoration:
              _inputDecoration('e.g. 50 Students Receive Career Counselling'),
          style:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 24),
        _StepSectionTitle(
          icon: Icons.event_rounded,
          title: 'Linked Event',
          subtitle: 'Link an event to auto-fill metrics',
        ),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: widget.vm,
          builder: (context, _) {
            final events = widget.vm.events;
            if (events.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.muted.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  'No events available to link.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.muted.withValues(alpha: 0.25)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<NGOEvent?>(
                  value: _selectedEvent,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  borderRadius: BorderRadius.circular(12),
                  hint: const Text('Select event (optional)',
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 13)),
                  items: [
                    const DropdownMenuItem<NGOEvent?>(
                      value: null,
                      child: Text('None',
                          style: TextStyle(color: AppColors.muted)),
                    ),
                    ...events.map((e) => DropdownMenuItem<NGOEvent?>(
                          value: e,
                          child: Text(e.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedEvent = v;
                      if (v != null) {
                        _summaryCtrl.text =
                            'We reached ${v.maxVolunteers} volunteers at ${v.location}.';
                      }
                    });
                  },
                ),
              ),
            );
          },
        ),
        if (_selectedEvent != null) ...[
          const SizedBox(height: 12),
          _AutoFillBanner(event: _selectedEvent!),
        ],
      ],
    );
  }

  // ── Step 2: Media Upload ────────────────────────────────────────────────────

  Widget _buildStep2(ScrollController ctrl) {
    final images = _mediaItems.where((m) => m.isImage).toList();
    final others = _mediaItems.where((m) => !m.isImage).toList();
    final uploadedCount =
        _mediaItems.where((m) => m.status == _UploadStatus.success).length;
    final totalCount = _mediaItems.length;
    final progress =
        totalCount == 0 ? 0.0 : uploadedCount / totalCount;

    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      children: [
        _StepSectionTitle(
          icon: Icons.photo_library_rounded,
          title: 'Upload Photos & Videos',
          subtitle:
              'First image becomes the cover. Up to $_kMaxImages photos.',
        ),
        const SizedBox(height: 14),
        // Upload zone
        GestureDetector(
          onTap: _pickMedia,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              color: _kPurple.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _kPurple.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: _kPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tap to add photos or videos',
                  style: TextStyle(
                    color: _kPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'JPG, PNG, WEBP (max 5 MB) · MP4, MOV (max 50 MB)',
                  style: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Overall upload progress
        if (_isUploading ||
            (totalCount > 0 && uploadedCount < totalCount)) ...[
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.upload_rounded,
                      size: 14, color: _kPurple),
                  const SizedBox(width: 6),
                  Text(
                    'Uploaded $uploadedCount of $totalCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  color: _kPurple,
                  backgroundColor: _kPurple.withValues(alpha: 0.1),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
        // Image grid
        if (images.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Photos (${images.length})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, i) {
              final item = images[i];
              final globalIdx = _mediaItems.indexOf(item);
              return _ImageThumb(
                item: item,
                onSetCover: () => _setCover(item.localId),
                onRemove: () => _removeMedia(item.localId),
                onMoveUp: globalIdx > 0 ? () => _moveUp(globalIdx) : null,
                onMoveDown: globalIdx < _mediaItems.length - 1
                    ? () => _moveDown(globalIdx)
                    : null,
                onRetry: item.status == _UploadStatus.failed
                    ? () {
                        setState(
                            () => item.status = _UploadStatus.pending);
                        _uploadSingleItem(item);
                      }
                    : null,
              );
            },
          ),
        ],
        // Non-image files list
        if (others.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Videos & Documents (${others.length})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          ...others.map((item) => _FileListTile(
                item: item,
                onRemove: () => _removeMedia(item.localId),
                onRetry: item.status == _UploadStatus.failed
                    ? () {
                        setState(
                            () => item.status = _UploadStatus.pending);
                        _uploadSingleItem(item);
                      }
                    : null,
              )),
        ],
        if (_mediaItems.isEmpty) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              'No media yet — photos make posts 3× more engaging.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Step 3: Impact Story ────────────────────────────────────────────────────

  Widget _buildStep3(ScrollController ctrl) {
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      children: [
        _StepSectionTitle(
          icon: Icons.auto_stories_rounded,
          title: 'Impact Description *',
          subtitle: 'Tell the story of what happened',
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descCtrl,
          decoration: _inputDecoration(
            'Describe the event, who was helped, and what was achieved…',
            maxLines: 6,
          ),
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        _StepSectionTitle(
          icon: Icons.bar_chart_rounded,
          title: 'Impact Summary',
          subtitle: 'One-line headline metric statement',
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _summaryCtrl,
          decoration: _inputDecoration(
              'e.g. We reached 200 students in 3 hours'),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 24),
        _StepSectionTitle(
          icon: Icons.favorite_outline_rounded,
          title: 'Appreciation Message',
          subtitle: 'Thank volunteers, sponsors, or the school',
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _appreciationCtrl,
          decoration: _inputDecoration(
            'e.g. Thank you to all our volunteers who made this possible.',
            maxLines: 3,
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  // ── Step 4: Review & Submit ─────────────────────────────────────────────────

  Widget _buildStep4(ScrollController ctrl) {
    final images = _mediaItems
        .where((m) => m.isImage && m.remoteUrl != null)
        .toList();

    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      children: [
        _StepSectionTitle(
          icon: Icons.preview_rounded,
          title: 'Review Your Post',
          subtitle: 'This is how it will look on the Wall of Impact',
        ),
        const SizedBox(height: 16),
        // Preview card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _kPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assests/ngo_logo.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.volunteer_activism_rounded,
                            color: _kPurple,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Punjabi Welfare Trust',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                          Text(
                            'Just now',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _type.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _type.color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _type.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _type.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Text(
                  _titleCtrl.text.isNotEmpty
                      ? _titleCtrl.text
                      : '(No title)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              // Cover image preview
              if (images.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: images.first.bytes != null
                      ? Image.memory(images.first.bytes!,
                          fit: BoxFit.cover)
                      : images.first.remoteUrl != null
                          ? Image.network(
                              ApiClient.resolveUrl(
                                  images.first.remoteUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFFF0F0F0),
                                child: const Center(
                                  child: Icon(Icons.image_rounded,
                                      size: 40,
                                      color: AppColors.muted),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF0F0F0),
                              child: const Center(
                                child: Icon(Icons.image_rounded,
                                    size: 40, color: AppColors.muted),
                              ),
                            ),
                )
              else
                Container(
                  height: 100,
                  color: const Color(0xFFF0F0F0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            size: 30,
                            color: AppColors.muted.withValues(alpha: 0.5)),
                        const SizedBox(height: 4),
                        Text(
                          'No photos uploaded',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Text(
                  _descCtrl.text.isNotEmpty
                      ? _descCtrl.text
                      : '(No description)',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_summaryCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _kPurple.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded,
                            size: 14, color: _kPurple),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _summaryCtrl.text,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _kPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_appreciationCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF2E7D32)
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded,
                            size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _appreciationCtrl.text,
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.favorite_border_rounded,
                          size: 16),
                      label: const Text('Appreciate'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.muted),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Share'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ReviewChecklist(
          hasTitle: _titleCtrl.text.trim().isNotEmpty,
          hasMedia:
              _mediaItems.any((m) => m.status == _UploadStatus.success),
          hasDesc: _descCtrl.text.trim().isNotEmpty,
          uploading: _isUploading,
        ),
      ],
    );
  }
}

// ── Helper: input decoration ──────────────────────────────────────────────────

InputDecoration _inputDecoration(String hint, {int maxLines = 1}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppColors.muted.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppColors.muted.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kPurple, width: 1.5),
      ),
    );

// ── Step section title ────────────────────────────────────────────────────────

class _StepSectionTitle extends StatelessWidget {
  const _StepSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _kPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: _kPurple, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  )),
              Text(subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Auto-fill banner when event is linked ─────────────────────────────────────

class _AutoFillBanner extends StatelessWidget {
  const _AutoFillBanner({required this.event});
  final NGOEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_fix_high_rounded,
                  size: 14, color: Color(0xFF2E7D32)),
              SizedBox(width: 6),
              Text(
                'Auto-filled from event',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _AutoChip(Icons.people_rounded,
                  '${event.maxVolunteers} volunteers'),
              _AutoChip(Icons.location_on_rounded, event.location),
              if (event.certificateEligible)
                _AutoChip(Icons.workspace_premium_rounded,
                    'Certificate eligible'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutoChip extends StatelessWidget {
  const _AutoChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              )),
        ],
      ),
    );
  }
}

// ── Image thumbnail grid item ─────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({
    required this.item,
    required this.onSetCover,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
    this.onRetry,
  });
  final _ImpactMedia item;
  final VoidCallback onSetCover;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: item.bytes != null
              ? Image.memory(item.bytes!, fit: BoxFit.cover)
              : item.remoteUrl != null
                  ? Image.network(
                      ApiClient.resolveUrl(item.remoteUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Icon(Icons.broken_image_rounded,
                            color: AppColors.muted),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.muted),
                    ),
        ),
        if (item.status == _UploadStatus.uploading)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        if (item.status == _UploadStatus.failed)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: const Color(0xFFC62828).withValues(alpha: 0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(height: 4),
                  if (onRetry != null)
                    GestureDetector(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Retry',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (item.isCover)
          Positioned(
            top: 5,
            left: 5,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _kPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('COVER',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5)),
            ),
          ),
        if (item.status == _UploadStatus.success && !item.isCover)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!item.isCover)
                  _ThumbBtn(
                    icon: Icons.star_rounded,
                    tooltip: 'Set as cover',
                    onTap: onSetCover,
                  ),
                if (onMoveUp != null)
                  _ThumbBtn(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Move left',
                    onTap: onMoveUp!,
                  ),
                if (onMoveDown != null)
                  _ThumbBtn(
                    icon: Icons.arrow_forward_rounded,
                    tooltip: 'Move right',
                    onTap: onMoveDown!,
                  ),
                _ThumbBtn(
                  icon: Icons.close_rounded,
                  tooltip: 'Remove',
                  onTap: onRemove,
                  destructive: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThumbBtn extends StatelessWidget {
  const _ThumbBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: destructive
                ? const Color(0xFFC62828).withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: Colors.white),
        ),
      ),
    );
  }
}

// ── File list tile for videos / docs ─────────────────────────────────────────

class _FileListTile extends StatelessWidget {
  const _FileListTile(
      {required this.item, required this.onRemove, this.onRetry});
  final _ImpactMedia item;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isOk = item.status == _UploadStatus.success;
    final isFail = item.status == _UploadStatus.failed;
    final isUp = item.status == _UploadStatus.uploading;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFail
              ? const Color(0xFFC62828).withValues(alpha: 0.4)
              : isOk
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
                  : AppColors.muted.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.isVideo
                ? Icons.videocam_rounded
                : Icons.picture_as_pdf_rounded,
            color: isOk
                ? const Color(0xFF2E7D32)
                : isFail
                    ? const Color(0xFFC62828)
                    : AppColors.muted,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOk
                      ? 'Uploaded · ${item.sizeLabel}'
                      : isFail
                          ? item.errorMessage ?? 'Upload failed'
                          : isUp
                              ? 'Uploading…'
                              : item.sizeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isOk
                        ? const Color(0xFF2E7D32)
                        : isFail
                            ? const Color(0xFFC62828)
                            : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (isUp)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPurple),
            )
          else if (isFail && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 30),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ── Review checklist ──────────────────────────────────────────────────────────

class _ReviewChecklist extends StatelessWidget {
  const _ReviewChecklist({
    required this.hasTitle,
    required this.hasMedia,
    required this.hasDesc,
    required this.uploading,
  });
  final bool hasTitle;
  final bool hasMedia;
  final bool hasDesc;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.muted.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to submit?',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          _CheckRow(label: 'Title added', done: hasTitle),
          const SizedBox(height: 6),
          _CheckRow(label: 'Description written', done: hasDesc),
          const SizedBox(height: 6),
          _CheckRow(label: 'Photos uploaded', done: hasMedia),
          const SizedBox(height: 6),
          _CheckRow(
            label: uploading
                ? 'Waiting for uploads to finish…'
                : 'All uploads complete',
            done: !uploading && hasMedia,
            warning: uploading,
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(
      {required this.label, required this.done, this.warning = false});
  final String label;
  final bool done;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? AppColors.accent
        : done
            ? const Color(0xFF2E7D32)
            : AppColors.muted;
    return Row(
      children: [
        Icon(
          warning
              ? Icons.hourglass_top_rounded
              : done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight:
                done || warning ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Post detail bottom sheet ──────────────────────────────────────────────────

class _PostDetailSheet extends StatelessWidget {
  const _PostDetailSheet({required this.post});
  final EMImpactPost post;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.97,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(post.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  ),
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
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                children: [
                  if (post.photoUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          ApiClient.resolveUrl(post.photoUrls.first),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Center(child: Icon(Icons.image_rounded, size: 40, color: AppColors.muted)),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: post.type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: post.type.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(post.type.icon, size: 13, color: post.type.color),
                        const SizedBox(width: 6),
                        Text(post.type.label,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: post.type.color)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(post.description,
                      style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.6)),
                  if (post.appreciationMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.format_quote_rounded, size: 18, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(post.appreciationMessage,
                              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
                                  color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (post.studentsHelped != null || post.hoursServed != null || post.donationRaised != null) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        if (post.studentsHelped != null)
                          _DetailChip(icon: Icons.people_rounded, label: "${post.studentsHelped} helped", color: _kPurple),
                        if (post.hoursServed != null)
                          _DetailChip(icon: Icons.schedule_rounded, label: "${post.hoursServed!.toStringAsFixed(0)} hours", color: AppColors.primary),
                        if (post.donationRaised != null)
                          _DetailChip(icon: Icons.currency_rupee_rounded, label: "\u20b9${post.donationRaised!.toStringAsFixed(0)} raised", color: const Color(0xFF2E7D32)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
