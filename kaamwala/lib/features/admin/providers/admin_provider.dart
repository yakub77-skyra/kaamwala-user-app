/// Admin state - verification queue controller.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/admin/repositories/admin_repository.dart';
import 'package:kaamwala/models/worker.dart';

final adminRepoProvider = Provider((_) => const AdminRepository());

class AdminState {
  const AdminState({
    this.loading = true,
    this.isAdmin = false,
    this.queue = const [],
    this.busyWorkerId,
  });

  final bool loading;
  final bool isAdmin;
  final List<Worker> queue;

  /// Worker currently being approved/rejected (disables its buttons).
  final String? busyWorkerId;

  bool get isEmpty => !loading && isAdmin && queue.isEmpty;
}

class AdminController extends AsyncNotifier<AdminState> {
  @override
  Future<AdminState> build() async {
    final repo = ref.read(adminRepoProvider);
    final isAdminRes = await repo.isAdmin();
    final isAdmin = switch (isAdminRes) {
      Success(:final data) => data,
      Error() => false,
    };
    if (!isAdmin) return const AdminState(loading: false);

    final queueRes = await repo.pendingWorkers();
    return AdminState(
      loading: false,
      isAdmin: true,
      queue: switch (queueRes) {
        Success(:final data) => data,
        Error() => const <Worker>[],
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /// Approve or reject. Returns null on success / user-cancel, else an
  /// error message for a snackbar.
  Future<String?> decide(
    String workerId, {
    required bool approve,
    String? reason,
  }) async {
    _setBusy(workerId);
    final err = await ref
        .read(adminRepoProvider)
        .decide(workerId: workerId, approve: approve, reason: reason);
    await refresh();
    return err;
  }

  void _setBusy(String workerId) {
    final current = state.value ?? const AdminState();
    state = AsyncData(
      AdminState(
        loading: current.loading,
        isAdmin: current.isAdmin,
        queue: current.queue,
        busyWorkerId: workerId,
      ),
    );
  }
}

final adminProvider = AsyncNotifierProvider<AdminController, AdminState>(
  AdminController.new,
);

/// Cheap check used by Settings to show/hide the admin entry point.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final res = await ref.watch(adminRepoProvider).isAdmin();
  return switch (res) {
    Success(:final data) => data,
    Error() => false,
  };
});
