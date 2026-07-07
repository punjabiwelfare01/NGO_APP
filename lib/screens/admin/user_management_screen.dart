import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/api_models.dart';
import '../../viewmodels/admin_viewmodel.dart';
import 'user_approval_detail_screen.dart';

/// Full user management table with search, filter, and actions.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({required this.vm, super.key});

  final AdminViewModel vm;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _filterRole = '';
  String _filterStatus = '';
  bool _loading = false;

  // Drives the collapse/expand of the sticky User (avatar + name) column.
  late final AnimationController _collapseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _collapseAnim = CurvedAnimation(
    parent: _collapseCtrl,
    curve: Curves.easeInOut,
  );
  bool _userColCollapsed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _collapseCtrl.dispose();
    super.dispose();
  }

  void _toggleUserColumn() {
    setState(() => _userColCollapsed = !_userColCollapsed);
    if (_userColCollapsed) {
      _collapseCtrl.forward();
    } else {
      _collapseCtrl.reverse();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    await widget.vm.loadAllUsers(
      search: _searchCtrl.text.trim(),
      role: _filterRole.isEmpty ? null : _filterRole,
      status: _filterStatus.isEmpty ? null : _filterStatus,
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: const Text(
          'User Management',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
            tooltip: 'Refresh',
            onPressed: _fetch,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + filters ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _fetch(),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.muted,
                    ),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              _fetch();
                            },
                          ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                              _Chip(
                                label: 'All',
                                selected:
                                    _filterStatus.isEmpty &&
                                    _filterRole.isEmpty,
                                onTap: () {
                                  setState(() {
                                    _filterStatus = '';
                                    _filterRole = '';
                                  });
                                  _fetch();
                                },
                              ),
                              _Chip(
                                label: 'Pending',
                                color: const Color(0xFFFF8C00),
                                selected: _filterStatus == 'pending',
                                onTap: () {
                                  setState(() {
                                    _filterStatus = 'pending';
                                    _filterRole = '';
                                  });
                                  _fetch();
                                },
                              ),
                              _Chip(
                                label: 'Approved',
                                color: AppColors.secondary,
                                selected: _filterStatus == 'approved',
                                onTap: () {
                                  setState(() {
                                    _filterStatus = 'approved';
                                    _filterRole = '';
                                  });
                                  _fetch();
                                },
                              ),
                              _Chip(
                                label: 'Blocked',
                                color: AppColors.softRed,
                                selected: _filterStatus == 'deactivated',
                                onTap: () {
                                  setState(() {
                                    _filterStatus = 'deactivated';
                                    _filterRole = '';
                                  });
                                  _fetch();
                                },
                              ),
                              _Chip(
                                label: 'Rejected',
                                color: AppColors.muted,
                                selected: _filterStatus == 'rejected',
                                onTap: () {
                                  setState(() {
                                    _filterStatus = 'rejected';
                                    _filterRole = '';
                                  });
                                  _fetch();
                                },
                              ),
                              const SizedBox(width: 12),
                              _Chip(
                                label: 'Students',
                                color: AppColors.primary,
                                selected: _filterRole == 'student',
                                onTap: () {
                                  setState(() {
                                    _filterRole = 'student';
                                    _filterStatus = '';
                                  });
                                  _fetch();
                                },
                              ),
                              _Chip(
                                label: 'Counsellors',
                                color: AppColors.secondary,
                                selected: _filterRole == 'mentor',
                                onTap: () {
                                  setState(() {
                                    _filterRole = 'mentor';
                                    _filterStatus = '';
                                  });
                                  _fetch();
                                },
                              ),
                              _Chip(
                                label: 'Creators',
                                color: AppColors.accent,
                                selected: _filterRole == 'content_creator',
                                onTap: () {
                                  setState(() {
                                    _filterRole = 'content_creator';
                                    _filterStatus = '';
                                  });
                                  _fetch();
                                },
                              ),
                              _Chip(
                                label: 'Admins',
                                color: const Color(0xFF6B48FF),
                                selected: _filterRole == 'admin',
                                onTap: () {
                                  setState(() {
                                    _filterRole = 'admin';
                                    _filterStatus = '';
                                  });
                                  _fetch();
                                },
                              ),
                            ]
                            .map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: w,
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Table ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListenableBuilder(
                    listenable: widget.vm,
                    builder: (_, _) {
                      final users = widget.vm.allUsers;
                      if (users.isEmpty) {
                        return const _EmptyView();
                      }
                      return _UsersTable(
                        users: users,
                        collapseAnim: _collapseAnim,
                        collapsed: _userColCollapsed,
                        onToggleUserColumn: _toggleUserColumn,
                        onView: (u) => _openDetail(u),
                        onBlock: (u) => _block(u),
                        onUnblock: (u) => _unblock(u),
                        onDelete: (u) => _delete(u),
                        onAssign: (u) => _openDetail(u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openDetail(AdminUserItem user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            UserApprovalDetailScreen(userId: user.id, vm: widget.vm),
      ),
    );
  }

  Future<void> _block(AdminUserItem user) async {
    final confirmed = await _confirm(
      title: 'Block ${user.name}?',
      body: '${user.name} will lose access to the platform.',
      confirmLabel: 'Block',
      confirmColor: AppColors.softRed,
    );
    if (!confirmed || !mounted) return;
    final ok = await widget.vm.blockUser(user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? '${user.name} blocked.' : widget.vm.errorMessage ?? 'Failed.',
          ),
          backgroundColor: ok ? AppColors.softRed : Colors.grey,
        ),
      );
    }
  }

  Future<void> _unblock(AdminUserItem user) async {
    final ok = await widget.vm.unblockUser(user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${user.name} unblocked.'
                : widget.vm.errorMessage ?? 'Failed.',
          ),
          backgroundColor: ok ? AppColors.secondary : Colors.grey,
        ),
      );
    }
  }

  Future<void> _delete(AdminUserItem user) async {
    final confirmed = await _confirm(
      title: 'Delete ${user.name}?',
      body: 'This cannot be undone. All user data will be permanently removed.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.softRed,
    );
    if (!confirmed || !mounted) return;
    final ok = await widget.vm.deleteUser(user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? '${user.name} deleted.' : widget.vm.errorMessage ?? 'Failed.',
          ),
          backgroundColor: ok ? AppColors.muted : Colors.grey,
        ),
      );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(body, style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ── Table ─────────────────────────────────────────────────────────────────────
//
// Layout: a narrow sticky left region (row # + avatar/name) that only ever
// scrolls vertically, beside a wide right region (email through actions)
// that scrolls both ways. Two _ScrollSync pairs keep the two vertical lists
// (left/right) and the two horizontal scrollables (header/body) mirrored, so
// the header stays visually locked to its columns while the body scrolls
// sideways, and the sticky column stays visually locked to its row while
// the body scrolls down. Every row uses ListView.builder with a fixed
// itemExtent, so thousands of users stay lazily-built and the two vertical
// lists always report identical scroll extents (exact 1:1 offset mirroring).

const _kIndexColWidth = 40.0;
const _kUserColWidth = 220.0;
const _kStickyWidth = _kIndexColWidth + _kUserColWidth;
const _kRowHeight = 78.0;
const _kHeaderHeight = 44.0;

// Width the sticky column animates down to when the User column is
// collapsed. Kept wide enough (index column + the row's own horizontal
// padding) so the "#" cell always has room, rather than collapsing all
// the way to _kIndexColWidth which would clip it under the cell padding.
const _kCollapsedStickyWidth = _kIndexColWidth + 24.0;

// Fixed layout width given to the avatar+name content so it always renders
// at the same size it did before the column became collapsible; the
// surrounding OverflowBox/ClipRect handle animating how much of it is
// visible, rather than reflowing the content itself.
const _kUserNameContentWidth = _kUserColWidth - 24.0;

double _stickyColumnWidth(double collapseProgress) =>
    _kStickyWidth - (_kStickyWidth - _kCollapsedStickyWidth) * collapseProgress;

// Fixed-width slot (never animates) that holds the collapse/expand chevron,
// sitting right at the edge of the User column, always visible whether the
// column is expanded or collapsed.
const _kToggleColWidth = 28.0;

class _ColSpec {
  const _ColSpec(this.label, this.width);
  final String label;
  final double width;
}

const _kScrollColumns = [
  _ColSpec('Email', 240),
  _ColSpec('Phone', 150),
  _ColSpec('Roles', 220),
  _ColSpec('Location', 140),
  _ColSpec('Status', 120),
  _ColSpec('Registered', 160),
  _ColSpec('Approval', 160),
  _ColSpec('Last Login', 170),
  _ColSpec('Actions', 240),
];

double get _kScrollWidth =>
    _kScrollColumns.fold(0.0, (sum, c) => sum + c.width);

/// Mirrors scroll offset between two controllers, in both directions, so
/// dragging either one moves both (used for the sticky-column / fixed-header
/// table below). Guarded against feedback loops.
class _ScrollSync {
  _ScrollSync() {
    left.addListener(_onLeft);
    right.addListener(_onRight);
  }

  final ScrollController left = ScrollController();
  final ScrollController right = ScrollController();
  bool _guard = false;

  void _onLeft() => _mirror(from: left, to: right);
  void _onRight() => _mirror(from: right, to: left);

  void _mirror({required ScrollController from, required ScrollController to}) {
    if (_guard || !from.hasClients || !to.hasClients) return;
    final target = from.offset.clamp(0.0, to.position.maxScrollExtent);
    if ((to.offset - target).abs() < 0.5) return;
    _guard = true;
    to.jumpTo(target);
    _guard = false;
  }

  void dispose() {
    left.dispose();
    right.dispose();
  }
}

// Small chevron handle anchored at the edge of the User column, used to
// collapse/expand it. Lives in the fixed header (never scrolls away).
class _UserColumnToggle extends StatelessWidget {
  const _UserColumnToggle({required this.collapsed, required this.onTap});

  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kToggleColWidth,
      child: Center(
        child: Tooltip(
          message: collapsed ? 'Show User column' : 'Hide User column',
          child: Material(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersTable extends StatefulWidget {
  const _UsersTable({
    required this.users,
    required this.collapseAnim,
    required this.collapsed,
    required this.onToggleUserColumn,
    required this.onView,
    required this.onBlock,
    required this.onUnblock,
    required this.onDelete,
    required this.onAssign,
  });

  final List<AdminUserItem> users;
  final Animation<double> collapseAnim;
  final bool collapsed;
  final VoidCallback onToggleUserColumn;
  final void Function(AdminUserItem) onView;
  final void Function(AdminUserItem) onBlock;
  final void Function(AdminUserItem) onUnblock;
  final void Function(AdminUserItem) onDelete;
  final void Function(AdminUserItem) onAssign;

  @override
  State<_UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<_UsersTable> {
  // .left = sticky user column, .right = scrollable body (vertical sync).
  final _vSync = _ScrollSync();
  // .left = header row, .right = scrollable body (horizontal sync).
  final _hSync = _ScrollSync();

  @override
  void dispose() {
    _vSync.dispose();
    _hSync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider = Container(width: 1, color: AppColors.muted.withValues(alpha: 0.15));
    return Column(
      children: [
        // ── Fixed header (never scrolls vertically) ──────────────────────
        SizedBox(
          height: _kHeaderHeight,
          child: Container(
            color: const Color(0xFFF0F4FF),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: widget.collapseAnim,
                  builder: (context, child) {
                    final progress = widget.collapseAnim.value;
                    return SizedBox(
                      width: _stickyColumnWidth(progress),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: _kIndexColWidth,
                            child: _HeaderCell('#'),
                          ),
                          Expanded(
                            child: Opacity(
                              opacity: 1 - progress,
                              child: const _HeaderCell('User'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _UserColumnToggle(
                  collapsed: widget.collapsed,
                  onTap: widget.onToggleUserColumn,
                ),
                divider,
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hSync.left,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final col in _kScrollColumns)
                          SizedBox(width: col.width, child: _HeaderCell(col.label)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // ── Body: sticky column (left) + scrollable columns (right) ─────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedBuilder(
                animation: widget.collapseAnim,
                child: ListView.builder(
                  controller: _vSync.left,
                  itemExtent: _kRowHeight,
                  itemCount: widget.users.length,
                  itemBuilder: (_, i) => _StickyUserCell(
                    index: i + 1,
                    user: widget.users[i],
                    onTap: () => widget.onView(widget.users[i]),
                    collapseAnim: widget.collapseAnim,
                  ),
                ),
                builder: (context, child) => SizedBox(
                  width: _stickyColumnWidth(widget.collapseAnim.value),
                  child: child,
                ),
              ),
              // Empty spacer matching the header's toggle-button slot width,
              // so the vertical divider stays aligned between header & body.
              const SizedBox(width: _kToggleColWidth),
              divider,
              Expanded(
                child: Scrollbar(
                  controller: _hSync.right,
                  child: SingleChildScrollView(
                    controller: _hSync.right,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _kScrollWidth,
                      child: ListView.builder(
                        controller: _vSync.right,
                        itemExtent: _kRowHeight,
                        itemCount: widget.users.length,
                        itemBuilder: (_, i) => _ScrollableRowCells(
                          user: widget.users[i],
                          onView: () => widget.onView(widget.users[i]),
                          onBlock: () => widget.onBlock(widget.users[i]),
                          onUnblock: () => widget.onUnblock(widget.users[i]),
                          onDelete: () => widget.onDelete(widget.users[i]),
                          onAssign: () => widget.onAssign(widget.users[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

// ── Sticky left cell: row # + avatar + bold name ────────────────────────────

class _StickyUserCell extends StatelessWidget {
  const _StickyUserCell({
    required this.index,
    required this.user,
    required this.onTap,
    required this.collapseAnim,
  });

  final int index;
  final AdminUserItem user;
  final VoidCallback onTap;
  final Animation<double> collapseAnim;

  @override
  Widget build(BuildContext context) {
    final avatarAndName = Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Tooltip(
            message: user.name,
            child: Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AnimatedBuilder(
          animation: collapseAnim,
          child: avatarAndName,
          builder: (context, child) {
            final progress = collapseAnim.value;
            return Row(
              children: [
                SizedBox(
                  width: _kIndexColWidth,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  // The avatar+name row always lays out at its natural width
                  // (_kUserNameContentWidth) via OverflowBox, regardless of
                  // how little space the shrinking Expanded actually grants
                  // it; ClipRect then hides whatever doesn't fit, so the
                  // collapse never trips a RenderFlex overflow.
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: _kUserNameContentWidth,
                      maxWidth: _kUserNameContentWidth,
                      alignment: Alignment.centerLeft,
                      child: Opacity(
                        opacity: 1 - progress,
                        child: Transform.translate(
                          offset: Offset(-24 * progress, 0),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Scrollable right cells: Email · Phone · Roles · Location · Status ·
//    Registered · Approval · Last Login · Actions ──────────────────────────

class _ScrollableRowCells extends StatelessWidget {
  const _ScrollableRowCells({
    required this.user,
    required this.onView,
    required this.onBlock,
    required this.onUnblock,
    required this.onDelete,
    required this.onAssign,
  });

  final AdminUserItem user;
  final VoidCallback onView;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onDelete;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(user.accessStatus);
    final statusLabel = _statusLabel(user.accessStatus);
    final approvalColor = _approvalColor(user.accessStatus);
    final approvalLabel = _approvalLabel(user.accessStatus);

    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _cell(
            _kScrollColumns[0].width,
            Tooltip(
              message: user.email,
              child: Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
              ),
            ),
          ),
          _cell(
            _kScrollColumns[1].width,
            Text(
              user.phone?.isNotEmpty == true ? user.phone! : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
          _cell(
            _kScrollColumns[2].width,
            _RolesCell(role: user.role, roles: user.roles),
          ),
          _cell(
            _kScrollColumns[3].width,
            Text(
              user.location?.isNotEmpty == true ? user.location! : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
          _cell(_kScrollColumns[4].width, _Badge(label: statusLabel, color: statusColor)),
          _cell(
            _kScrollColumns[5].width,
            Text(
              _fmtDate(user.createdAt),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          _cell(_kScrollColumns[6].width, _Badge(label: approvalLabel, color: approvalColor)),
          _cell(
            _kScrollColumns[7].width,
            Text(
              user.lastLoginAt == null ? 'Never' : _fmtDateTime(user.lastLoginAt!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          _cell(
            _kScrollColumns[8].width,
            _ActionsCell(
              user: user,
              onView: onView,
              onBlock: onBlock,
              onUnblock: onUnblock,
              onDelete: onDelete,
              onAssign: onAssign,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cell(double width, Widget child) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(alignment: Alignment.centerLeft, child: child),
    ),
  );

  static Color _statusColor(String s) => switch (s) {
    'approved' => AppColors.secondary,
    'pending' || 'pending_verification' => const Color(0xFFFF8C00),
    'deactivated' => AppColors.softRed,
    _ => AppColors.muted,
  };

  static String _statusLabel(String s) => switch (s) {
    'approved' => 'Active',
    'pending' || 'pending_verification' => 'Pending',
    'deactivated' => 'Blocked',
    'rejected' => 'Rejected',
    _ => s,
  };

  static Color _approvalColor(String s) => switch (s) {
    'approved' => AppColors.secondary,
    'pending' || 'pending_verification' => const Color(0xFFFF8C00),
    'rejected' => AppColors.softRed,
    'deactivated' => AppColors.softRed,
    _ => AppColors.muted,
  };

  static String _approvalLabel(String s) => switch (s) {
    'approved' => 'Approved',
    'pending' || 'pending_verification' => 'Waiting',
    'rejected' => 'Rejected',
    'deactivated' => 'Blocked',
    _ => s,
  };

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtDateTime(DateTime d) {
    final local = d.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '${_fmtDate(local)}, $h:${local.minute.toString().padLeft(2, '0')} $ampm';
  }
}

// ── Actions cell ──────────────────────────────────────────────────────────────

class _ActionsCell extends StatelessWidget {
  const _ActionsCell({
    required this.user,
    required this.onView,
    required this.onBlock,
    required this.onUnblock,
    required this.onDelete,
    required this.onAssign,
  });

  final AdminUserItem user;
  final VoidCallback onView;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onDelete;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _MiniBtn(
          icon: Icons.visibility_outlined,
          tooltip: 'View',
          color: AppColors.primary,
          onTap: onView,
        ),
        if (user.isPending)
          _MiniBtn(
            icon: Icons.check_circle_outline_rounded,
            tooltip: 'Approve',
            color: AppColors.secondary,
            onTap: onAssign,
          ),
        if (user.isBlocked)
          _MiniBtn(
            icon: Icons.lock_open_rounded,
            tooltip: 'Unblock',
            color: AppColors.secondary,
            onTap: onUnblock,
          )
        else if (!user.isPending)
          _MiniBtn(
            icon: Icons.block_rounded,
            tooltip: 'Block',
            color: AppColors.softRed,
            onTap: onBlock,
          ),
        _MiniBtn(
          icon: Icons.manage_accounts_rounded,
          tooltip: 'Assign Role',
          color: const Color(0xFF6B48FF),
          onTap: onAssign,
        ),
        _MiniBtn(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Delete',
          color: AppColors.muted,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  static final _config = {
    'student': (AppColors.primary, 'Volunteer'),
    'mentor': (AppColors.secondary, 'Counsellor'),
    'content_creator': (AppColors.accent, 'Creator'),
    'event_manager': (const Color(0xFF7C4DFF), 'Event Manager'),
    'support_staff': (const Color(0xFF11B8C9), 'Support Staff'),
    'school_partner': (const Color(0xFF0D47A1), 'School Partner'),
    'admin': (const Color(0xFF6B48FF), 'Admin'),
    'super_admin': (const Color(0xFF6B48FF), 'Super Admin'),
    'guest': (AppColors.muted, 'Guest'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[role] ?? (AppColors.muted, role);
    return _Badge(label: cfg.$2, color: cfg.$1);
  }
}

/// The "Roles" column — shows every role this account is granted (see the
/// multi-role feature) as small badges, primary role first.
class _RolesCell extends StatelessWidget {
  const _RolesCell({required this.role, required this.roles});
  final String role;
  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    final others = roles.where((r) => r != role);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _RoleBadge(role: role),
        ...others.map((r) => _RoleBadge(role: r)),
      ],
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : AppColors.muted.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: AppColors.muted,
            ),
            SizedBox(height: 12),
            Text(
              'No users found yet.',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Registered users will appear here.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
