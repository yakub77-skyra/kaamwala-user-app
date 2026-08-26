// LocationService.cityFromPlacemarks - Android geocoders fill fields
// inconsistently, so the locality -> subAdministrativeArea ->
// administrativeArea fallback order is what decides whether a user in, say,
// Warangal gets "Warangal" or nothing.
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

import 'package:kaamwala/services/location_service.dart';

void main() {
  group('cityFromPlacemarks', () {
    test('prefers locality when present', () {
      final city = LocationService.cityFromPlacemarks([
        const Placemark(
          locality: 'Warangal',
          administrativeArea: 'Telangana',
          country: 'India',
        ),
      ]);
      expect(city, 'Warangal');
    });

    test('falls back to subAdministrativeArea when locality empty', () {
      final city = LocationService.cityFromPlacemarks([
        const Placemark(
          locality: '',
          subAdministrativeArea: 'Warangal Urban',
          administrativeArea: 'Telangana',
        ),
      ]);
      expect(city, 'Warangal Urban');
    });

    test('falls back to administrativeArea as last resort', () {
      final city = LocationService.cityFromPlacemarks([
        const Placemark(administrativeArea: 'Maharashtra'),
      ]);
      expect(city, 'Maharashtra');
    });

    test('scans later placemarks before degrading', () {
      // First placemark missing everything, second has locality.
      final city = LocationService.cityFromPlacemarks([
        const Placemark(name: 'Unnamed Road'),
        const Placemark(locality: 'Pune'),
      ]);
      expect(city, 'Pune');
    });

    test('trims whitespace-only values', () {
      final city = LocationService.cityFromPlacemarks([
        const Placemark(locality: '   ', subAdministrativeArea: ' Jaipur '),
      ]);
      expect(city, 'Jaipur');
    });

    test('returns null when every field is blank', () {
      final city = LocationService.cityFromPlacemarks([
        const Placemark(),
        const Placemark(locality: '', administrativeArea: ''),
      ]);
      expect(city, isNull);
    });

    test('returns null for empty list', () {
      expect(LocationService.cityFromPlacemarks(const []), isNull);
    });
  });
}
