/// Support screen with help options.
/// 
/// Trust UI (Phase 1 Section 6): Easy access to support builds user confidence.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(KwSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: KwColors.brandGradient,
              ),
              borderRadius: BorderRadius.circular(KwRadius.lg),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: KwSpacing.md),
                Text(
                  'We\'re Here to Help',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: KwSpacing.sm),
                Text(
                  'Choose how you\'d like to contact us',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: KwSpacing.xl),

          // Support options
          _SupportOption(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: KwColors.primary,
            title: 'Report an Issue',
            subtitle: 'Tell us what went wrong',
            onTap: () => _showComingSoon(context, 'Issue reporting'),
          ),
          const SizedBox(height: KwSpacing.md),
          
          _SupportOption(
            icon: Icons.payment_outlined,
            iconColor: KwColors.green,
            title: 'Payment Help',
            subtitle: 'Refunds, failed payments, billing',
            onTap: () => _showComingSoon(context, 'Payment support'),
          ),
          const SizedBox(height: KwSpacing.md),
          
          _SupportOption(
            icon: Icons.phone_in_talk_outlined,
            iconColor: KwColors.orange,
            title: 'Call Support',
            subtitle: 'Speak to our team directly',
            onTap: () => _launchPhone(),
          ),
          const SizedBox(height: KwSpacing.md),
          
          _SupportOption(
            icon: Icons.message_outlined,
            iconColor: KwColors.teal,
            title: 'WhatsApp Support',
            subtitle: 'Chat with us on WhatsApp',
            onTap: () => _launchWhatsApp(),
          ),
          const SizedBox(height: KwSpacing.md),
          
          _SupportOption(
            icon: Icons.email_outlined,
            iconColor: KwColors.purple,
            title: 'Email Support',
            subtitle: 'Send us detailed information',
            onTap: () => _launchEmail(),
          ),
          const SizedBox(height: KwSpacing.md),
          
          _SupportOption(
            icon: Icons.description_outlined,
            iconColor: KwColors.muted,
            title: 'FAQs',
            subtitle: 'Frequently asked questions',
            onTap: () => _showComingSoon(context, 'FAQs'),
          ),
          const SizedBox(height: KwSpacing.xl),

          // Contact info footer
          Container(
            padding: const EdgeInsets.all(KwSpacing.lg),
            decoration: BoxDecoration(
              color: KwColors.fill,
              borderRadius: BorderRadius.circular(KwRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Other Ways to Reach Us',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: KwSpacing.md),
                _ContactRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'support@kaamwala.com',
                ),
                const SizedBox(height: KwSpacing.sm),
                _ContactRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: '+91 98765 43210',
                ),
                const SizedBox(height: KwSpacing.sm),
                _ContactRow(
                  icon: Icons.access_time_rounded,
                  label: 'Support Hours',
                  value: '9 AM - 6 PM (Mon-Sat)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/919876543210?text=Hi%20KaamWala%20Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:support@kaamwala.com?subject=Support%20Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SupportOption extends StatelessWidget {
  const _SupportOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KwRadius.md),
      child: Container(
        padding: const EdgeInsets.all(KwSpacing.lg),
        decoration: BoxDecoration(
          color: KwColors.surface,
          borderRadius: BorderRadius.circular(KwRadius.md),
          border: Border.all(color: KwColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(KwRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: KwSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KwColors.muted,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: KwColors.muted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KwColors.muted),
        const SizedBox(width: KwSpacing.sm),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: KwColors.muted,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
