class TicketMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  TicketMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });
} 