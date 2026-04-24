import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:royal_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:royal_app/features/gate/presentation/screens/gate_screen.dart';
import 'package:royal_app/features/history/domain/ride_entity.dart';
import 'package:royal_app/features/history/presentation/screens/history_map_screen.dart';
import 'package:royal_app/features/history/presentation/screens/history_screen.dart';
import 'package:royal_app/features/mileage/presentation/screens/mileage_screen.dart';
import 'package:royal_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:royal_app/features/tracking/presentation/screens/tracking_screen.dart';

// ── Route names ───────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const gate        = '/';
  static const dashboard   = '/dashboard';
  static const tracking    = '/tracking';
  static const history     = '/history';
  static const historyMap  = '/history/map';
  static const mileage     = '/mileage';
  static const settings    = '/settings';
}

// ── Router ────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: AppRoutes.gate,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.gate,
      name: 'gate',
      pageBuilder: (context, state) => _fade(state, const GateScreen()),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      pageBuilder: (context, state) => _fade(state, const DashboardScreen()),
      routes: [
        GoRoute(
          path: 'tracking',
          name: 'tracking',
          pageBuilder: (context, state) =>
              _slide(state, const TrackingScreen()),
        ),
        GoRoute(
          path: 'history',
          name: 'history',
          pageBuilder: (context, state) =>
              _slide(state, const HistoryScreen()),
          routes: [
            GoRoute(
              path: 'map',
              name: 'historyMap',
              pageBuilder: (context, state) {
                final ride = state.extra as RideEntity;
                return _slide(state, HistoryMapScreen(ride: ride));
              },
            ),
          ],
        ),
        GoRoute(
          path: 'mileage',
          name: 'mileage',
          pageBuilder: (context, state) =>
              _slide(state, const MileageScreen()),
        ),
        GoRoute(
          path: 'settings',
          name: 'settings',
          pageBuilder: (context, state) =>
              _slide(state, const SettingsScreen()),
        ),
      ],
    ),
  ],
);

// ── Page transition helpers ───────────────────────────────────────────────────

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
