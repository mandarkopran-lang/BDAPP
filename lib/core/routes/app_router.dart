import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_provider.dart';
import '../models/user_model.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/screens/phone_number_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/company_management_screen.dart';
import '../../features/admin/screens/department_plant_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/breakdown/screens/breakdown_list_screen.dart';
import '../../features/breakdown/screens/breakdown_create_screen.dart';
import '../../features/breakdown/screens/breakdown_detail_screen.dart';
import '../../features/dashboard/home_screen.dart';

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation.startsWith('/auth');
      final atSplash = state.matchedLocation == '/';

      if (authProvider.status == AuthStatus.unknown) {
        return atSplash ? null : '/';
      }

      if (authProvider.status == AuthStatus.unauthenticated) {
        return loggingIn ? null : '/auth/phone';
      }

      // Authenticated but no company assigned yet & not an admin creating one.
      final profile = authProvider.currentUserProfile;
      if (profile != null &&
          profile.companyId == null &&
          profile.role != UserRole.admin &&
          state.matchedLocation != '/pending-approval') {
        return '/pending-approval';
      }

      if (loggingIn || atSplash) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneNumberScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpScreen(
            verificationId: extra?['verificationId'] ?? '',
            phoneNumber: extra?['phoneNumber'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/companies',
        builder: (context, state) => const CompanyManagementScreen(),
      ),
      GoRoute(
        path: '/admin/departments-plants',
        builder: (context, state) => const DepartmentPlantScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/breakdowns',
        builder: (context, state) => const BreakdownListScreen(),
      ),
      GoRoute(
        path: '/breakdowns/create',
        builder: (context, state) => const BreakdownCreateScreen(),
      ),
      GoRoute(
        path: '/breakdowns/:id',
        builder: (context, state) => BreakdownDetailScreen(
          breakdownId: state.pathParameters['id']!,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}
