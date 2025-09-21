import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumi/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:sumi/main.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _setLocale(BuildContext context, String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    // Save language preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    
    // Set locale in MyApp
    if (!mounted) return;
    MyApp.setLocale(context, Locale(languageCode));
    
    // Short delay to allow animation
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Navigate to onboarding page and clear stack
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => const OnboardingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
              ? [Colors.grey.shade900, Colors.black] 
              : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogoSection(),
                    const SizedBox(height: 50),
                    _buildTitleSection(context),
                    const SizedBox(height: 40),
                    _buildLanguageOptions(context),
                    const SizedBox(height: 50),
                    _buildContinueButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Hero(
      tag: 'app_logo',
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Image.asset('assets/images/logo.png', height: 120),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Text(
            AppLocalizations.of(context)!.selectLanguage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOptions(BuildContext context) {
    return Column(
      children: [
        _LanguageCard(
          languageName: "English",
          languageCode: 'en',
          isSelected: _selectedLanguage == 'en',
          flagEmoji: "🇺🇸",
          onTap: () => _setLocale(context, 'en'),
          animationDelay: 0.2,
        ),
        const SizedBox(height: 20),
        _LanguageCard(
          languageName: "العربية",
          languageCode: 'ar',
          isSelected: _selectedLanguage == 'ar',
          flagEmoji: "🇦🇪",
          onTap: () => _setLocale(context, 'ar'),
          animationDelay: 0.4,
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: ElevatedButton(
        onPressed: _selectedLanguage != null 
            ? () => _setLocale(context, _selectedLanguage!) 
            : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Text(
          AppLocalizations.of(context)!.continueButton,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatefulWidget {
  final String languageName;
  final String languageCode;
  final String flagEmoji;
  final bool isSelected;
  final VoidCallback onTap;
  final double animationDelay;

  const _LanguageCard({
    required this.languageName,
    required this.languageCode,
    required this.flagEmoji,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      // Add staggered animation based on card position
      builder: (context, value, child) {
        // Delayed start for each card
        final delayedValue = (value - widget.animationDelay).clamp(0.0, 1.0) / (1.0 - widget.animationDelay.clamp(0.0, 0.99));
        
        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - delayedValue)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovering = true;
            _animationController.forward();
          });
        },
        onExit: (_) {
          setState(() {
            _isHovering = false;
            _animationController.reverse();
          });
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Theme.of(context).colorScheme.primary.withAlpha(38)
                      : (_isHovering 
                          ? Theme.of(context).colorScheme.primary.withAlpha(20)
                          : Theme.of(context).colorScheme.surface),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: widget.isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: _isHovering || widget.isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withAlpha(25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        widget.flagEmoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.languageName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                            color: widget.isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (widget.isSelected) 
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 