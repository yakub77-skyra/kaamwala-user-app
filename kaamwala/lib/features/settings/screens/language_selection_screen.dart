/// Language selection screen with Riverpod state management.
/// 
/// Trust UI (Phase 1 Section 6): Multi-language support for Hindi, Marathi, English.
/// Architecture: Uses SharedPreferences to persist user's language choice.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

/// Supported languages.
enum AppLanguage {
  english('English', 'en'),
  hindi('हिंदी', 'hi'),
  marathi('मराठी', 'mr');

  const AppLanguage(this.displayName, this.localeCode);
  final String displayName;
  final String localeCode;

  static AppLanguage fromLocaleCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.localeCode == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Riverpod provider for the current locale.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// Notifier that manages locale state and persistence.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  /// Load saved locale from SharedPreferences.
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('kw_language') ?? 'en';
      state = Locale(savedCode);
    } catch (e) {
      // Default to English on error
      state = const Locale('en');
    }
  }

  /// Set a new locale and save to SharedPreferences.
  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kw_language', locale.languageCode);
      state = locale;
    } catch (e) {
      // Still update state even if save fails
      state = locale;
    }
  }

  /// Get the current AppLanguage enum value.
  AppLanguage get currentLanguage {
    return AppLanguage.fromLocaleCode(state.languageCode);
  }
}

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(KwSpacing.lg),
            decoration: BoxDecoration(
              color: KwColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(KwRadius.md),
              border: Border.all(color: KwColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.translate_rounded,
                  color: KwColors.primary,
                  size: 24,
                ),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Language',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'The app will display in your selected language',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: KwColors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KwSpacing.xl),

          // Language options
          Text(
            'Available Languages',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: KwColors.muted,
                ),
          ),
          const SizedBox(height: KwSpacing.md),

          ...AppLanguage.values.map((language) {
            final isSelected = currentLocale.languageCode == language.localeCode;
            return Padding(
              padding: const EdgeInsets.only(bottom: KwSpacing.md),
              child: _LanguageTile(
                displayName: language.displayName,
                isSelected: isSelected,
                onTap: () {
                  notifier.setLocale(Locale(language.localeCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to ${language.displayName}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            );
          }),

          const SizedBox(height: KwSpacing.xl),

          // Info note
          Container(
            padding: const EdgeInsets.all(KwSpacing.md),
            decoration: BoxDecoration(
              color: KwColors.fill,
              borderRadius: BorderRadius.circular(KwRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: KwColors.muted,
                ),
                const SizedBox(width: KwSpacing.sm),
                Expanded(
                  child: Text(
                    'Some content may still appear in English as translations are being added.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KwColors.muted,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.displayName,
    required this.isSelected,
    required this.onTap,
  });

  final String displayName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KwRadius.md),
      child: Container(
        padding: const EdgeInsets.all(KwSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected 
              ? KwColors.primary.withOpacity(0.05) 
              : KwColors.surface,
          borderRadius: BorderRadius.circular(KwRadius.md),
          border: Border.all(
            color: isSelected ? KwColors.primary : KwColors.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? KwColors.primary : null,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: KwColors.primary,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: KwColors.muted,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
