import 'package:flutter/material.dart';
import 'package:sumi/features/auth/services/support_service.dart';
import 'package:sumi/l10n/app_localizations.dart';

class CreateSupportTicketPage extends StatefulWidget {
  const CreateSupportTicketPage({super.key});

  @override
  _CreateSupportTicketPageState createState() =>
      _CreateSupportTicketPageState();
}

class _CreateSupportTicketPageState extends State<CreateSupportTicketPage> {
  final _formKey = GlobalKey<FormState>();
  String _subject = '';
  String _message = '';

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
          AppLocalizations.of(context)?.openNewTicketTitle ?? 'Open New Ticket',
          style: const TextStyle(
            color: Color(0xFF1D2035),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.ticketSubject ?? 'Subject',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)?.ticketSubjectRequired ?? 'Please enter the subject';
                  }
                  return null;
                },
                onSaved: (value) {
                  _subject = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.ticketMessage ?? 'Message',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)?.ticketMessageRequired ?? 'Please enter the message';
                  }
                  return null;
                },
                onSaved: (value) {
                  _message = value!;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    SupportService().createSupportTicket(_subject, _message);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A46D7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  AppLocalizations.of(context)?.send ?? 'Send',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 