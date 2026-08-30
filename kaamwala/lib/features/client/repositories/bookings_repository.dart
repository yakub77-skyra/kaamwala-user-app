/// Bookings repository (FR-CLIENT-04..07, FR-WORKER-04..07) + Phase 2.
///
/// Money rule (NFR-SEC-02 / FR-PAY-04): ALL money math is server-side
/// (Edge Function create-order). Booking creation + order creation happen
/// in ONE server call; the client only sends the booking details and never
/// an amount. This repository reads what the server stored.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/services/booking/booking_validator.dart'
    show kSlotOccupyingStatuses;
import 'package:kaamwala/models/booking.dart';
import 'package:kaamwala/services/supabase_service.dart';

class BookingsRepository {
  const BookingsRepository();

  /// Creates the booking (payment_pending) AND its payment order in one
  /// server call (create-order mode 2). Validates worker availability, slot
  /// overlap, date/time lead time and address server-side. Returns the
  /// server-computed order draft (paise amount).
  Future<Result<BookingOrderDraft>> createBookingOrder({
    required String workerId,
    required ServiceCategory category,
    required String description,
    required DateTime serviceDate,
    required String timeSlot,
    required String address,
    required num estimateMin,
    required num estimateMax,
    required String idempotencyKey,
  }) async {
    if (!SupabaseService.isReady) {
      return const Error(PaymentFailure('Backend not configured'));
    }
    try {
      final res = await SupabaseService.client.functions.invoke(
        'create-order',
        body: {
          'worker_id': workerId,
          'category': category.dbValue,
          'description': description,
          'service_date': serviceDate.toIso8601String().substring(0, 10),
          'time_slot': timeSlot,
          'address': address,
          'estimate_min': estimateMin,
          'estimate_max': estimateMax,
          'idempotency_key': idempotencyKey,
        },
      );
      return _draftFrom(res.data);
    } catch (e) {
      return Error(_friendly(e));
    }
  }

  /// Reuses/creates the payment order for an EXISTING booking
  /// (create-order mode 1) - idempotent server-side. Used by the payment
  /// screen and My Bookings "Pay Now".
  Future<Result<BookingOrderDraft>> createOrder(String bookingId) async {
    if (!SupabaseService.isReady) {
      return const Error(PaymentFailure('Backend not configured'));
    }
    try {
      final res = await SupabaseService.client.functions.invoke(
        'create-order',
        body: {'booking_id': bookingId},
      );
      return _draftFrom(res.data);
    } catch (e) {
      return Error(_friendly(e));
    }
  }

  /// All slots already taken by active bookings of this worker on [date]
  /// (used to disable slot chips with a reason).
  Future<Result<Set<String>>> takenSlots({
    required String workerId,
    required DateTime serviceDate,
  }) async {
    if (!SupabaseService.isReady) return const Success({});
    try {
      final rows = await SupabaseService.client
          .from('bookings')
          .select('time_slot')
          .eq('worker_id', workerId)
          .eq('service_date', serviceDate.toIso8601String().substring(0, 10))
          .inFilter('status', kSlotOccupyingStatuses.toList());
      return Success({for (final r in rows) r['time_slot'] as String});
    } catch (e) {
      return const Success({});
    }
  }

  /// Server-side payment status check (task 11) - reconciles stuck razorpay
  /// orders and reports authoritative payment state.
  Future<Result<BookingPaymentStatus>> checkPaymentStatus(
    String bookingId,
  ) async {
    if (!SupabaseService.isReady) {
      return const Error(PaymentFailure('Backend not configured'));
    }
    try {
      final res = await SupabaseService.client.functions.invoke(
        'check-payment-status',
        body: {'booking_id': bookingId},
      );
      return Success(
        BookingPaymentStatus.fromMap(
          Map<String, dynamic>.from(res.data as Map),
        ),
      );
    } catch (e) {
      return Error(_friendly(e));
    }
  }

  /// Marks a MOCK booking paid (dev mode only; server rejects when the
  /// booking's provider is razorpay).
  Future<Result<void>> confirmMockPayment(String bookingId) async {
    if (!SupabaseService.isReady) {
      return const Error(PaymentFailure('Backend not configured'));
    }
    try {
      await SupabaseService.client.functions.invoke(
        'verify-payment',
        body: {'type': 'mock_confirm', 'booking_id': bookingId},
      );
      return const Success(null);
    } catch (e) {
      return Error(_friendly(e));
    }
  }

  /// Cancels a booking server-side: records reason, initiates refund when
  /// applicable (task 13). Allowed only before worker acceptance.
  Future<Result<CancelBookingResult>> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    if (!SupabaseService.isReady) {
      return const Error(ServerFailure('Backend not configured'));
    }
    try {
      final res = await SupabaseService.client.functions.invoke(
        'cancel-booking',
        body: {
          'booking_id': bookingId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return Success(
        CancelBookingResult(
          cancelled: (data['cancelled'] ?? true) as bool,
          refundStatus: RefundStatus.fromDb(data['refund_status'] as String?),
          refundMessage: data['refund_message'] as String?,
          refundId: data['refund_id'] as String?,
        ),
      );
    } catch (e) {
      return Error(_friendly(e));
    }
  }

  /// Single booking (client side) with worker identity embed.
  Future<Result<Booking?>> bookingById(String id) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      final row = await SupabaseService.client
          .from('bookings')
          .select('*, workers(id, users(name, photo_url))')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return const Success(null);
      return Success(Booking.fromMap(row));
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Uploads booking photos to storage (booking_photos/`uid`/`bookingId`/)
  /// with per-photo progress. On success attaches the URLs to the booking.
  /// [onProgress] reports (uploadedCount, totalCount). Returns uploaded URLs;
  /// a failed upload throws nothing - failures come back as Error.
  Future<Result<List<String>>> uploadBookingPhotos({
    required String bookingId,
    required List<({Uint8List bytes, String name})> photos,
    void Function(int done, int total)? onProgress,
  }) async {
    if (!SupabaseService.isReady) {
      return const Error(ServerFailure('Backend not configured'));
    }
    if (photos.isEmpty) return const Success([]);
    try {
      final bucket = SupabaseService.client.storage.from('booking_photos');
      final uid = SupabaseService.currentUserId;
      if (uid == null) return const Error(AuthFailure());
      final urls = <String>[];
      for (var i = 0; i < photos.length; i++) {
        final photo = photos[i];
        final ext = _extOf(photo.name);
        final path =
            '$uid/$bookingId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        await bucket.uploadBinary(path, photo.bytes);
        urls.add(bucket.getPublicUrl(path));
        onProgress?.call(i + 1, photos.length);
      }
      await SupabaseService.client
          .from('bookings')
          .update({'photo_urls': urls})
          .eq('id', bookingId);
      return Success(urls);
    } catch (e) {
      return Error(
        ServerFailure('Photo upload failed. Please retry or remove the photo.'),
      );
    }
  }

  /// Client confirms completion -> unlocks payout (Phase 3 sequence diagram).
  Future<Result<void>> confirmCompletion(String bookingId) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client.functions.invoke(
        'release-payout',
        body: {'booking_id': bookingId, 'action': 'confirm'},
      );
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<List<Booking>>> forClient(String clientId) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      final rows = await SupabaseService.client
          .from('bookings')
          .select('*, workers(id, users(name, photo_url))')
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(50);
      return Success([for (final r in rows) Booking.fromMap(r)]);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Display name of the OTHER participant of a booking (chat header).
  /// Works from either side thanks to the users/workers embeds.
  Future<Result<String>> counterpartName(String bookingId) async {
    if (!SupabaseService.isReady) return const Success('');
    try {
      final row = await SupabaseService.client
          .from('bookings')
          .select('client_id, users(name), workers(id, users(name))')
          .eq('id', bookingId)
          .maybeSingle();
      if (row == null) return const Success('');
      final myId = SupabaseService.currentUserId;
      final clientName = ((row['users'] as Map?)?['name'] ?? '') as String;
      final workerMap = (row['workers'] as Map?)?['users'] as Map?;
      final workerName = ((workerMap?['name'] ?? '') as String);
      if (row['client_id'] == myId) return Success(workerName);
      return Success(clientName);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Realtime subscription so status timeline updates live (CS-10).
  RealtimeChannel subscribeBooking(String bookingId, void Function() onChange) {
    return SupabaseService.client
        .channel('booking:$bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: bookingId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  /// Updates live location for worker tracking (only during 'traveling' status).
  Future<Result<void>> updateLiveLocation({
    required String bookingId,
    required double lat,
    required double lng,
  }) async {
    if (!SupabaseService.isReady) {
      return const Error(ServerFailure('Backend not configured'));
    }
    try {
      await SupabaseService.client
          .from('bookings')
          .update({
            'live_lat': lat,
            'live_lng': lng,
            'live_location_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId)
          .eq('status', BookingStatus.traveling.dbValue);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Stops live location sharing.
  Future<Result<void>> stopLiveLocation(String bookingId) async {
    if (!SupabaseService.isReady) {
      return const Error(ServerFailure('Backend not configured'));
    }
    try {
      await SupabaseService.client
          .from('bookings')
          .update({
            'live_lat': null,
            'live_lng': null,
            'live_location_updated_at': null,
          })
          .eq('id', bookingId);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  static Result<BookingOrderDraft> _draftFrom(Object? data) {
    if (data is! Map) {
      return const Error(PaymentFailure('Payment failed. Try again.'));
    }
    final map = Map<String, dynamic>.from(data);
    if (map['error'] != null) {
      return Error(
        PaymentFailure(map['error'] as String? ?? 'Payment failed. Try again.'),
      );
    }
    return Success(BookingOrderDraft.fromMap(map));
  }

  /// Maps edge-function failures to user-friendly messages where possible.
  static Failure _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('already paid') || msg.contains('already_paid')) {
      return const PaymentFailure('This booking is already paid.');
    }
    if (msg.contains('worker_unavailable')) {
      return const PaymentFailure(
        'This worker is currently unavailable. Please choose another worker.',
      );
    }
    if (msg.contains('slot_taken')) {
      return const PaymentFailure(
        'This time slot is no longer available. Please select another slot.',
      );
    }
    return mapException(e);
  }

  static String _extOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return 'jpg';
    final ext = name.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'webp' => ext == 'jpeg' ? 'jpg' : ext,
      _ => 'jpg',
    };
  }
}
