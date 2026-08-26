/// Which store-listing binary is running.
///
/// One codebase ships TWO apps via Android product flavors (Swiggy /
/// Swiggy Partner model):
///  - [customer] = "KaamWala" (com.kaamwala.kaamwala) - booking side
///  - [partner]  = "KaamWala Partner" (com.kaamwala.partner) - worker side
///
/// The flavor is decided by the entry point (`main_customer.dart` vs
/// `main_partner.dart`) and exposed to widgets through [flavorProvider].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFlavor { customer, partner }

/// Defaults to customer so plain `flutter test` / `KaamWalaApp()` usage
/// needs no overrides; bootstrap() overrides this for partner builds.
final flavorProvider = Provider<AppFlavor>((ref) => AppFlavor.customer);

extension AppFlavorX on AppFlavor {
  /// Play Store / launcher name.
  String get appName =>
      this == AppFlavor.partner ? 'KaamWala Partner' : 'KaamWala';

  /// The sibling app a user of the wrong binary must install instead.
  AppFlavor get sibling =>
      this == AppFlavor.customer ? AppFlavor.partner : AppFlavor.customer;
}
