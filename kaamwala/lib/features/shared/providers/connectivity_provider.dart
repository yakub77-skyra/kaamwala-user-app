/// Connectivity awareness: offline banner state + auto-refresh on reconnect.
///
/// Assumes online until the platform says otherwise, so tests and platforms
/// without the channel behave exactly like today (errors stay reactive).
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/providers/shared_providers.dart';
import 'package:kaamwala/features/worker/providers/worker_providers.dart';

/// True = assume online. Never blocks UI; failures still surface via
/// NetworkFailure from repositories.
class ConnectivityController extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  bool build() {
    ref.onDispose(() => unawaited(_sub?.cancel()));
    _listen();
    return true;
  }

  void _listen() {
    try {
      _sub = Connectivity().onConnectivityChanged.listen((results) {
        final online = !results.contains(ConnectivityResult.none);
        if (online == state) return;
        state = online;
        // Coming back online: silently refresh everything on screen.
        if (online) _refreshAll();
      }, onError: (_) {});
    } on Exception catch (_) {
      // Channel unavailable (tests / unsupported platform) - stay "online".
    }
  }

  void _refreshAll() {
    ref.invalidate(topRatedWorkersProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(myBookingsProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(workerJobsProvider);
    ref.invalidate(activeJobsProvider);
    ref.invalidate(completedJobsProvider);
  }
}

final connectivityProvider = NotifierProvider<ConnectivityController, bool>(
  ConnectivityController.new,
);
