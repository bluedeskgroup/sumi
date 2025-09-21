import 'package:flutter/material.dart';
import 'package:sumi/features/auth/models/challenge_model.dart';

class ChallengeCompletedPage extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onReceiveReward;

  const ChallengeCompletedPage({
    super.key,
    required this.challenge,
    required this.onReceiveReward,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Semi-transparent overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1D2035).withOpacity(0.45),
          ),
          // Bottom modal
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, isRtl),
                  _buildContent(isRtl),
                  _buildButton(context, isRtl),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isRtl) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, left: 24, right: 24),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EBEF),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),
          // Close button and title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24), // Spacer for centering
              Text(
                isRtl ? 'هدية' : 'Gift',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D2035),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFFCED7DE),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isRtl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          // Challenge icon
          Container(
            width: 124.53,
            height: 124.41,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/challenges/challenge_completed_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      size: 60,
                      color: Color(0xFF9A46D7),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Congratulations text
          Text(
            isRtl ? 'رائع! أكتمل التحدي' : 'Great! Challenge Completed',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2035),
              height: 1.625,
            ),
          ),
          const SizedBox(height: 16),
          // Challenge description
          Text(
            isRtl 
              ? '${challenge.title} وحصلت على ${challenge.reward} نقطة'
              : '${challenge.title} and earned ${challenge.reward} points',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF637D92),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, bool isRtl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            onReceiveReward();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9A46D7),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            isRtl ? 'استلام الهدية' : 'Receive Gift',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
} 