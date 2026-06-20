import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/admin_entities.dart';
import '../../domain/entities/scheduled_class.dart';
import '../../features/admin/presentation/screens/admin_class_form_screen.dart';
import '../../features/admin/presentation/screens/admin_class_waitlist_screen.dart';
import '../../features/admin/presentation/screens/admin_classes_screen.dart';
import '../../features/admin/presentation/screens/admin_client_profile_screen.dart';
import '../../features/admin/presentation/screens/admin_clients_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/payments/presentation/providers/payment_providers.dart';
import '../../features/payments/presentation/screens/checkout_screen.dart';
import '../../features/payments/presentation/screens/membership_plans_screen.dart';
import '../../features/profile/presentation/screens/my_bookings_screen.dart';
import '../../features/profile/presentation/screens/my_memberships_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/schedule/presentation/screens/class_details_screen.dart';
import '../../features/schedule/presentation/screens/schedule_screen.dart';
import '../di/providers.dart';
import 'scaffold_with_nav_bar.dart';

/// Имена/пути маршрутов в одном месте.
abstract class AppRoutes {
  static const login = '/login';
  static const schedule = '/schedule';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const admin = '/admin';
  static const adminClasses = '/admin/classes';
  static const adminClassForm = '/admin/classes/form';
  static const adminClients = '/admin/clients';
  static const adminClientProfile = '/admin/client';
  static const adminClassWaitlist = '/admin/class-waitlist';
  static const adminReports = '/admin/reports';
  static const classDetails = '/class';
  static const myBookings = '/my-bookings';
  static const myMemberships = '/my-memberships';
  static const membershipPlans = '/membership-plans';
  static const checkout = '/checkout';
  static const notificationSettings = '/notification-settings';
}

/// GoRouter, построенный с учётом состояния аутентификации (Riverpod).
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(supabaseClientProvider).auth;

  return GoRouter(
    initialLocation: AppRoutes.schedule,
    debugLogDiagnostics: true,
    // Перестраиваем редиректы при любом событии авторизации.
    refreshListenable: GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final loc = state.matchedLocation;
      final loggingIn = loc == AppRoutes.login;

      // Неавторизованного — на экран входа.
      if (!loggedIn) return loggingIn ? null : AppRoutes.login;
      // Авторизованного с экрана входа — на расписание.
      if (loggingIn) return AppRoutes.schedule;
      // Админ-панель — только для персонала.
      if (loc.startsWith(AppRoutes.admin) && !ref.read(isStaffProvider)) {
        return AppRoutes.schedule;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // Раздел с нижней навигацией (клиентская часть).
      ShellRoute(
        builder: (context, state, child) =>
            ScaffoldWithNavBar(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.schedule,
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.classDetails,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is ScheduledClass) {
            return ClassDetailsScreen(item: extra);
          }
          // Прямой переход без данных (например, по deep link) — вернёмся назад.
          return const _MissingClassScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.myBookings,
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.myMemberships,
        builder: (context, state) => const MyMembershipsScreen(),
      ),
      GoRoute(
        path: AppRoutes.membershipPlans,
        builder: (context, state) => const MembershipPlansScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is CheckoutArgs) {
            return CheckoutScreen(args: extra);
          }
          return const _MissingClassScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminClasses,
        builder: (context, state) => const AdminClassesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminClassForm,
        builder: (context, state) {
          final extra = state.extra;
          return AdminClassFormScreen(
              editing: extra is AdminClass ? extra : null);
        },
      ),
      GoRoute(
        path: AppRoutes.adminClassWaitlist,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is AdminClass) {
            return AdminClassWaitlistScreen(classItem: extra);
          }
          return const _MissingClassScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.adminClients,
        builder: (context, state) => const AdminClientsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminClientProfile,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is String) {
            return AdminClientProfileScreen(clientId: extra);
          }
          return const _MissingClassScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
    ],
  );
});

/// Заглушка на случай открытия деталей занятия без переданных данных.
class _MissingClassScreen extends StatelessWidget {
  const _MissingClassScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('Откройте занятие из расписания'),
      ),
    );
  }
}

/// Адаптер: превращает Stream в Listenable для refreshListenable у GoRouter.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
