/// Pure phone-number helpers (India, +91 default).
///
/// No Flutter imports: usable from screens and unit tests alike.
library;

/// Strips everything except digits (allows leading `91` country code).
String onlyDigits(String input) => input.replaceAll(RegExp(r'[^\d]'), '');

/// Validates a 10-digit Indian mobile (optionally typed with a leading `91`
/// country code, spaces, dashes, or a `+` prefix). Non-numeric garbage
/// (letters etc.) is rejected.
bool isValidIndianMobile(String input) {
  final cleaned = input.replaceAll(RegExp(r'[+\s\-()]'), '');
  if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;
  final digits = onlyDigits(cleaned);
  if (digits.length == 10) return true;
  return digits.startsWith('91') && digits.length == 12;
}

/// Normalizes any accepted Indian phone entry to E.164 (+91XXXXXXXXXX).
///
/// Examples: '9876543210' -> '+919876543210', '919876543210' -> '+919876543210',
/// '+91 98765 43210' -> '+919876543210'.
String normalizePhoneE164(String input) {
  final digits = onlyDigits(input);
  if (digits.startsWith('91') && digits.length == 12) return '+$digits';
  return '+91$digits';
}

/// Masks an E.164 number for display: '+91 ••••• 3210'.
String maskPhoneE164(String phoneE164) {
  if (phoneE164.length < 10) return phoneE164;
  final last4 = phoneE164.substring(phoneE164.length - 4);
  return '+91 ••••• $last4';
}

/// Title-case a city name: 'mumbai' -> 'Mumbai', '  pUNE ' -> 'Pune'.
String normalizeCity(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final words = trimmed.split(RegExp(r'\s+'));
  return words
      .map(
        (w) =>
            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
      )
      .join(' ');
}
