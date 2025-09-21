import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

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
        title: const Text(
          'شروط الاستخدام',
          style: TextStyle(
            color: Color(0xFF1D2035),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSectionTitle('1. قبول الشروط:'),
          _buildSectionContent(
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص مولد النص يمكنك أن تولد مثل هذا النص هذا النص',
          ),
          _buildSectionTitle('2. مسؤوليات المستخدم:'),
          _buildSectionContent(
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص',
          ),
          _buildSectionTitle('3. إدارة الفاتورة:'),
          _buildSectionContent(
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص مولد النص يمكنك أن تولد مثل هذا النص هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة',
          ),
          _buildSectionTitle('4. إنهاء الحجز :'),
          _buildSectionContent(
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص مولد النص يمكنك',
          ),
          _buildSectionTitle('5. حدود المسؤولية:'),
          _buildSectionContent(
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص مولد النص يمكنك أن تولد مثل هذا النص هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة',
          ),
          _buildSectionTitle('6. القانون الحاكم:'),
          _buildSectionContent(
            'تخضع هذه الشروط لقوانين [ولايتك القضائية].\n,سيتم حل أي نزاعات من خلال التحكيم وفقًا لـ [قواعد التحكيم].',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D2035),
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 18,
        color: Color(0xFF1D2035),
        height: 1.5,
      ),
    );
  }
} 