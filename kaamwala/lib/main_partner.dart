/// KaamWala Partner (worker app) entry point - flavor `partner`,
/// applicationId com.kaamwala.partner.
///
/// Build/run:
///   flutter run --flavor partner -t lib/main_partner.dart
library;

import 'package:kaamwala/bootstrap.dart';
import 'package:kaamwala/core/config/app_flavor.dart';

Future<void> main() => bootstrap(AppFlavor.partner);
