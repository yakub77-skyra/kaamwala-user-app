/// Pricing repository - reads platform_config['pricing'] (source of truth,
/// Phase 2 task 7). Falls back to the legacy 'booking_fee_rupees' key and
/// finally to [PricingConfig.defaults].
library;

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/models/pricing_config.dart';
import 'package:kaamwala/services/supabase_service.dart';

class PricingRepository {
  const PricingRepository();

  Future<Result<PricingConfig>> fetch() async {
    if (!SupabaseService.isReady) {
      return Success(PricingConfig.defaults);
    }
    try {
      final rows = await SupabaseService.client
          .from('platform_config')
          .select('key, value')
          .inFilter('key', ['pricing', 'booking_fee_rupees']);
      final map = <String, dynamic>{};
      for (final r in rows) {
        final v = r['value'];
        if (v is Map) {
          map.addAll(Map<String, dynamic>.from(v));
          // Keep the legacy key as a sub-field so fromMap can use it too.
          if (r['key'] == 'booking_fee_rupees') {
            map['booking_fee_rupees'] = v['value'] ?? v;
          }
        } else {
          map[r['key'] as String] = v;
        }
      }
      return Success(PricingConfig.fromMap(map));
    } catch (e) {
      // Config is non-critical display data: fall back to defaults rather
      // than blocking the booking flow.
      return Success(PricingConfig.defaults);
    }
  }
}
