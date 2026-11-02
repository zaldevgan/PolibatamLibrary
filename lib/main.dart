import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Penangkal crash global agar aplikasi tidak auto close
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher Error] $error');
    return true; // Return true agar exception tertangani dan aplikasi tetap stabil
  };

  runApp(
    const ProviderScope(
      child: PolibatamLibraryApp(),
    ),
  );
}

final _navigatorKey = GlobalKey<NavigatorState>();

class PolibatamLibraryApp extends ConsumerWidget {
  const PolibatamLibraryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Logout / sesi habis: tutup layar & dialog yang masih terbuka di atas beranda
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.status == AuthStatus.authenticated && next.status != AuthStatus.authenticated) {
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Perpustakaan Polibatam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState state) {
    switch (state.status) {
      case AuthStatus.loading:
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      case AuthStatus.authenticated:
        return const DashboardScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}
