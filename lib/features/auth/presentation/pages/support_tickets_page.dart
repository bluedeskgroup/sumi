import 'package:flutter/material.dart';
import 'package:sumi/features/auth/models/support_ticket_model.dart';
import 'package:sumi/features/auth/presentation/pages/create_support_ticket_page.dart';
import 'package:sumi/features/auth/presentation/pages/ticket_chat_page.dart';
import 'package:sumi/features/auth/services/support_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/auth/models/ticket_message_model.dart';
import 'package:sumi/l10n/app_localizations.dart';

class SupportTicketsPage extends StatelessWidget {
  const SupportTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRtl ? Icons.arrow_forward : Icons.arrow_back,
            color: const Color(0xFF1D2035),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)?.supportTicketsTitle ?? 'Support Tickets',
          style: const TextStyle(
            color: Color(0xFF1D2035),
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 18.0),
              child: Text(
                AppLocalizations.of(context)?.supportTicketsHint ?? 'Tickets are available for 24 hours, then they will be closed...',
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Color(0xFF92A5B5),
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
            _buildNewTicketButton(context, isRtl),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<List<SupportTicket>>(
                stream: SupportService().getSupportTickets(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(AppLocalizations.of(context)?.noSupportTickets ?? 'No support tickets.'));
                  }

                  final tickets = snapshot.data!;
                  return ListView.separated(
                    itemCount: tickets.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      return _buildTicketItem(context, tickets[index], isRtl);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTicketButton(BuildContext context, bool isRtl) {
    List<Widget> children = [
      Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFF9A46D7),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Color(0xFFFAF6FE)),
      ),
      const SizedBox(width: 16),
      Text(
        AppLocalizations.of(context)?.openNewTicketTitle ?? 'Open New Ticket',
        style: const TextStyle(
          color: Color(0xFF9A46D7),
          fontFamily: 'Ping AR + LT',
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateSupportTicketPage(),
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: isRtl ? children.reversed.toList() : children,
      ),
    );
  }

  Widget _buildTicketItem(BuildContext context, SupportTicket ticket, bool isRtl) {
    return StreamBuilder<List<TicketMessage>>(
        stream: SupportService().getTicketMessages(ticket.id),
        builder: (context, snapshot) {
          final lastMessage = snapshot.hasData && snapshot.data!.isNotEmpty ? snapshot.data!.last.message : 'No messages yet...';
          final unreadCount = snapshot.hasData ? snapshot.data!.where((m) => !m.isRead && m.senderId != FirebaseAuth.instance.currentUser?.uid).length : 0;

          List<Widget> rowChildren = [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F8F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, color: Color(0xFF7991A4)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      color: Color(0xFF1D2035),
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (unreadCount > 0) ...[
                        Container(
                          width: 25,
                          height: 25,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF75555),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Ping AR + LT',
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          lastMessage,
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4A5E6D),
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketChatPage(ticket: ticket),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isRtl ? rowChildren.reversed.toList() : rowChildren,
            ),
          );
        });
  }
} 