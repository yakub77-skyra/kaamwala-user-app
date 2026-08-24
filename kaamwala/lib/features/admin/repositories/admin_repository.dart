/// Admin repository - worker verification queue (Phase 3 section 5.3).
///
/// Authorization model:
/// - `isAdmin()` reads platform_config.admin_user_ids (readable by all
///   authenticated users - contains no secrets, just uuids).
/// - Queue data comes from the SECURITY DEFINER RPC `admin_pending_workers()`
///   which returns rows ONLY when the caller is on the allowlist.
/// - Approve/reject goes through the `approve-worker` Edge Function which
///   re-checks the allowlist server-side.
library;

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/models/worker.dart';
import 'package:kaamwala/services/supabase_service.dart';

class AdminRepository {
  const AdminRepository();

  Future<Result<bool>> isAdmin() async {
    if (!SupabaseService.isReady) return const Success(false);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Success(false);
    try {
      final row = await SupabaseService.client
          .from('platform_config')
          .select('value')
          .eq('key', 'admin_user_ids')
          .maybeSingle();
      final ids = ((row?['value'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      return Success(ids.contains(uid));
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Pending workers via the admin-gated RPC. Non-admins get [].
  Future<Result<List<Worker>>> pendingWorkers() async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      final rows = await SupabaseService.client.rpc(
        'admin_pending_workers',
      ) as List<dynamic>;
      return Success([for (final r in rows) _workerFromRow(r)]);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Worker _workerFromRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Worker(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      category: ServiceCategory.fromDb(map['category'] as String? ?? 'plumber'),
      name: (map['name'] ?? '') as String,
      photoUrl: map['photo_url'] as String?,
      city: (map['city'] ?? '') as String,
      area: (map['area'] ?? '') as String,
      bio: (map['bio'] ?? '') as String,
      skills: [
        for (final s in (map['skills'] as List<dynamic>? ?? const []))
          s as String,
      ],
      priceMin: (map['price_min'] ?? 0) as num,
      priceMax: (map['price_max'] ?? 0) as num,
      isAvailable: false,
      approvalStatus: ApprovalStatus.pending,
      portfolioUrls: [
        for (final s in (map['portfolio_urls'] as List<dynamic>? ?? const []))
          s as String,
      ],
    );
  }

  /// Approve or reject a worker via the Edge Function.
  /// Returns null on success, or a human-readable failure message.
  Future<String?> decide({
    required String workerId,
    required bool approve,
    String? reason,
  }) async {
    if (!SupabaseService.isReady) return 'Backend not configured';
    try {
      final res = await SupabaseService.client.functions.invoke(
        'approve-worker',
        body: {
          'worker_id': workerId,
          'action': approve ? 'approve' : 'reject',
          if (!approve && reason != null) 'reason': reason,
        },
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['ok'] == true) return null;
      return (data['error'] as String?) ?? 'Action failed';
    } catch (e) {
      return mapException(e).message;
    }
  }

  /// Aadhar document paths for manual review in Supabase Studio
  /// (private bucket; client apps cannot render them by design).
  Future<Result<Map<String, String?>>> aadhaarPaths(String workerId) async {
    if (!SupabaseService.isReady) return const Success({});
    try {
      final row = await SupabaseService.client
          .from('workers')
          .select('aadhar_front_url, aadhar_back_url')
          .eq('id', workerId)
          .maybeSingle();
      return Success({
        'front': row?['aadhar_front_url'] as String?,
        'back': row?['aadhar_back_url'] as String?,
      });
    } catch (e) {
      return Error(mapException(e));
    }
  }
}
