/// KaamWala (customer app) entry point - flavor `customer`,
/// applicationId com.kaamwala.kaamwala.
///
/// Build/run:
///   flutter run --flavor customer -t lib/main_customer.dart
library;

import 'package:kaamwala/bootstrap.dart';
import 'package:kaamwala/core/config/app_flavor.dart';

export 'package:kaamwala/bootstrap.dart' show KaamWalaApp;

Future<void> main() => bootstrap(AppFlavor.customer);
