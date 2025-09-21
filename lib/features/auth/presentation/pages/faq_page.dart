import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

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
          'الاسئلة الشائعة',
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
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildFaqItem(
            'ما هو هذا التطبيق التطبيق ؟',
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة...',
          ),
          _buildFaqItem(
            'كيف يمكنني الاستفاده من التطبيق؟',
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص مولد النص يمكنك أن تولد مثل هذا النص هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص مولد النص يمكنك أن تولد مثل هذا النص هذا النص ..',
            isExpanded: true,
          ),
          _buildFaqItem(
            'هل يضاف مصاريف اضافيه عند الحجز ؟',
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة...',
          ),
          _buildFaqItem(
            'عند الغاء الحجز هل يرجع فى حسابي كامل المبلغ المدفوع؟',
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة...',
          ),
          _buildFaqItem(
            'كيف يتم التعامل مع بياناتي ؟',
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة...',
          ),
          _buildFaqItem(
            'ازاي ممكن اغير بياناتي فى التطبيق ؟',
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة...',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBEF)),
      ),
      child: const TextField(
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحث عن سؤالك',
          hintStyle: TextStyle(color: Color(0xFFCED7DE)),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Color(0xFF4A5E6D)),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer,
      {bool isExpanded = false}) {
    return ExpansionTile(
      initiallyExpanded: isExpanded,
      title: Text(
        question,
        style: TextStyle(
          fontWeight: isExpanded ? FontWeight.w800 : FontWeight.w500,
          color: const Color(0xFF1D2035),
        ),
      ),
      trailing: Icon(
        isExpanded ? Icons.remove : Icons.add,
        color: const Color(0xFF9A46D7),
      ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            answer,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF465064),
              height: 1.5,
            ),
          ),
        ),
      ],
      onExpansionChanged: (bool expanded) {
        // We can use a StatefulWidget to manage the state of each ExpansionTile
        // but for this example, we'll just print the state.
      },
    );
  }
} 