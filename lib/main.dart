import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'services/auth_providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/lineup_screen.dart';
import 'screens/team_select_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/score_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: OpplApp()));
}

class OpplApp extends ConsumerWidget {
  const OpplApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'OPPL',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      routerConfig: router,
    );
  }
}

/// Router with simple auth gate: if signed in -> home; else -> login.
final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authStream = ref.watch(firebaseAuthProvider).authStateChanges();

  return GoRouter(
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(authStream),
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/team-select',
        name: 'team-select',
        builder: (context, state) => const TeamSelectScreen(),
      ),
      GoRoute(
        path: '/lineup/:matchId',
        name: 'lineup',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return LineupScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/verify',
        name: 'verify',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/matches/:teamId',
        name: 'matches',
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          return MatchesScreen(teamId: teamId);
        },
      ),
      GoRoute(
        path: '/score/:matchId',
        name: 'score',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return ScoreScreen(matchId: matchId);
        },
      ),
    ],
    redirect: (context, state) {
      final user = authState.asData?.value;
      final loggingIn = state.uri.path == '/login';
      final registering = state.uri.path == '/register';
      final verifying = state.uri.path == '/verify';
      if (user == null) {
        return (loggingIn || registering) ? null : '/login';
      }
      // If not verified, force to verify page
      if (!user.emailVerified) {
        if (verifying) return null;
        return '/verify';
      }
      if (loggingIn || registering || verifying) return '/';
      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic>? stream) {
    _sub = stream?.listen((_) => notifyListeners());
  }
  StreamSubscription<dynamic>? _sub;
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
