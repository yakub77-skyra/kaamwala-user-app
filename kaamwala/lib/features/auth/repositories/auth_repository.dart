/// Auth repository - phone OTP via Supabase Auth (FR-AUTH-01..05).
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/models/user_profile.dart';
import 'package:kaamwala/services/supabase_service.dart';

class AuthRepository {
  const AuthRepository();

  /// Sends SMS OTP. Returns failure on error (never throws raw exceptions).
  Future<Result<void>> sendOtp(String phoneE164) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client.auth.signInWithOtp(phone: phoneE164);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Verifies the 6-digit code. On success ensures a profiles row exists
  /// (role assigned later at Role Selection - FR-AUTH-05).
  Future<Result<UserProfile?>> verifyOtp(String phoneE164, String code) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      final res = await SupabaseService.client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phoneE164,
        token: code,
      );
      final user = res.user;
      if (user == null) return const Success(null);
      final profile = await _ensureProfile(user.id, phoneE164);
      return Success(profile);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<UserProfile?>> fetchMyProfile() async {
    if (!SupabaseService.isReady) return const Success(null);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Success(null);
    try {
      final row = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return const Success(null);
      return Success(UserProfile.fromMap(row));
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Sets the locked role - one phone number = one role (Phase 2 section 2).
  Future<Result<UserProfile>> completeOnboarding({
    required String name,
    required UserRole role,
    required String city,
  }) async {
    if (!SupabaseService.isReady) {
      return Error(const ServerFailure('Backend not configured'));
    }
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Error(AuthFailure());
    try {
      final updated = await SupabaseService.client
          .from('users')
          .update({'name': name, 'role': role.name, 'city': city})
          .eq('id', uid)
          .select()
          .single();
      return Success(UserProfile.fromMap(updated));
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<void>> signOut() async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client.auth.signOut();
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Uploads a compressed avatar to the PUBLIC profiles bucket under my own
  /// folder (storage RLS: first path segment must be my uid), then persists
  /// the public URL on users.photo_url.
  Future<Result<UserProfile>> uploadAvatar(Uint8List bytes) async {
    if (!SupabaseService.isReady) {
      return Error(const ServerFailure('Backend not configured'));
    }
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Error(AuthFailure());
    try {
      final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SupabaseService.client.storage
          .from('profiles')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = SupabaseService.client.storage
          .from('profiles')
          .getPublicUrl(path);
      final updated = await SupabaseService.client
          .from('users')
          .update({'photo_url': publicUrl})
          .eq('id', uid)
          .select()
          .single();
      return Success(UserProfile.fromMap(updated));
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<UserProfile> _ensureProfile(String uid, String phone) async {
    final client = SupabaseService.client;
    final existing = await client
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (existing != null) return UserProfile.fromMap(existing);
    final created = await client
        .from('users')
        .insert({'id': uid, 'phone': phone})
        .select()
        .single();
    return UserProfile.fromMap(created);
  }
}
