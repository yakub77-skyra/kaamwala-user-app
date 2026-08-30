/// Reviews repository (FR-CLIENT-08) - reads/writes the reviews table.
library;

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/models/review.dart';
import 'package:kaamwala/services/supabase_service.dart';

class ReviewsRepository {
  const ReviewsRepository();

  /// One review per booking (UNIQUE constraint enforces immutability at DB).
  Future<Result<void>> submitReview(Review review) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client.from('reviews').insert({
        'booking_id': review.bookingId,
        'worker_id': review.workerId,
        'client_id': review.clientId,
        'rating': review.rating,
        'text': review.text,
        'tags': review.tags,
      });
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<List<Review>>> forWorker(String workerId) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      final rows = await SupabaseService.client
          .from('reviews')
          .select()
          .eq('worker_id', workerId)
          .order('created_at', ascending: false)
          .limit(20);
      return Success([for (final r in rows) Review.fromMap(r)]);
    } catch (e) {
      return Error(mapException(e));
    }
  }
}
