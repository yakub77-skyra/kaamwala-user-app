/// Worker-side repository (FR-WORKER-01..10).
library;

import 'dart:typed_data';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/models/booking.dart';
import 'package:kaamwala/services/supabase_service.dart';

class WorkerRegistrationData {
  String name = '';
  String city = '';
  String category = '';
  int priceMin = 300;
  Uint8List? aadharFrontBytes;
  Uint8List? aadharBackBytes;
}

class WorkerRepository {
  const WorkerRepository();

  /// Step 3 submit: uploads Aadhar to PRIVATE bucket then inserts row with
  /// approval_status=pending (FR-WORKER-01 / NFR-SEC-05).
  Future<Result<void>> submitRegistration(WorkerRegistrationData d) async {
    if (!SupabaseService.isReady) return const Success(null);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Error(AuthFailure());
    try {
      String? frontUrl;
      String? backUrl;
      final bucket = SupabaseService.client.storage.from('aadhar_scans');
      if (d.aadharFrontBytes != null) {
        await bucket.uploadBinary('$uid/front.jpg', d.aadharFrontBytes!);
        frontUrl = '$uid/front.jpg';
      }
      if (d.aadharBackBytes != null) {
        await bucket.uploadBinary('$uid/back.jpg', d.aadharBackBytes!);
        backUrl = '$uid/back.jpg';
      }
      await SupabaseService.client.from('workers').upsert({
        'user_id': uid,
        'city': d.city,
        'category': d.category,
        'price_min': d.priceMin,
        'approval_status': 'pending',
        'aadhar_front_url': frontUrl,
        'aadhar_back_url': backUrl,
      });
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Availability toggle - OFF hides worker from search (FR-WORKER-03).
  Future<Result<void>> setAvailability(bool available) async {
    if (!SupabaseService.isReady) return const Success(null);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Error(AuthFailure());
    try {
      await SupabaseService.client
          .from('workers')
          .update({'is_available': available}).eq('user_id', uid);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Pending bookings assigned to me (FR-WORKER-04).
  Future<Result<List<Booking>>> pendingJobs() async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      final rows = await SupabaseService.client
          .from('bookings')
          .select()
          .eq('status', BookingStatus.pending.dbValue)
          .order('created_at', ascending: false)
          .limit(50);
      return Success([for (final r in rows) Booking.fromMap(r)]);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<void>> updateStatus(String bookingId, BookingStatus s) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client
          .from('bookings')
          .update({'status': s.dbValue}).eq('id', bookingId);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// One-time UPI/bank setup - validated server side too (FR-WORKER-10).
  Future<Result<void>> savePaymentInfo({
    required bool upi,
    required String upiId,
    String bankAccount = '',
    String ifsc = '',
    String holderName = '',
  }) async {
    if (!SupabaseService.isReady) return const Success(null);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Error(AuthFailure());
    try {
      await SupabaseService.client.from('worker_payment_info').upsert({
        'user_id': uid,
        'payout_method': upi ? 'upi' : 'bank',
        'upi_id': upi ? upiId : null,
        'bank_account': upi ? null : bankAccount,
        'ifsc': upi ? null : ifsc,
        'account_holder': holderName,
      });
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }
}
