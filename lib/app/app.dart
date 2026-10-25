import '../features/places/curated_places.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';
import '../features/auth/auth_screen.dart';
import '../features/trips/presentation/trip_list_screen.dart';
import '../features/trips/presentation/trip_form_screen.dart';
import '../features/trips/presentation/trip_detail_screen.dart';
import '../features/activities/presentation/activity_form_screen.dart';
import '../core/errors.dart';

class TripPocketApp extends ConsumerWidget {
  const TripPocketApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return session.when(
      skipLoadingOnRefresh: false,
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, s) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorText(e)),
                TextButton(
                  onPressed: () => ref.invalidate(sessionProvider),
                  child: const Text('ลองใหม่'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (user) =>
          SessionApp(key: ValueKey(user?.uid ?? 'signed-out'), uid: user?.uid),
    );
  }
}

/// Recreated per uid: drops the complete navigation stack and all old screen state.
class SessionApp extends ConsumerStatefulWidget {
  final String? uid;
  const SessionApp({super.key, required this.uid});
  @override
  ConsumerState<SessionApp> createState() => _SessionAppState();
}

class _SessionAppState extends ConsumerState<SessionApp> {
  late final GoRouter router = GoRouter(
    initialLocation: widget.uid == null ? '/login' : '/trips',
    redirect: (c, s) {
      final auth =
          s.matchedLocation == '/login' || s.matchedLocation == '/register';
      if (widget.uid == null && !auth) return '/login';
      if (widget.uid != null && auth) return '/trips';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const AuthScreen()),
      GoRoute(
        path: '/register',
        builder: (c, s) => const AuthScreen(register: true),
      ),
      GoRoute(
        path: '/trips',
        builder: (c, s) => TripListScreen(uid: widget.uid!),
      ),
      GoRoute(
        path: '/trips/new',
        builder: (c, s) => TripFormScreen(uid: widget.uid!),
      ),
      GoRoute(
        path: '/trips/:tripId',
        builder: (c, s) => TripDetailScreen(
          uid: widget.uid!,
          tripId: s.pathParameters['tripId']!,
        ),
      ),
      GoRoute(
        path: '/trips/:tripId/edit',
        builder: (c, s) => TripFormScreen(
          uid: widget.uid!,
          tripId: s.pathParameters['tripId'],
        ),
      ),
      GoRoute(
        path: '/trips/:tripId/activities/new',
        builder: (c, s) => ActivityFormScreen(
          uid: widget.uid!,
          tripId: s.pathParameters['tripId']!,
          seed: s.extra is ActivitySeed ? s.extra as ActivitySeed : null,
        ),
      ),
      GoRoute(
        path: '/trips/:tripId/activities/:activityId/edit',
        builder: (c, s) => ActivityFormScreen(
          uid: widget.uid!,
          tripId: s.pathParameters['tripId']!,
          activityId: s.pathParameters['activityId'],
        ),
      ),
    ],
  );
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    return MaterialApp.router(
      title: 'TripPocket',
      debugShowCheckedModeBanner: false,
      locale: const Locale('th'),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff087e8b)),
        scaffoldBackgroundColor: const Color(0xfff6f9f9),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      ),
      routerConfig: router,
      builder: (context, child) => Column(
        children: [
          if (mode != 'live')
            Material(
              color: Colors.amber.shade100,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      mode == 'demo'
                          ? 'โหมดจำลอง • ทริปไม่บันทึกบน Firebase'
                          : 'Firebase Emulator • ข้อมูลทดสอบ',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(child: child!),
        ],
      ),
    );
  }
}
