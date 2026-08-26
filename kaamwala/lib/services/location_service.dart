/// Device GPS -> city detection ("Use my current location").
///
/// City-level accuracy only (LocationAccuracy.low): we never need or store
/// precise coordinates - the result is just a city name string written to
/// users.city through the normal profile flow.
library;

import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/services/analytics_service.dart';

abstract final class LocationService {
  /// Resolves the device's current city. Asks for location permission on
  /// first use. Never throws - always a typed [Result].
  static Future<Result<String>> detectCity({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const Error(
          ServerFailure('Location is off. Turn it on or type your city.'),
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return const Error(
            ServerFailure(
              'Location permission denied. Type your city instead.',
            ),
          );
        case LocationPermission.deniedForever:
          return const Error(
            ServerFailure(
              'Location is blocked for this app. Enable it from Settings '
              'or type your city.',
            ),
          );
        case LocationPermission.whileInUse:
        case LocationPermission.always:
        case LocationPermission.unableToDetermine:
          break;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeout,
        ),
      );
      // geocoding 5.x is instance-based; on Android this wraps the system
      // geocoder, on iOS CoreLocation reverse geocoding.
      final marks = await Geocoding().placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final city = cityFromPlacemarks(marks);
      if (city == null) {
        return const Error(
          ServerFailure('Could not detect your city. Type it instead.'),
        );
      }
      return Success(city);
    } on TimeoutException {
      return const Error(
        ServerFailure('Taking too long to find you. Type your city instead.'),
      );
    } on Exception catch (e) {
      unawaited(AnalyticsService.recordError(e, StackTrace.current));
      return const Error(
        ServerFailure('Could not detect your city. Type it instead.'),
      );
    }
  }

  /// Pure best-effort city name extraction from reverse-geocode placemarks.
  /// Android's geocoder fills fields inconsistently, so fall back through
  /// locality -> subAdministrativeArea -> administrativeArea.
  static String? cityFromPlacemarks(List<Placemark> marks) {
    for (final m in marks) {
      final c = _clean(m.locality);
      if (c != null) return c;
    }
    for (final m in marks) {
      final c = _clean(m.subAdministrativeArea) ?? _clean(m.administrativeArea);
      if (c != null) return c;
    }
    return null;
  }

  static String? _clean(String? raw) {
    final t = raw?.trim() ?? '';
    return t.isEmpty ? null : t;
  }
}
