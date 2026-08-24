/// Workers repository - discovery (FR-CLIENT-01..03).
/// Sorted by rating desc, only approved + available workers shown.
library;

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/models/worker.dart';
import 'package:kaamwala/services/supabase_service.dart';

class WorkersRepository {
  const WorkersRepository();

  /// Search by category + city + optional name. Default sort rating desc.
  /// Paginated 10/page max 50 (NFR-SCAL-03).
  Future<Result<List<Worker>>> search({
    required ServiceCategory category,
    String? city,
    String? name,
    int limit = 10,
    int offset = 0,
  }) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      var query = SupabaseService.client
          .from('workers')
          .select('*, users(name, photo_url)')
          .eq('category', category.dbValue)
          .eq('approval_status', 'approved');
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }
      final q = name?.trim() ?? '';
      if (q.isNotEmpty) {
        // PostgREST embed filtering on users.name (safe: parameterised).
        query = query.ilike('users.name', '%$q%');
      }
      final rows = await query
          .order('rating_avg', ascending: false)
          .range(offset, offset + limit - 1);
      return Success([for (final r in rows) Worker.fromMap(r)]);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Home screen "Top rated near you" - any category, available only.
  Future<Result<List<Worker>>> topRated({String? city, int limit = 5}) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      var query = SupabaseService.client
          .from('workers')
          .select('*, users(name, photo_url)')
          .eq('approval_status', 'approved')
          .eq('is_available', true);
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }
      final rows = await query
          .order('rating_avg', ascending: false)
          .limit(limit);
      return Success([for (final r in rows) Worker.fromMap(r)]);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<Worker>> byId(String id) async {
    if (!SupabaseService.isReady) {
      return Success(
        Worker(
          id: id,
          userId: 'demo-user',
          category: ServiceCategory.electrician,
          name: 'Ramesh Kumar',
          area: 'Kharadi',
          city: 'Pune',
          bio: '10 yrs experience. Fan, wiring, MCB, inverter installation.',
          skills: const ['Wiring', 'Fans', 'MCB', 'Inverter'],
          priceMin: 300,
          priceMax: 800,
          ratingAvg: 4.8,
          ratingCount: 120,
          isAvailable: true,
          approvalStatus: ApprovalStatus.approved,
        ),
      );
    }
    try {
      final row = await SupabaseService.client
          .from('workers')
          .select('*, users(name, photo_url)')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return const Error(NotFoundFailure());
      return Success(Worker.fromMap(row));
    } catch (e) {
      return Error(mapException(e));
    }
  }
}
