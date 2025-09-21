class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String status;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final bool adminTyping;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.status,
    required this.createdAt,
    this.lastUpdatedAt,
    this.adminTyping = false,
  });
} 