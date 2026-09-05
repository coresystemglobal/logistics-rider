import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/verify_email_screen.dart';
import '../../screens/auth/pending_approval_screen.dart';
import '../../screens/rider/rider_shell.dart';
import '../../screens/rider/home_screen.dart';
import '../../screens/rider/jobs_screen.dart';
import '../../screens/rider/job_detail_screen.dart';
import '../../screens/rider/job_accepted_screen.dart';
import '../../screens/rider/active_delivery_screen.dart';
import '../../screens/rider/delivery_complete_screen.dart';
import '../../screens/rider/earnings_screen.dart';
import '../../screens/rider/transactions_screen.dart';
import '../../screens/rider/withdrawal_screen.dart';
import '../../screens/rider/payout_settings_screen.dart';
import '../../screens/rider/edit_rider_profile_screen.dart';
import '../../screens/rider/change_password_screen.dart';
import '../../screens/rider/rider_profile_screen.dart';
import '../../screens/rider/vehicle_documents_screen.dart';
import '../../screens/rider/performance_screen.dart';
import '../../screens/shared/notifications_screen.dart';
import '../../screens/shared/package_chat_screen.dart';
import '../../screens/shared/ratings_screen.dart';
import '../../screens/shared/help_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final status = authState.status;
      final loc = state.matchedLocation;
      final isPublic = loc == '/' || loc.startsWith('/onboarding') ||
          loc.startsWith('/login') || loc.startsWith('/register') ||
          loc.startsWith('/verify-email') || loc.startsWith('/pending');

      if (status == AuthStatus.unknown) return '/';
      if (status == AuthStatus.unauthenticated && !isPublic) return '/login';
      if (status == AuthStatus.authenticated) {
        // Must verify email before anything else
        if (!authState.isEmailVerified && loc != '/verify-email') return '/verify-email';
        if (authState.isPendingRider && loc != '/pending') return '/pending';
        if (!authState.isPendingRider && isPublic && loc != '/pending') return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/verify-email', builder: (_, __) => const VerifyEmailScreen()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingApprovalScreen()),

      ShellRoute(
        builder: (context, state, child) => RiderShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/jobs', builder: (_, __) => const JobsScreen()),
          GoRoute(path: '/earnings', builder: (_, __) => const EarningsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const RiderProfileScreen()),
        ],
      ),

      GoRoute(
        path: '/job/:jobId',
        builder: (context, state) =>
            JobDetailScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/job/:jobId/accepted',
        builder: (context, state) =>
            JobAcceptedScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/delivery/:packageId',
        builder: (context, state) =>
            ActiveDeliveryScreen(packageId: state.pathParameters['packageId']!),
      ),
      GoRoute(
        path: '/delivery/:packageId/complete',
        builder: (context, state) => DeliveryCompleteScreen(
          packageId: state.pathParameters['packageId']!,
          earnings: double.tryParse(
                  state.uri.queryParameters['earnings'] ?? '') ??
              0,
        ),
      ),
      GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
      GoRoute(path: '/withdrawal', builder: (_, __) => const WithdrawalScreen()),
      GoRoute(path: '/payout-settings', builder: (_, __) => const PayoutSettingsScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditRiderProfileScreen()),
      GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(path: '/vehicle-docs', builder: (_, __) => const VehicleDocumentsScreen()),
      GoRoute(path: '/performance', builder: (_, __) => const PerformanceScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(
        path: '/chat/:packageId',
        builder: (context, state) =>
            PackageChatScreen(packageId: state.pathParameters['packageId']!),
      ),
      GoRoute(
        path: '/ratings/:riderId',
        builder: (context, state) => RatingsScreen(
          riderId: state.pathParameters['riderId']!,
          riderName: state.uri.queryParameters['name'],
        ),
      ),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
    ],
  );
});
