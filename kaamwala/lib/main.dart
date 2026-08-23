import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/routing/app_router.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const ProviderScope(child: KaamWalaApp()));
}

class KaamWalaApp extends ConsumerWidget {
  const KaamWalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'KaamWala',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
