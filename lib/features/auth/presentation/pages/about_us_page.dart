import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

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
          'من نحن',
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
          _buildSectionTitle('سومي', isRtl),
          _buildSectionContent(
            'فكرة , شغف ثم هدف . هذا ما قد نصف به منصة سومي , فمنذ اللحظة الأولى لتأسيس سومي كانت الفكرة هي أن تكوم بوابة لأكبر تجمع عصري للخدمات النسائية المميزة , بدأ الشغف في تنفيذ الفكرة فكان الهدف سومي .\n\n'
            'اسم "Somi" يأتي من أصل أفريقي وله عدة معاني في اللغة السواحيلية والزولوية والتشيوا. ومن بين تلك المعاني:\n\n'
            '- العطر الجميل\n'
            '- البساطة والأصالة\n'
            '- الأمل والتفاؤل\n'
            '- الملكية والنبل\n\n'
            'يعد "Somi" أيضًا اسمًا شخصيًا بشائر وجميل يعبر عن روح المرح والحيوية.',
            isRtl,
          ),
          const Divider(height: 32),
          _buildCompanyInfo(isRtl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isRtl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1D2035),
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content, bool isRtl) {
    return Text(
      content,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF465064),
        height: 1.5,
      ),
    );
  }

  Widget _buildCompanyInfo(bool isRtl) {
    return Column(
      crossAxisAlignment:
          isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/about_us/logo.svg',
          height: 84,
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('الشركة', isRtl),
        _buildSectionContent(
            'مؤسسة نطاق العلامة للخدمات التسويقية \nسجل تجاري 1010955078', isRtl),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  const Text('خدمة العملاء :',
                      style: TextStyle(
                          color: Color(0xFF0F315C),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text('0570151550',
                      style: TextStyle(
                          color: Color(0xFF7991A4),
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  const Text('التواصل الإجتماعي :',
                      style: TextStyle(
                          color: Color(0xFF0F315C),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: isRtl ? WrapAlignment.end : WrapAlignment.start,
                    children: [
                      _buildSocialIcon(
                        'assets/images/about_us/facebook.svg',
                        const Color(0xFF1877F2),
                      ),
                      _buildSocialIcon(
                        'assets/images/about_us/twitter.svg',
                        const Color(0xFF1D2035),
                      ),
                      _buildSocialIcon(
                        'assets/images/about_us/linkedin.svg',
                        const Color(0xFF2867B2),
                      ),
                      _buildSocialIcon(
                        'assets/images/about_us/whatsapp.svg',
                        const Color(0xFF25D366),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildSocialIcon(String assetName, Color backgroundColor) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: backgroundColor,
      child: SvgPicture.asset(
        assetName,
        height: 18,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
} 