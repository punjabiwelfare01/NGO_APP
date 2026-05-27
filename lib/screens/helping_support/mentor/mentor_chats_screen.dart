import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/chat_message.dart';
import '../../../services/chat_service.dart';
import '../../../viewmodels/view_state.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/top_header.dart';
import '../student/chat_screen.dart';

class MentorChatsScreen extends StatefulWidget {
  const MentorChatsScreen({super.key});

  @override
  State<MentorChatsScreen> createState() => _MentorChatsScreenState();
}

class _MentorChatsScreenState extends State<MentorChatsScreen> {
  ViewState _state = ViewState.loading;
  List<ConversationSummary> _conversations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = ViewState.loading;
      _error = null;
    });
    try {
      final convs = await ChatService.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = convs;
        _state = ViewState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = ViewState.error;
        _error = 'Could not load conversations.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const TopHeader(
              title: 'Student Chats',
              subtitle: 'Your recent conversations with students',
              actionIcon: Icons.chat_rounded,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_state == ViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_state == ViewState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Error',
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No student messages yet.',
                style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: _conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final conv = _conversations[i];
          return _ConversationTile(
            conv: conv,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: conv.otherUserId,
                    otherUserName: conv.otherUserName,
                  ),
                ),
              );
              _load(); // refresh after returning from chat
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conv, required this.onTap});

  final ConversationSummary conv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
              child: Text(
                conv.otherUserName.isNotEmpty
                    ? conv.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.otherUserName,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(conv.lastMessageAt),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conv.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
    }
    return '${dt.day}/${dt.month}';
  }
}
