import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../routes.dart';

class AdminNavDrawer extends StatelessWidget {
  final Function(String) onNavigate;

  const AdminNavDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.cyan.shade400],
                        ),
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'JS Construction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? 'Admin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.2)),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      route: AppRoutes.dashboard,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.calendar_today_outlined,
                      title: 'Bookings / Leads',
                      route: AppRoutes.bookings,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.business_center_outlined,
                      title: 'Projects',
                      route: AppRoutes.projects,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.design_services_outlined,
                      title: 'Services',
                      route: AppRoutes.services,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.article_outlined,
                      title: 'Content',
                      route: AppRoutes.content,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.analytics_outlined,
                      title: 'Analytics',
                      route: AppRoutes.analytics,
                    ),
                    _buildNotificationsNavItem(context),
                    _buildNavItem(
                      context,
                      icon: Icons.people_outlined,
                      title: 'Users',
                      route: AppRoutes.users,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      route: AppRoutes.settings,
                    ),
                  ],
                ),
              ),

              // Logout Button
              Divider(color: Colors.white.withValues(alpha: 0.2)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.login);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isCurrentRoute = ModalRoute.of(context)?.settings.name == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isCurrentRoute
            ? Colors.cyan.shade400
            : Colors.white.withOpacity(0.8),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isCurrentRoute
              ? Colors.cyan.shade400
              : Colors.white.withOpacity(0.9),
          fontWeight: isCurrentRoute ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isCurrentRoute,
      selectedTileColor: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        if (!isCurrentRoute) {
          onNavigate(route);
        }
      },
    );
  }

  Widget _buildNotificationsNavItem(BuildContext context) {
    final isCurrentRoute =
        ModalRoute.of(context)?.settings.name == AppRoutes.notifications;
    final notificationService = NotificationService();

    return StreamBuilder<int>(
      stream: notificationService.streamUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: isCurrentRoute
                    ? Colors.cyan.shade400
                    : Colors.white.withOpacity(0.8),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1a1a2e),
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            'Notifications',
            style: TextStyle(
              color: isCurrentRoute
                  ? Colors.cyan.shade400
                  : Colors.white.withOpacity(0.9),
              fontWeight: isCurrentRoute ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isCurrentRoute,
          selectedTileColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () {
            Navigator.of(context).pop();
            if (!isCurrentRoute) {
              onNavigate(AppRoutes.notifications);
            }
          },
        );
      },
    );
  }
}
