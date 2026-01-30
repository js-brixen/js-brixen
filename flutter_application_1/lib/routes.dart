import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/services_screen.dart';
import 'screens/media_screen.dart';
import 'screens/content_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/users_screen.dart';
import 'screens/settings_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String bookings = '/bookings';
  static const String projects = '/projects';
  static const String services = '/services';
  static const String media = '/media';
  static const String content = '/content';
  static const String analytics = '/analytics';
  static const String notifications = '/notifications';
  static const String users = '/users';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      dashboard: (context) => const DashboardScreen(),
      bookings: (context) => const BookingsScreen(),
      projects: (context) => const ProjectsScreen(),
      services: (context) => const ServicesScreen(),
      media: (context) => const MediaScreen(),
      content: (context) => const ContentScreen(),
      analytics: (context) => const AnalyticsScreen(),
      notifications: (context) => const NotificationsScreen(),
      users: (context) => const UsersScreen(),
      settings: (context) => const SettingsScreen(),
    };
  }
}
