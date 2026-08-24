/// Worker-side repository (FR-WORKER-01..10).
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Optional work photos (max 5, CS-05) -> PUBLIC portfolios bucket.
  final List<Uint8List> portfolioBytes = [];
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

      // Work photos -> public portfolios bucket, public URLs on the row
      // (DB check caps the array at 5; we cap earlier for UX).
      final portfolioUrls = <String>[];
      if (d.portfolioBytes.isNotEmpty) {
        final pf = SupabaseService.client.storage.from('portfolios');
        for (var i = 0; i < d.portfolioBytes.length && i < 5; i++) {
          final path =
              '$uid/work_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await pf.uploadBinary(
            path,
            d.portfolioBytes[i],
            fileOptions: const FileOptions(upsert: true),
          );
          portfolioUrls.add(pf.getPublicUrl(path));
        }
      }

      await SupabaseService.client.from('workers').upsert({
        'user_id': uid,
        'city': d.city,
        'category': d.category,
        'price_min': d.priceMin,
        'approval_status': 'pending',
        'aadhar_front_url': frontUrl,
        'aadhar_back_url': backUrl,
        'portfolio_urls': portfolioUrls,
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
          .update({'is_available': available})
          .eq('user_id', uid);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Pending bookings assigned to me (FR-WORKER-04).
  /// RLS scopes rows to the signed-in worker (0002 bookings_select_participants);
  /// client name is embedded via FK so Booking.fromMap picks it up.
  Future<Result<List<Booking>>> pendingJobs() =>
      myBookings(statuses: [BookingStatus.pending]);

  /// Bookings for this worker filtered by status - dashboard, active jobs,
  /// earnings all read from here. Money fields are server-computed values
  /// that we only display (NFR-SEC-02).
  Future<Result<List<Booking>>> myBookings({
    List<BookingStatus>? statuses,
  }) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      var query = SupabaseService.client
          .from('bookings')
          .select('*, users(name)');
      if (statuses != null && statuses.isNotEmpty) {
        query = query.inFilter('status', [for (final s in statuses) s.dbValue]);
      }
      final rows = await query.order('created_at', ascending: false).limit(100);
      return Success([for (final r in rows) Booking.fromMap(r)]);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Single booking by id - job detail screen (W5).
  Future<Result<Booking?>> bookingById(String id) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      final row = await SupabaseService.client
          .from('bookings')
          .select('*, users(name)')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return const Success(null);
      return Success(Booking.fromMap(row));
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// My workers row - dashboard reads availability + review status from it.
  Future<Result<Map<String, dynamic>?>> myWorker() async {
    if (!SupabaseService.isReady) return const Success(null);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Error(AuthFailure());
    try {
      final row = await SupabaseService.client
          .from('workers')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      return Success(row == null ? null : Map<String, dynamic>.from(row));
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Moves a booking forward. [expectedFrom] guards against out-of-order
  /// taps (e.g. completing before arriving) - the update simply no-ops
  /// when the row is no longer in the expected state.
  Future<Result<void>> updateStatus(
    String bookingId,
    BookingStatus s, {
    BookingStatus? expectedFrom,
  }) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      var query = SupabaseService.client
          .from('bookings')
          .update({'status': s.dbValue})
          .eq('id', bookingId);
      if (expectedFrom != null) {
        query = query.eq('status', expectedFrom.dbValue);
      }
      await query;
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
