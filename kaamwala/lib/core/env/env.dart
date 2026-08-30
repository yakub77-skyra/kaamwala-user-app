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

  // ---- Payments (Phase 2) ------------------------------------------------
  // 'mock' (default) runs the in-app MockPaymentGateway - no real payment
  // keys needed. Later: 'razorpay'.

  static const String paymentProvider = String.fromEnvironment(
    'KW_PAYMENT_PROVIDER',
    defaultValue: 'mock',
  );

  /// When true (default) mock payment UX is used even if a Razorpay key is
  /// set - the app then simulates payments via the server's mock order path.
  /// Set to false in production once [razorpayKeyId] is configured.
  /// NOTE: the authoritative mock/real decision is made SERVER-SIDE by
  /// create-order (real order only when RZP keys exist there); this flag
  /// only drives the client's demo badge/UX.
  static const bool enableDemoPayment =
      String.fromEnvironment('KW_ENABLE_DEMO_PAYMENT', defaultValue: 'true') ==
      'true';

  /// Whether the client-side payment UX should be mock (demo) mode.
  static bool get useMockPayment =>
      paymentProvider == 'mock' || razorpayKeyId.isEmpty || enableDemoPayment;

  /// Proxy domain that fronts Supabase to bypass ISP DNS blocks (Phase 4 2.2).
  /// Empty => talk to Supabase directly (dev).
  static const String proxyBaseUrl = String.fromEnvironment(
    'KW_PROXY_BASE_URL',
  );

  // ---- SMS / OTP (Phase 1) -------------------------------------------------
  // 'mock' (default) runs the in-app MockSmsGateway - no real SMS API needed.
  // Later: 'msg91', 'twilio', ...

  static const String smsProvider = String.fromEnvironment(
    'KW_SMS_PROVIDER',
    defaultValue: 'mock',
  );

  /// Optional - only needed when [smsProvider] is a real gateway.
  static const String smsApiKey = String.fromEnvironment('KW_SMS_API_KEY');

  /// Optional - e.g. "KMWALA" for MSG91 (DLT sender id).
  static const String smsSenderId = String.fromEnvironment('KW_SMS_SENDER_ID');

  /// When true (default) a mock gateway is used even if a provider key is
  /// set - the app then shows demo/console OTPs. Set to false in production
  /// once [smsApiKey] is configured.
  static const bool enableDemoOtp =
      String.fromEnvironment('KW_ENABLE_DEMO_OTP', defaultValue: 'true') ==
      'true';

  /// Minimal config check for Supabase; SMS never blocks the app (mock default).
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Effective API origin for all REST calls (proxy when configured).
  static String get apiOrigin =>
      proxyBaseUrl.isNotEmpty ? proxyBaseUrl : supabaseUrl;
}
