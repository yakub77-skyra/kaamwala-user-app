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
  /// [availableNow] filters to workers with is_available=true.
  /// [userLat]/[userLng] enables distance-based sorting (nearest first).
  Future<Result<List<Worker>>> search({
    required ServiceCategory category,
    String? city,
    String? name,
    bool availableNow = false,
    double? userLat,
    double? userLng,
    int limit = 10,
    int offset = 0,
  }) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      var query = SupabaseService.client
          .from('workers')
          .select('*, users(name, photo_url, phone)')
          .eq('category', category.dbValue)
          .eq('approval_status', 'approved');
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }
      if (availableNow) {
        query = query.eq('is_available', true);
      }
      final q = name?.trim() ?? '';
      if (q.isNotEmpty) {
        // PostgREST embed filtering on users.name (safe: parameterised).
        query = query.ilike('users.name', '%$q%');
      }

      // Apply sorting
      if (userLat != null && userLng != null) {
        // Distance sorting - use PostGIS if available, otherwise sort client-side
        // For now, fetch and sort client-side (limit 50 max)
        final rows = await query.limit(50);
        final workers = [for (final r in rows) Worker.fromMap(r)];
        workers.sort((a, b) {
          final da = a.distanceKmFrom(userLat, userLng) ?? double.infinity;
          final db = b.distanceKmFrom(userLat, userLng) ?? double.infinity;
          return da.compareTo(db);
        });
        final paginated = workers.skip(offset).take(limit).toList();
        return Success(paginated);
      } else {
        final rows = await query
            .order('rating_avg', ascending: false)
            .range(offset, offset + limit - 1);
        return Success([for (final r in rows) Worker.fromMap(r)]);
      }
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Home screen "Top rated near you" - any category, available only.
  Future<Result<List<Worker>>> topRated({
    String? city,
    int limit = 5,
    double? userLat,
    double? userLng,
  }) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      var query = SupabaseService.client
          .from('workers')
          .select('*, users(name, photo_url, phone)')
          .eq('approval_status', 'approved')
          .eq('is_available', true);
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }

      if (userLat != null && userLng != null) {
        final rows = await query.limit(50);
        final workers = [for (final r in rows) Worker.fromMap(r)];
        workers.sort((a, b) {
          final da = a.distanceKmFrom(userLat, userLng) ?? double.infinity;
          final db = b.distanceKmFrom(userLat, userLng) ?? double.infinity;
          return da.compareTo(db);
        });
        return Success(workers.take(limit).toList());
      } else {
        final rows = await query
            .order('rating_avg', ascending: false)
            .limit(limit);
        return Success([for (final r in rows) Worker.fromMap(r)]);
      }
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<Worker>> byId(String id) async {
    if (!SupabaseService.isReady) {
      return const Error(ServerFailure('Backend not configured'));
    }
    try {
      final row = await SupabaseService.client
          .from('workers')
          .select('*, users(name, photo_url, phone)')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return const Error(NotFoundFailure());
      return Success(Worker.fromMap(row));
    } catch (e) {
      return Error(mapException(e));
    }
  }
}
