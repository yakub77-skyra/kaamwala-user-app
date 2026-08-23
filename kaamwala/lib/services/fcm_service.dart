/// FCM push notifications wrapper.
///
/// Phase 4 section 6.2: FCM chosen over Expo Push for reliable delivery on
/// budget Android phones. Tokens are stored in the `push_tokens` table
/// (FR-NOTIF-01); actual sending happens ONLY from Edge Functions.
library;

// FCM wiring requires firebase_core + firebase_messaging native setup
// (google-services.json). Kept behind this seam so the rest of the app is
// independent of it. Register/unregister are no-ops until Firebase is added.

abstract final class FcmService {
  /// Returns the current device token, or null when Firebase isn't wired yet.
  static Future<String?> getToken() async => null;

  /// Persists token to push_tokens table (FR-NOTIF-01). No-op pre-Firebase.
  static Future<void> registerToken(String userId, String token) async {}
}
