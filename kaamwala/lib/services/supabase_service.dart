/// Supabase wrapper - single place that knows about Supabase.
/// Screens never call Supabase directly (Phase 2 section 8 architecture rule).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/env/env.dart';

abstract final class SupabaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized || !Env.isConfigured) return;
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    _initialized = true;
  }

  /// Client for repositories. Throws if called before init in unconfigured
  /// builds - repositories guard with [isReady].
  static SupabaseClient get client => Supabase.instance.client;

  static bool get isReady => _initialized;

  static Session? get currentSession =>
      _initialized ? client.auth.currentSession : null;

  static String? get currentUserId =>
      _initialized ? client.auth.currentUser?.id : null;
}
