import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/dashboard/presentation/admin_shell_layout.dart';
import '../features/dashboard/presentation/dashboard_home_screen.dart';
import '../features/fleet/presentation/fleet_manager_screen.dart';
import '../features/bookings/presentation/live_bookings_screen.dart';
import '../features/search/presentation/home_search_screen.dart';
import '../features/search/presentation/search_results_screen.dart';
import '../features/search/presentation/car_details_screen.dart';
import '../features/fleet/presentation/partner_apply_screen.dart';
import '../features/fleet/presentation/partner_register_screen.dart';
import '../features/fleet/presentation/partner_applications_screen.dart';
import '../features/fleet/presentation/partner_login_screen.dart';
import '../features/fleet/data/partner_repository.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  final currentPartner = ref.watch(currentPartnerProvider);
  final isAdmin = ref.watch(isAdminProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      if (path.startsWith('/admin')) {
        if (!isAdmin && currentPartner == null) {
          return '/partner/login';
        }
      }
      return null;
    },
    routes: [
      // 1. Standalone Customer App Routes
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeSearchScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search_results',
        builder: (context, state) {
          final locationId = state.uri.queryParameters['locationId'];
          final startStr = state.uri.queryParameters['start'];
          final endStr = state.uri.queryParameters['end'];

          final startDate = startStr != null ? DateTime.tryParse(startStr) : null;
          final endDate = endStr != null ? DateTime.tryParse(endStr) : null;

          return SearchResultsScreen(
            locationId: locationId,
            startDate: startDate,
            endDate: endDate,
          );
        },
      ),
      GoRoute(
        path: '/car/:id',
        name: 'car_details',
        builder: (context, state) {
          final carId = state.pathParameters['id'] ?? '';
          return CarDetailsScreen(carId: carId);
        },
      ),

      GoRoute(
        path: '/partner/apply',
        name: 'partner_apply',
        builder: (context, state) => const PartnerApplyScreen(),
      ),
      GoRoute(
        path: '/partner/login',
        name: 'partner_login',
        builder: (context, state) => const PartnerLoginScreen(),
      ),
      GoRoute(
        path: '/partner/register',
        name: 'partner_register',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return PartnerRegisterScreen(token: token);
        },
      ),

      // 2. Shell Route for Admin Control Panel (separated under /admin prefix)
      ShellRoute(
        builder: (context, state, child) => AdminShellLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: 'admin_dashboard',
            builder: (context, state) => const DashboardHomeScreen(),
          ),
          GoRoute(
            path: '/admin/fleet',
            name: 'admin_fleet',
            builder: (context, state) => const FleetManagerScreen(),
          ),
          GoRoute(
            path: '/admin/bookings',
            name: 'admin_bookings',
            builder: (context, state) => const LiveBookingsScreen(),
          ),
          GoRoute(
            path: '/admin/applications',
            name: 'admin_applications',
            builder: (context, state) => const PartnerApplicationsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
}
