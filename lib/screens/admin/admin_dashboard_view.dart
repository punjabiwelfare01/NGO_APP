import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/api_models.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/section_header.dart';
import '../events/admin/event_manager_screen.dart';
import '../helping_support/admin/counselling_admin_screen.dart';
import '../helping_support/admin/emergency_contacts_admin_screen.dart';
import '../home/admin/safety_awareness_manager_screen.dart';
import 'pending_approvals_screen.dart';
import 'user_approval_detail_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late final AdminViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AdminViewModel();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminName = (AppState.studentName ?? 'Admin').split(' ').first;
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return AppScrollView(
          children: [
            // ── Header ──────────────────────────────────────────────
            _AdminHeader(
              name: adminName,
              role: AppState.role.displayName,
              unreadCount: _vm.unreadCount,
              onBellTap: () => _openNotifications(),
            ),

            // ── Stats row ────────────────────────────────────────────
            _StatsRow(
              pendingCount: _vm.pendingCount,
              unreadCount: _vm.unreadCount,
              onPendingTap: _openPendingApprovals,
              onNotificationTap: _openNotifications,
            ),

            // ── User statistics ──────────────────────────────────────
            _UserStatsCard(
              stats: _vm.stats,
              onTap: _openUserManagement,
            ),

            // ── Pending approvals ────────────────────────────────────
            if (_vm.pendingCount > 0) ...[
              SectionHeader(
                title: 'Pending Approvals',
                action: 'View all',
                onTap: _openPendingApprovals,
              ),
              if (_vm.state == ViewState.loading)
                const _LoadingCard()
              else
                ..._vm.pendingUsers
                    .take(3)
                    .map((u) => _PendingUserRow(
                          user: u,
                          onTap: () => _openDetail(u),
                        )),
              if (_vm.pendingUsers.length > 3)
                _ViewAllButton(
                  label: 'View all ${_vm.pendingCount} pending requests',
                  onTap: _openPendingApprovals,
                ),
            ],

            // ── Recent notifications ─────────────────────────────────
            if (_vm.notifications.isNotEmpty) ...[
              SectionHeader(
                title: 'Recent Notifications',
                action: _vm.unreadCount > 0 ? 'Mark all read' : null,
                onTap: _vm.markAllRead,
              ),
              ..._vm.notifications
                  .take(4)
                  .map((n) => _NotificationRow(
                        notification: n,
                        onTap: () => _vm.markNotificationRead(n.id),
                      )),
            ],

            // ── Management tools ─────────────────────────────────────
            const SectionHeader(title: 'Management Tools'),
            _ToolsGrid(
              tools: [
                _AdminTool(
                  icon: Icons.pending_actions_rounded,
                  label: 'User Approvals',
                  subtitle: '${_vm.pendingCount} pending',
                  color: const Color(0xFFFF8C00),
                  onTap: _openPendingApprovals,
                ),
                _AdminTool(
                  icon: Icons.manage_accounts_rounded,
                  label: 'User Management',
                  subtitle: '${_vm.stats.totalUsers} total users',
                  color: AppColors.primary,
                  onTap: _openUserManagement,
                ),
                _AdminTool(
                  icon: Icons.event_rounded,
                  label: 'Event Manager',
                  subtitle: 'Create & manage events',
                  color: AppColors.secondary,
                  onTap: () => _push(const EventManagerScreen()),
                ),
                _AdminTool(
                  icon: Icons.psychology_outlined,
                  label: 'Counselling',
                  subtitle: 'Sessions & schedules',
                  color: const Color(0xFF009688),
                  onTap: () => _push(const CounsellingAdminScreen()),
                ),
                _AdminTool(
                  icon: Icons.shield_rounded,
                  label: 'Safety Awareness',
                  subtitle: 'Stories & questions',
                  color: AppColors.softRed,
                  onTap: () => _push(const SafetyAwarenessManagerScreen()),
                ),
                _AdminTool(
                  icon: Icons.contact_phone_rounded,
                  label: 'Emergency Contacts',
                  subtitle: 'Manage helplines',
                  color: const Color(0xFF6B48FF),
                  onTap: () => _push(const EmergencyContactsAdminScreen()),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openUserManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserManagementScreen(vm: _vm),
      ),
    );
  }

  void _openPendingApprovals() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PendingApprovalsScreen()),
    );
  }

  void _openDetail(PendingUserItem user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserApprovalDetailScreen(userId: user.id, vm: _vm),
      ),
    );
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(vm: _vm),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.name,
    required this.role,
    required this.unreadCount,
    required this.onBellTap,
  });

  final String name;
  final String role;
  final int unreadCount;
  final VoidCallback onBellTap;

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
                'Hi $name',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              onPressed: onBellTap,
              icon: const Icon(Icons.notifications_rounded),
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.pendingCount,
    required this.unreadCount,
    required this.onPendingTap,
    required this.onNotificationTap,
  });

  final int pendingCount;
  final int unreadCount;
  final VoidCallback onPendingTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Pending\nApprovals',
            value: '$pendingCount',
            color: const Color(0xFFFF8C00),
            onTap: onPendingTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.notifications_active_rounded,
            label: 'Unread\nNotifications',
            value: '$unreadCount',
            color: AppColors.secondary,
            onTap: onNotificationTap,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
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
}

class _PendingUserRow extends StatelessWidget {
  const _PendingUserRow({required this.user, required this.onTap});

  final PendingUserItem user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final requestedRole = user.requestedRole;
    final roleColor = switch (requestedRole) {
      'mentor'           => AppColors.secondary,
      'content_creator'  => AppColors.accent,
      _                  => AppColors.primary,
    };
    final roleLabel = switch (requestedRole) {
      'mentor'           => 'Mentor',
      'content_creator'  => 'Content Creator',
      _                  => 'Student',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.onTap,
  });

  final AdminNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.muted.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.isRead
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_active_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                        color: AppColors.ink,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 42),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ToolsGrid extends StatelessWidget {
  const _ToolsGrid({required this.tools});

  final List<_AdminTool> tools;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: tools,
    );
  }
}

class _AdminTool extends StatelessWidget {
  const _AdminTool({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

// ── User stats card ───────────────────────────────────────────────────────────

class _UserStatsCard extends StatelessWidget {
  const _UserStatsCard({required this.stats, required this.onTap});

  final AdminStats   stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'User Statistics',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total',
                    value: stats.totalUsers,
                    color: AppColors.ink,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Active',
                    value: stats.activeUsers,
                    color: AppColors.secondary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Pending',
                    value: stats.pendingUsers,
                    color: const Color(0xFFFF8C00),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Blocked',
                    value: stats.blockedUsers,
                    color: AppColors.softRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int    value;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Notifications bottom sheet ────────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.vm});

  final AdminViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  if (vm.unreadCount > 0)
                    TextButton(
                      onPressed: vm.markAllRead,
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListenableBuilder(
                listenable: vm,
                builder: (_, _) {
                  final notes = vm.notifications;
                  if (notes.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    itemBuilder: (_, i) => _NotificationRow(
                      notification: notes[i],
                      onTap: () => vm.markNotificationRead(notes[i].id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
