/// Onboarding flow state - holds the role + phone chosen before OTP so the
/// screens can share it without stuffing it into a not-yet-created profile.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Intent captured on the role-selection screen.
enum OnboardingRole { client, worker }

class OnboardingState {
  const OnboardingState({this.role, this.phoneE164});

  final OnboardingRole? role;
  final String? phoneE164;

  OnboardingState copyWith({OnboardingRole? role, String? phoneE164}) =>
      OnboardingState(
        role: role ?? this.role,
        phoneE164: phoneE164 ?? this.phoneE164,
      );

  bool get asWorker => role == OnboardingRole.worker;
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void selectRole(OnboardingRole role) {
    state = OnboardingState(role: role);
  }

  void setPhone(String phoneE164) {
    state = state.copyWith(phoneE164: phoneE164);
  }

  void reset() {
    state = const OnboardingState();
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
