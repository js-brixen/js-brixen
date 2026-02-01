import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_admin_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authService = AuthService();
      await authService.signOut();

      if (context.mounted) {
        context.read<UserProvider>().clearUser();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAllBookings(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Delete All Bookings',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete ALL bookings? This action cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = FirestoreAdminService();
      await service.deleteAllBookings();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All bookings deleted successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete bookings: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAllProjects(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Delete All Projects',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete ALL projects? This action cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = FirestoreAdminService();
      await service.deleteAllProjects();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All projects deleted successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete projects: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAllServices(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Delete All Services',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete ALL services? This action cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = FirestoreAdminService();
      await service.deleteAllServices();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All services deleted successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete services: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAllNotifications(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Delete All Notifications',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete ALL notifications? This action cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = FirestoreAdminService();
      await service.deleteAllNotifications();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications deleted successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notifications: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _handleClearAnalytics(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Clear Analytics',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear ALL analytics data? This action cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = FirestoreAdminService();
      await service.clearAnalytics();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Analytics data cleared successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear analytics: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings'), elevation: 0),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                  const Color(0xFF0f3460),
                ],
              ),
            ),
            child: currentUser == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading user profile...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 100, // Extra padding to clear bottom navigation
                    ),
                    children: [
                      // Profile Section
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: currentUser.isAdmin
                                    ? Colors.lime.shade600
                                    : Colors.blue.shade600,
                                child: Text(
                                  currentUser.displayName.isNotEmpty
                                      ? currentUser.displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                currentUser.displayName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentUser.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: currentUser.isAdmin
                                      ? Colors.lime.shade600
                                      : Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currentUser.role.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (currentUser.lastLoginAt != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Last login: ${DateFormat('MMM d, y - h:mm a').format(currentUser.lastLoginAt!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Notification Preferences
                      const Text(
                        'Notification Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text(
                                'Booking Alerts',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Get notified when new bookings arrive',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              value:
                                  currentUser.notificationPrefs.bookingAlerts,
                              activeColor: Colors.lime.shade600,
                              onChanged: (value) {
                                userProvider.updateNotificationPrefs(
                                  currentUser.notificationPrefs.copyWith(
                                    bookingAlerts: value,
                                  ),
                                );
                              },
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            SwitchListTile(
                              title: const Text(
                                'System Notifications',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Get notified about system updates',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              value: currentUser
                                  .notificationPrefs
                                  .systemNotifications,
                              activeColor: Colors.lime.shade600,
                              onChanged: (value) {
                                userProvider.updateNotificationPrefs(
                                  currentUser.notificationPrefs.copyWith(
                                    systemNotifications: value,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Booking Settings (Moved to consolidated section below)
                      // Booking Controls (Admin only)
                      if (currentUser.isAdmin) ...[
                        const BookingControlsSection(),
                        const SizedBox(height: 24),
                      ],

                      // Data Management (Admin only)
                      if (currentUser.isAdmin) ...[
                        const Text(
                          'Data Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade600.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.delete_sweep,
                                    color: Colors.orange.shade400,
                                  ),
                                ),
                                title: const Text(
                                  'Delete All Bookings',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Permanently delete all bookings',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 16,
                                ),
                                onTap: () => _handleDeleteAllBookings(context),
                              ),
                              Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade600.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.delete_sweep,
                                    color: Colors.orange.shade400,
                                  ),
                                ),
                                title: const Text(
                                  'Delete All Projects',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Permanently delete all projects',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 16,
                                ),
                                onTap: () => _handleDeleteAllProjects(context),
                              ),
                              Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade600.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.delete_sweep,
                                    color: Colors.orange.shade400,
                                  ),
                                ),
                                title: const Text(
                                  'Delete All Services',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Permanently delete all services',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 16,
                                ),
                                onTap: () => _handleDeleteAllServices(context),
                              ),
                              Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade600.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.delete_sweep,
                                    color: Colors.orange.shade400,
                                  ),
                                ),
                                title: const Text(
                                  'Delete All Notifications',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Permanently delete all notifications',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 16,
                                ),
                                onTap: () =>
                                    _handleDeleteAllNotifications(context),
                              ),
                              Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade600.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.analytics_outlined,
                                    color: Colors.purple.shade400,
                                  ),
                                ),
                                title: const Text(
                                  'Clear Analytics',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Clear all analytics data',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 16,
                                ),
                                onTap: () => _handleClearAnalytics(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Session Management
                      const Text(
                        'Session Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.logout,
                                  color: Colors.red.shade400,
                                ),
                              ),
                              title: const Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Sign out of your account',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 16,
                              ),
                              onTap: () => _handleLogout(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App Info
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.info_outline,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              title: const Text(
                                'Version',
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: Text(
                                '1.0.0',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.support_agent,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              title: const Text(
                                'Support',
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 16,
                              ),
                              onTap: () {
                                // TODO: Add support contact
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Contact: support@jsconstruction.com',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Booking Controls Section Widget
class BookingControlsSection extends StatefulWidget {
  const BookingControlsSection({super.key});

  @override
  State<BookingControlsSection> createState() => _BookingControlsSectionState();
}

class _BookingControlsSectionState extends State<BookingControlsSection> {
  bool _isLoading = true;
  int _cooldownSeconds = 5 * 60; // Default 5 mins
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);

      final firestore = FirebaseFirestore.instance;
      final doc = await firestore
          .collection('appSettings')
          .doc('general')
          .get();

      if (doc.exists) {
        final data = doc.data();
        int cooldown = 300;

        if (data != null) {
          if (data.containsKey('bookingCooldownSeconds')) {
            cooldown = data['bookingCooldownSeconds'];
          } else if (data.containsKey('bookingCooldownMinutes')) {
            cooldown = (data['bookingCooldownMinutes'] as num).toInt() * 60;
          }
        }

        setState(() {
          _cooldownSeconds = cooldown;
          _isLoading = false;
        });
      } else {
        // Create default document if it doesn't exist
        await firestore.collection('appSettings').doc('general').set({
          'bookingCooldownSeconds': 300,
          'bookingCooldownMinutes': 5,
          'updatedAt': DateTime.now(),
        });
        setState(() {
          _cooldownSeconds = 300;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
      }
    }
  }

  Future<void> _saveCooldown() async {
    try {
      setState(() => _isSaving = true);

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('appSettings').doc('general').set({
        'bookingCooldownSeconds': _cooldownSeconds,
        'bookingCooldownMinutes': (_cooldownSeconds / 60)
            .round(), // Legacy support
        'updatedAt': DateTime.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cooldown set to ${_formatDuration(_cooldownSeconds)}',
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours h $minutes m $seconds s';
    }
    return '$minutes m $seconds s';
  }

  void _updateCooldown(int hours, int minutes, int seconds) {
    final total = (hours * 3600) + (minutes * 60) + seconds;
    setState(() => _cooldownSeconds = total);
    _saveCooldown();
  }

  Widget _buildTimeInput(
    BuildContext context,
    String label,
    int value,
    Function(int) onChanged, {
    int max = 59,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1a1a2e),
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: List.generate(max + 1, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cooldownDuration = Duration(seconds: _cooldownSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Cooldown Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.hourglass_bottom,
                                color: Colors.lime.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Booking Cooldown Period',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Minimum time between booking submissions',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // H:M:S Inputs
                          Row(
                            children: [
                              _buildTimeInput(
                                context,
                                'Hours',
                                cooldownDuration.inHours,
                                (val) => _updateCooldown(
                                  val,
                                  cooldownDuration.inMinutes % 60,
                                  cooldownDuration.inSeconds % 60,
                                ),
                                max: 23,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                ':',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildTimeInput(
                                context,
                                'Minutes',
                                cooldownDuration.inMinutes % 60,
                                (val) => _updateCooldown(
                                  cooldownDuration.inHours,
                                  val,
                                  cooldownDuration.inSeconds % 60,
                                ),
                                max: 59,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                ':',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildTimeInput(
                                context,
                                'Seconds',
                                cooldownDuration.inSeconds % 60,
                                (val) => _updateCooldown(
                                  cooldownDuration.inHours,
                                  cooldownDuration.inMinutes % 60,
                                  val,
                                ),
                                max: 59,
                              ),
                            ],
                          ),

                          if (_isSaving)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: LinearProgressIndicator(),
                            ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade900.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.shade600.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _cooldownSeconds == 0
                                        ? 'Users can submit bookings immediately without waiting'
                                        : 'Users must wait ${_formatDuration(_cooldownSeconds)} between submissions',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
