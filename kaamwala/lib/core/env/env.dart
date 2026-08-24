/// Runtime configuration via --dart-define.
///
/// Secrets policy (Phase 4 section 8):
///  - Only PUBLIC keys live here (Supabase anon key, Razorpay Key ID).
///  - Razorpay Secret / Service Role / FCM keys NEVER ship in the app -
///    they live exclusively in Supabase Edge Functions.
library;

abstract final class Env {
  // Run with: flutter run --dart-define=KW_SUPABASE_URL=... --dart-define=KW_SUPABASE_ANON_KEY=...
  static const String supabaseUrl = String.fromEnvironment('KW_SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'KW_SUPABASE_ANON_KEY',
  );

  /// Public Razorpay Key ID - safe to embed, required for checkout (Phase 4 5.1).
  static const String razorpayKeyId = String.fromEnvironment(
    'KW_RAZORPAY_KEY_ID',
  );

  /// Proxy domain that fronts Supabase to bypass ISP DNS blocks (Phase 4 2.2).
  /// Empty => talk to Supabase directly (dev).
  static const String proxyBaseUrl = String.fromEnvironment(
    'KW_PROXY_BASE_URL',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Effective API origin for all REST calls (proxy when configured).
  static String get apiOrigin =>
      proxyBaseUrl.isNotEmpty ? proxyBaseUrl : supabaseUrl;
}
