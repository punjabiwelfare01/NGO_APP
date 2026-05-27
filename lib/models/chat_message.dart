class ChatMessage {
  final int id;
  final int mentorId;
  final int studentId;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as int,
        mentorId: j['mentor_id'] as int,
        studentId: j['student_id'] as int,
        senderId: j['sender_id'] as int,
        senderName: j['sender_name'] as String? ?? 'Unknown',
        senderRole: j['sender_role'] as String? ?? 'student',
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ConversationSummary {
  final int otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int mentorId;
  final int studentId;

  const ConversationSummary({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.mentorId,
    required this.studentId,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> j) =>
      ConversationSummary(
        otherUserId: j['other_user_id'] as int,
        otherUserName: j['other_user_name'] as String,
        otherUserRole: j['other_user_role'] as String,
        lastMessage: j['last_message'] as String,
        lastMessageAt: DateTime.parse(j['last_message_at'] as String),
        mentorId: j['mentor_id'] as int,
        studentId: j['student_id'] as int,
      );
}
