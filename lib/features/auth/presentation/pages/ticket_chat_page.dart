import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sumi/features/auth/models/support_ticket_model.dart';
import 'package:sumi/features/auth/models/ticket_message_model.dart';
import 'package:sumi/features/auth/services/support_service.dart';
import 'package:flutter/widgets.dart';

class TicketChatPage extends StatefulWidget {
  final SupportTicket ticket;

  const TicketChatPage({super.key, required this.ticket});

  @override
  _TicketChatPageState createState() => _TicketChatPageState();
}

class _TicketChatPageState extends State<TicketChatPage> {
  final _messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, color: const Color(0xFF1D2035)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.ticket.subject,
          style: const TextStyle(
            color: Color(0xFF1D2035),
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        actions: [
          if (widget.ticket.status != 'closed')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GestureDetector(
                onTap: () => _showCloseTicketDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE7EBEF)),
                  ),
                  child: const Icon(Icons.close, color: Color(0xFFAAB9C5), size: 20),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<TicketMessage>>(
              stream: SupportService().getTicketMessages(widget.ticket.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('An error occurred: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد رسائل.'));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _auth.currentUser?.uid;

                    // Logic to show date separator
                    bool showDateSeparator = false;
                    if (index == messages.length - 1) {
                      showDateSeparator = true;
                    } else {
                      final previousMessage = messages[index + 1];
                      if (!isSameDay(message.createdAt, previousMessage.createdAt)) {
                        showDateSeparator = true;
                      }
                    }

                    if (!isMe && !message.isRead) {
                      SupportService().markMessageAsRead(widget.ticket.id, message.id);
                    }

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _buildDateSeparator(message.createdAt),
                        _buildMessageBubble(message, isMe, isRtl),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          StreamBuilder<SupportTicket>(
            stream: SupportService().getTicketStream(widget.ticket.id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.adminTyping) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'الدعم يكتب الآن...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _buildMessageComposer(isRtl),
        ],
      ),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        DateFormat.yMMMMd('ar_SA').format(date),
        style: const TextStyle(
          color: Color(0xFF92A5B5),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(TicketMessage message, bool isMe, bool isRtl) {
    // This ensures user messages are always on the right and support messages on the left.
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    
    final bubbleColor = isMe ? const Color(0xFFFAFAFA) : const Color(0xFF9A46D7);
    final textColor = isMe ? const Color(0xFF2B2F4E) : Colors.white;
    
    // This logic creates the message bubble "tail" correctly for both sides.
    final borderRadius = BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 0 : 16),
            bottomRight: Radius.circular(isMe ? 16 : 0),
          );

    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.message,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(color: textColor, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  DateFormat.jm('ar_SA').format(message.createdAt),
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
                if (isMe && message.isRead) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 16, color: Colors.blueAccent),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(bool isRtl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 32,
            color: const Color(0xff087949).withOpacity(0.08),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _messageController,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  decoration: const InputDecoration(
                    hintText: "اكتب رسالتك هنا..",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                if (_messageController.text.isNotEmpty) {
                  SupportService().sendMessage(
                    widget.ticket.id,
                    _messageController.text,
                  );
                  _messageController.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF9A46D7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseTicketDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          height: 444,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 15, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFE2EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Spacer(),
                Image.asset(
                  'assets/images/chat/close_ticket_illustration.png',
                  height: 119,
                  width: 119,
                ),
                const SizedBox(height: 20),
                const Text(
                  'متأكد من اغلاق تذكرة الدعم!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: Color(0xFF2B2F4E),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'يتم اغلاق التذكرة بشكل نهائي بعد مساعدتك للحفاظ على سرية البيانات ..',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF637D92),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          SupportService().closeTicket(widget.ticket.id);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop(); // Go back from chat page
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9A46D7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(180, 60),
                        ),
                        child: const Text(
                          'اغلاق',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFAAB9C5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                           minimumSize: const Size(180, 60),
                        ),
                        child: const Text(
                          'البقاء',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFFAAB9C5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 