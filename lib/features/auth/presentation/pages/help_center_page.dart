import 'package:flutter/material.dart';
// removed self import
import 'package:sumi/features/auth/presentation/pages/about_us_page.dart';
import 'package:sumi/features/auth/presentation/pages/faq_page.dart';
import 'package:sumi/features/auth/presentation/pages/privacy_policy_page.dart';
import 'package:sumi/features/auth/presentation/pages/support_tickets_page.dart';
import 'package:sumi/features/auth/presentation/pages/terms_and_conditions_page.dart';
import 'package:sumi/features/auth/services/help_center_service.dart';
import 'package:sumi/features/auth/models/help_center_settings.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:sumi/main.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF3E115A),
            pinned: true,
            expandedHeight: 250.0,
            leading: IconButton(
              icon: Icon(
                isRtl ? Icons.arrow_forward : Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                AppLocalizations.of(context)?.helpCenterTitle ?? 'Help Center',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(
                color: const Color(0xFF3E115A),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)?.helpCenterHowCanWeHelp ?? 'How can we help?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)?.helpCenterSubtitle ?? "Didn't find what you were looking for? Contact our support!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -40.0, 0.0),
              padding:
                  const EdgeInsets.only(top: 50, bottom: 30, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30.0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildHelpButton(
                          text: AppLocalizations.of(context)?.openNewTicket ?? 'Open New Ticket',
                          icon: Icons.messenger_outline,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SupportTicketsPage(),
                              ),
                            );
                          },
                          isPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: _buildHelpButton(
                          text: AppLocalizations.of(context)?.contactUs ?? 'Contact Us',
                          icon: Icons.call_outlined,
                          onPressed: () async {
                            final settings = await HelpCenterService().getSettings();
                            _showContactSheet(context, settings);
                          },
                          isPrimary: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildHelpOption(
                    context,
                    title: AppLocalizations.of(context)?.aboutUs ?? 'About Us',
                    subtitle: AppLocalizations.of(context)?.aboutUsSubtitle ?? "Learn about Sumi's story",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUsPage(),
                        ),
                      );
                    },
                  ),
                  _buildHelpOption(
                    context,
                    title: AppLocalizations.of(context)?.sumiServices ?? 'Sumi Services',
                    subtitle: AppLocalizations.of(context)?.sumiServicesSubtitle ?? 'Various marketing and advertising services',
                    onTap: () {},
                  ),
                  _buildHelpOption(
                    context,
                    title: AppLocalizations.of(context)?.affiliateMarketing ?? 'Affiliate Marketing',
                    subtitle: AppLocalizations.of(context)?.affiliateMarketingSubtitle ?? 'Tell your friend and get rewards',
                    onTap: () {},
                  ),
                  _buildHelpOption(
                    context,
                    title: AppLocalizations.of(context)?.joinUs ?? 'Join Us',
                    subtitle: AppLocalizations.of(context)?.joinUsSubtitle ?? 'Join our team',
                    onTap: () {},
                  ),
                  _buildHelpOption(
                    context,
                    title: AppLocalizations.of(context)?.ourAgents ?? 'Our Agents',
                    subtitle: AppLocalizations.of(context)?.ourAgentsSubtitle ?? 'Find our agents',
                    onTap: () {},
                  ),
                  _buildHelpOption(
                    context,
                    title: AppLocalizations.of(context)?.faq ?? 'FAQ',
                    subtitle: AppLocalizations.of(context)?.faqSubtitle ?? 'Explore services and FAQs',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FaqPage(),
                        ),
                      );
                    },
                  ),
                  _buildHelpOption(
                    context,
                    title: AppLocalizations.of(context)?.privacyPolicy ?? 'Privacy Policy',
                    subtitle: AppLocalizations.of(context)?.privacyPolicySubtitle ?? 'How we collect and use your data',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  _buildHelpOption(
                    context,
                    title: AppLocalizations.of(context)?.termsAndConditions ?? 'Terms and Conditions',
                    subtitle: AppLocalizations.of(context)?.termsAndConditionsSubtitle ?? 'Protecting rights and legal framework',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsAndConditionsPage(),
                        ),
                      );
                    },
                  ),
                  _buildHelpOption(
                    context,
                    title: AppLocalizations.of(context)?.shareApp ?? 'Share App',
                    subtitle: AppLocalizations.of(context)?.shareAppSubtitle ?? 'Tell friends and get rewards',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF9A46D7),
          backgroundColor:
              isPrimary ? const Color(0xFF9A46D7) : const Color(0xFFFAF6FE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption(BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2035),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9DA2A7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.arrow_back_ios_new
                  : Icons.arrow_forward_ios,
              size: 16,
              color: const Color(0xFFC6C8CB),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSheet(BuildContext context, HelpCenterSettings settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _contactRow(
                  context,
                  icon: Icons.mail_outline,
                  label: settings.supportEmail ?? 'support@example.com',
                  onTap: settings.supportEmail == null
                      ? null
                      : () {
                          // Implement email launch
                        },
                ),
                _contactRow(
                  context,
                  icon: Icons.phone_outlined,
                  label: settings.supportPhone ?? '+0000000000',
                  onTap: settings.supportPhone == null ? null : () {},
                ),
                _contactRow(
                  context,
                  icon: Icons.chat_bubble_outline,
                  label: settings.whatsappNumber ?? '-',
                  onTap: settings.whatsappNumber == null ? null : () {},
                ),
                _contactRow(
                  context,
                  icon: Icons.send_outlined,
                  label: settings.telegramLink ?? '-',
                  onTap: settings.telegramLink == null ? null : () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _contactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
} 