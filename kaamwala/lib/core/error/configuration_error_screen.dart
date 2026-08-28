/// Configuration error screen shown when app is misconfigured.
/// 
/// This screen appears when:
/// - App is built for production (KW_DEMO_MODE=false)
/// - But Supabase keys are missing from environment
library;

import 'package:flutter/material.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_button.dart';

class ConfigurationErrorScreen extends StatelessWidget {
  const ConfigurationErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KwSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: KwColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(KwRadius.lg),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: KwColors.red,
                    ),
                  ),
                  const SizedBox(height: KwSpacing.lg),
                  
                  // Title
                  Text(
                    'Configuration Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KwSpacing.sm),
                  
                  // Message
                  Text(
                    'App configuration missing.\n\n'
                    'Please contact support or rebuild with valid environment settings.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: KwColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KwSpacing.xl),
                  
                  // Help button
                  KwButton(
                    label: 'Contact Support',
                    onPressed: () {
                      // TODO: Open support screen or WhatsApp link
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Support contact coming soon'),
                        ),
                      );
                    },
                    icon: Icons.support_agent_rounded,
                  ),
                  const SizedBox(height: KwSpacing.md),
                  
                  // Retry button
                  KwButton(
                    label: 'Retry',
                    onPressed: () {
                      // Trigger a reload attempt
                      // In real implementation, this might re-check env vars
                    },
                    variant: KwButtonVariant.secondary,
                    icon: Icons.refresh_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
