import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumi/l10n/app_localizations.dart';

class OnboardingPageThree extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingPageThree({
    super.key,
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
            colors: [Color(0xFFCEDEEF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenSize.height - 60,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 40 : 60),
                  // Image
                  SvgPicture.asset(
                    'assets/images/onboarding/onboarding_main_three.svg',
                    width: 300,
                    height: isSmallScreen ? 280 : 320,
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  // Title
                  Text(
                    localizations.onboardingPage3Title,
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
                      localizations.onboardingPage3Description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 16 : 18,
                        color: const Color(0xFF3E115A),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 30 : 50),
                  // Start Button
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
                        localizations.startButton,
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 40 : 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 