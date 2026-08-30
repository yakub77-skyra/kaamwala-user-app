/// Auth state - Riverpod controller (compile-safe, no BuildContext).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/auth/repositories/auth_repository.dart';
import 'package:kaamwala/models/user_profile.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/fcm_service.dart';
import 'package:kaamwala/services/supabase_service.dart';

enum AppStage {
  loading,
  startupError,
  onboarding,
  roleSelection,
  phoneEntry,
  otpVerification,
  clientApp,
  workerApp,
}

class AuthState {
  const AuthState({this.stage = AppStage.loading, this.profile});

  final AppStage stage;
  final UserProfile? profile;
}

class AuthController extends Notifier<AuthState> {
  final _repo = const AuthRepository();

  @override
  AuthState build() => const AuthState();

  /// Splash logic - Phase 3 C1: session -> home/dashboard, else onboarding/role.
  /// Network/server failures during restore land on [AppStage.startupError]
  /// (splash offers a retry) instead of silently dumping the user to login.
  Future<void> restoreSession({bool firstRun = false}) async {
    state = const AuthState();
    if (!SupabaseService.isReady) {
      // Demo mode without backend config: drop into client app shell.
      state = const AuthState(stage: AppStage.clientApp);
      return;
    }
    final session = SupabaseService.currentSession;
    if (session == null) {
      state = AuthState(
        stage: firstRun ? AppStage.onboarding : AppStage.roleSelection,
      );
      return;
    }
    final result = await _repo.fetchMyProfile();
    final UserProfile? profile;
    switch (result) {
      case Success(:final data):
        profile = data;
      case Error(:final failure)
          when failure is NetworkFailure || failure is ServerFailure:
        state = const AuthState(stage: AppStage.startupError);
        return;
      case Error():
        // Auth/other failure - treat like a missing profile (re-auth flow).
        profile = null;
    }
    if (profile == null || profile.name.isEmpty) {
      state = AuthState(stage: AppStage.roleSelection, profile: profile);
    } else {
      state = AuthState(
        stage: profile.role == UserRole.worker
            ? AppStage.workerApp
            : AppStage.clientApp,
        profile: profile,
      );
    }
    unawaited(_registerPushToken());
  }

  /// Best-effort FCM token registration (FR-NOTIF-01). No-op until Firebase
  /// is configured; never blocks or fails login.
  Future<void> _registerPushToken() async {
    try {
      final uid = SupabaseService.currentUserId;
      if (uid == null) return;
      await FcmService.ensureInitialized();
      final token = await FcmService.getToken();
      if (token == null) return;
      await FcmService.registerToken(uid, token);
    } on Exception catch (_) {}
  }

  /// After OTP verification - routes by profile completeness (FR-AUTH-05):
  /// no profile / unnamed -> role selection, else straight into the app shell
  /// (router redirect picks up the stage change).
  void authenticatedAs(UserProfile? profile) {
    if (profile == null || profile.name.isEmpty) {
      state = AuthState(stage: AppStage.roleSelection, profile: profile);
    } else {
      state = AuthState(
        stage: profile.role == UserRole.worker
            ? AppStage.workerApp
            : AppStage.clientApp,
        profile: profile,
      );
    }
    unawaited(_registerPushToken());
  }

  /// Returns true when onboarding completed; false surfaces an error snackbar.
  /// In mock/demo mode (no backend), this degrades gracefully: it builds a
  /// synthetic in-memory profile so the app remains navigable.
  Future<bool> finishRoleSelection({
    required String name,
    required bool asWorker,
    required String city,
  }) async {
    // Mock path when there is no real session (app not configured OR the
    // mock SMS flow verified without Supabase Auth). Degrades gracefully: it
    // builds a synthetic in-memory profile so the app remains navigable.
    final hasSession =
        SupabaseService.isReady && SupabaseService.currentSession != null;
    if (!hasSession) {
      final uid = SupabaseService.currentUserId ?? 'mock-user';
      final profile = UserProfile(
        id: uid,
        phone: state.profile?.phone ?? '',
        name: name,
        role: asWorker ? UserRole.worker : UserRole.client,
        city: city,
      );
      state = AuthState(
        stage: asWorker ? AppStage.workerApp : AppStage.clientApp,
        profile: profile,
      );
      unawaited(AnalyticsService.setUserRole(asWorker ? 'worker' : 'client'));
      unawaited(
        AnalyticsService.logEvent('onboarding_completed', {
          'role': asWorker ? 'worker' : 'client',
        }),
      );
      return true;
    }
    final result = await _repo.completeOnboarding(
      name: name,
      role: asWorker ? UserRole.worker : UserRole.client,
      city: city,
    );
    if (result is Success<UserProfile>) {
      state = AuthState(
        stage: asWorker ? AppStage.workerApp : AppStage.clientApp,
        profile: result.data,
      );
      unawaited(_registerPushToken());
      unawaited(AnalyticsService.setUserRole(asWorker ? 'worker' : 'client'));
      unawaited(
        AnalyticsService.logEvent('onboarding_completed', {
          'role': asWorker ? 'worker' : 'client',
        }),
      );
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    // Clear session-derived profile so a fresh start re-enters choose-role flow.
    state = const AuthState(stage: AppStage.roleSelection, profile: null);
  }

  /// Avatar upload -> refreshes in-memory profile (FR-PROFILE-02).
  /// Returns false on failure; UI shows a friendly message.
  Future<bool> updateAvatar(Uint8List bytes) async {
    final result = await _repo.uploadAvatar(bytes);
    if (result is Success<UserProfile>) {
      state = AuthState(stage: state.stage, profile: result.data);
      return true;
    }
    return false;
  }

  /// Edit name/city from Settings. Returns null on success, else an error
  /// message for the UI.
  Future<String?> updateDetails({String? name, String? city}) async {
    final result = await _repo.updateDetails(name: name, city: city);
    switch (result) {
      case Success(:final data):
        state = AuthState(stage: state.stage, profile: data);
        return null;
      case Error(:final failure):
        return failure.message;
    }
  }

  /// Called when user selects a role (customer/worker) on the role selection screen.
  /// Transitions to phone entry stage with the selected role.
  void selectRole(bool asWorker) {
    state = AuthState(stage: AppStage.phoneEntry, profile: state.profile);
    // Store the selected role in profile for later use
    if (state.profile != null) {
      // We'll use a temporary approach - store role in a way the phone entry screen can use
    }
    unawaited(
      AnalyticsService.logEvent('role_selected', {
        'role': asWorker ? 'worker' : 'client',
      }),
    );
  }

  /// Called when user enters a valid phone number and requests OTP.
  /// Transitions to OTP verification stage.
  void startOtpVerification(String phoneE164) {
    state = AuthState(stage: AppStage.otpVerification, profile: state.profile);
    unawaited(AnalyticsService.logEvent('otp_requested', {'phone': phoneE164}));
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
