/// Auth state - Riverpod controller (compile-safe, no BuildContext).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/auth/repositories/auth_repository.dart';
import 'package:kaamwala/models/user_profile.dart';
import 'package:kaamwala/services/supabase_service.dart';

enum AppStage { loading, onboarding, login, roleSelection, clientApp, workerApp }

class AuthState {
  const AuthState({this.stage = AppStage.loading, this.profile});

  final AppStage stage;
  final UserProfile? profile;
}

class AuthController extends Notifier<AuthState> {
  final _repo = const AuthRepository();

  @override
  AuthState build() => const AuthState();

  /// Splash logic - Phase 3 C1: session -> home/dashboard, else onboarding/login.
  Future<void> restoreSession({bool firstRun = false}) async {
    if (!SupabaseService.isReady) {
      // Demo mode without backend config: drop into client app shell.
      state = const AuthState(stage: AppStage.clientApp);
      return;
    }
    final session = SupabaseService.currentSession;
    if (session == null) {
      state = AuthState(
        stage: firstRun ? AppStage.onboarding : AppStage.login,
      );
      return;
    }
    final result = await _repo.fetchMyProfile();
    final profile = switch (result) {
      Success(:final data) => data,
      _ => null,
    };
    if (profile == null || profile.name.isEmpty) {
      state = AuthState(stage: AppStage.roleSelection, profile: profile);
    } else {
      state = AuthState(stage: profile.role == UserRole.worker ? AppStage.workerApp : AppStage.clientApp, profile: profile);
    }
  }

  Future<void> finishRoleSelection({
    required String name,
    required bool asWorker,
    required String city,
  }) async {
    final result = await _repo.completeOnboarding(
      name: name,
      role: asWorker ? UserRole.worker : UserRole.client,
      city: city,
    );
    state = switch (result) {
      Success(:final data) => AuthState(
          stage:
              asWorker ? AppStage.workerApp : AppStage.clientApp,
          profile: data,
        ),
      _ => AuthState(
          stage: AppStage.roleSelection,
          profile: state.profile,
        ),
    };
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(stage: AppStage.login);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
