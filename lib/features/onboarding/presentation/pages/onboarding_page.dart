import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumi/features/onboarding/presentation/pages/onboarding_page_one.dart';
import 'package:sumi/features/onboarding/presentation/pages/onboarding_page_two.dart';
import 'package:sumi/features/onboarding/presentation/pages/onboarding_page_three.dart';
import 'package:sumi/features/auth/presentation/pages/auth_gate.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<Widget> _onboardingPages;

  @override
  void initState() {
    super.initState();
    _onboardingPages = [
      OnboardingPageOne(onNext: _onNext, onSkip: _onSkip),
      OnboardingPageTwo(onNext: _onNext, onSkip: _onSkip),
      OnboardingPageThree(onNext: _completeOnboarding),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onNext() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const ClampingScrollPhysics(),
            children: _onboardingPages,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildPageIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_onboardingPages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6.84,
          width: _currentPage == index ? 36.5 : 6.84,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF9A46D7)
                : const Color(0xFFE6F1FC),
            borderRadius: BorderRadius.circular(57),
          ),
        );
      }),
    );
  }
} 