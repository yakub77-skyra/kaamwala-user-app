/// Riverpod providers for SMS service injection.
/// 
/// This file configures dependency injection for the SMS service layer.
/// 
/// IMPORTANT (Phase 1 Section 1):
/// - Currently uses [DemoSmsService] for development (hardcoded OTP: 123456)
/// - To switch to real SMS API after approval:
///   1. Import 'package:kaamwala/core/services/real_sms_service.dart'
///   2. Change the provider to return RealSmsService() instead
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/services/sms_service.dart';
import 'package:kaamwala/core/services/demo_sms_service.dart';
// TODO: Uncomment after SMS API approval:
// import 'package:kaamwala/core/services/real_sms_service.dart';

/// Provider for the SMS service.
/// 
/// Currently returns [DemoSmsService] for development.
/// 
/// To switch to real SMS API after approval, change to:
/// ```dart
/// final smsServiceProvider = Provider<SmsService>((ref) => RealSmsService());
/// ```
final smsServiceProvider = Provider<SmsService>((ref) => DemoSmsService());
