/// Bookings repository (FR-CLIENT-04..07, FR-WORKER-04..07).
///
/// NOTE on money: commission/fee/earning values are computed SERVER-SIDE
/// (Edge Function create-order). This repository only reads what the server
/// stored - never recalculates money math (NFR-SEC-02 / FR-PAY-04).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/models/booking.dart';
import 'package:kaamwala/services/supabase_service.dart';

class BookingsRepository {
  const BookingsRepository();

  /// Creates a pending booking. Payment happens right after via Razorpay.
  Future<Result<Booking>> create({
    required String clientId,
    required String workerId,
    required ServiceCategory category,
    required String description,
    required DateTime serviceDate,
    required String timeSlot,
    required String address,
    required num estimateMin,
    required num estimateMax,
  }) async {
    if (!SupabaseService.isReady) {
      return const Error(ServerFailure('Backend not configured'));
    }
    try {
      final row = await SupabaseService.client
          .from('bookings')
          .insert({
            'client_id': clientId,
            'worker_id': workerId,
            'category': category.dbValue,
            'description': description,
            'service_date': serviceDate.toIso8601String().substring(0, 10),
            'time_slot': timeSlot,
            'address': address,
            'status': BookingStatus.pending.dbValue,
            'estimate_min': estimateMin,
            'estimate_max': estimateMax,
          })
          .select()
          .single();
      return Success(Booking.fromMap(row));
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Asks the Edge Function to create a Razorpay order server-side (FR-PAY-01).
  /// Returns {orderId, amount} or failure. Never trusts client-computed amounts.
  Future<Result<Map<String, dynamic>>> createOrder(String bookingId) async {
    if (!SupabaseService.isReady) {
      return const Error(PaymentFailure('Backend not configured'));
    }
    try {
      final res = await SupabaseService.client.functions.invoke(
        'create-order',
        body: {'booking_id': bookingId},
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['error'] != null) {
        return Error(
          PaymentFailure(data['error'] as String? ?? 'Payment failed'),
        );
      }
      return Success(data);
    } catch (e) {
      return Error(mapException(e));
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

  /// Cancel allowed only while pending; Rs.20 auto-refund (FR-PAY-06).
  Future<Result<void>> cancel(String bookingId) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client
          .from('bookings')
          .update({'status': BookingStatus.cancelled.dbValue})
          .eq('id', bookingId)
          .eq('status', BookingStatus.pending.dbValue);
      await SupabaseService.client.functions.invoke(
        'verify-payment',
        body: {'type': 'refund', 'booking_id': bookingId},
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
      await SupabaseService.client.from('bookings').update({
        'live_lat': lat,
        'live_lng': lng,
        'live_location_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId).eq('status', BookingStatus.traveling.dbValue);
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
      await SupabaseService.client.from('bookings').update({
        'live_lat': null,
        'live_lng': null,
        'live_location_updated_at': null,
      }).eq('id', bookingId);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }
}
