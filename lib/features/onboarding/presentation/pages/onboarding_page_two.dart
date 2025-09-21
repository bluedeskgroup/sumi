import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumi/l10n/app_localizations.dart';

class OnboardingPageTwo extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const OnboardingPageTwo({
    super.key,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFDF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, right: 24),
                  child: TextButton(
                    onPressed: onSkip,
                    child: Text(
                      localizations.skipButton,
                      style: const TextStyle(
                        color: Color(0xFF9A46D7),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Main Content
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenSize.height - 80,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isSmallScreen ? 20 : 40),
                        // Image
                        SvgPicture.asset(
                          'assets/images/onboarding/onboarding_main_two.svg',
                          width: 300,
                          height: isSmallScreen ? 280 : 320,
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        // Title
                        Text(
                          localizations.onboardingPage2Title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w800,
                            fontSize: isSmallScreen ? 26 : 32,
                            color: const Color(0xFF1D2035),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 16),
                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            localizations.onboardingPage2Description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 16 : 18,
                              color: const Color(0xFF3E115A),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        // Next Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ElevatedButton(
                            onPressed: onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9A46D7),
                              minimumSize: Size(double.infinity, isSmallScreen ? 48 : 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              localizations.nextButton,
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The indicator is now managed by the parent PageView widget
  /*
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(false),
        const SizedBox(width: 4),
        Container(
          width: 36.5,
          height: 6.84,
          decoration: BoxDecoration(
            color: const Color(0xFF9A46D7),
            borderRadius: BorderRadius.circular(57),
          ),
        ),
        const SizedBox(width: 4),
        _buildDot(false),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: 6.84,
      height: 6.84,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF9A46D7) : const Color(0xFFE6F1FC),
        shape: BoxShape.circle,
      ),
    );
  }
  */
} 