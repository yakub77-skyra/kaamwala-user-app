// mapException classification - the single boundary every repo exception
// crosses; wrong class means wrong user-facing message.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/core/error/failure.dart';

void main() {
  group('mapException', () {
    test('socket/timeout/network -> NetworkFailure', () {
      expect(
        mapException(const SocketException('reset')),
        isA<NetworkFailure>(),
      );
      expect(mapException(TimeoutException('slow')), isA<NetworkFailure>());
      expect(
        mapException(Exception('Network request failed')),
        isA<NetworkFailure>(),
      );
    });

    test('401/403/jwt -> AuthFailure', () {
      expect(
        mapException(Exception('AuthApiException 401 unauthorized')),
        isA<AuthFailure>(),
      );
      expect(mapException(Exception('403 Forbidden')), isA<AuthFailure>());
      expect(
        mapException(Exception('Invalid JWT: token expired')),
        isA<AuthFailure>(),
      );
    });

    test('404 / not found -> NotFoundFailure', () {
      expect(mapException(Exception('404 Not Found')), isA<NotFoundFailure>());
      expect(mapException(Exception('row not found')), isA<NotFoundFailure>());
    });

    test('FormatException / TypeError -> ServerFailure', () {
      expect(mapException(FormatException('bad json')), isA<ServerFailure>());
      expect(
        () => mapException('' as int), // triggers TypeError
        throwsA(isA<TypeError>()),
      );
      // Directly verify the TypeError branch via a thrown-then-caught value:
      Object typeError;
      try {
        '' as int;
        typeError = Exception('unreachable');
      } catch (e) {
        typeError = e;
      }
      expect(mapException(typeError), isA<ServerFailure>());
    });

    test('unknown exception -> ServerFailure (safe default)', () {
      final f = mapException(Exception('something weird'));
      expect(f, isA<ServerFailure>());
    });

    test('classification precedence: socket beats other keywords', () {
      // A message containing both network and auth markers must classify as
      // Network because the network check runs first.
      final f = mapException(Exception('Socket closed during jwt exchange'));
      expect(f, isA<NetworkFailure>());
    });
  });
}
