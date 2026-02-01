import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../providers/dashboard_provider.dart';
import '../providers/bookings_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/admin_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardProvider>().refresh();
            },
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<DashboardProvider>().refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildMetricsGrid(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (dashboardProvider.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade400,
                  ),
                const SizedBox(height: 4),
                Text(
                  dashboardProvider.stats.timeSinceCalculation,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricsGrid() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final stats = dashboardProvider.stats;
        final isLoading = dashboardProvider.isLoading;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: [
            // New Bookings Today
            MetricCard(
              title: 'New Bookings Today',
              value: stats.newBookingsToday.toString(),
              trend: stats.newBookingsTrendText,
              icon: Icons.event_available,
              color: const Color(0xFF4A90E2),
              isLoading: isLoading,
              onTap: () => _navigateToBookings(context, filterToday: true),
            ),
            // Open Leads
            MetricCard(
              title: 'Open Leads',
              value: stats.totalOpenLeads.toString(),
              trend: stats.openLeadsTrendText,
              icon: Icons.people_outline,
              color: const Color(0xFFFF9500),
              isLoading: isLoading,
              onTap: () => _navigateToBookings(context, filterOpen: true),
            ),
            // Most Viewed Project
            MetricCard(
              title: 'Most Viewed Project',
              value: stats.mostViewedProject?.title ?? 'No projects',
              subtitle: stats.mostViewedProjectViews > 0
                  ? '${stats.mostViewedProjectViews} views'
                  : null,
              icon: Icons.visibility,
              color: const Color(0xFF9B59B6),
              isLoading: isLoading,
              onTap: () => _navigateToProjects(context),
            ),
            // Top Service
            MetricCard(
              title: 'Top Service',
              value: stats.mostRequestedService ?? 'No data',
              subtitle: stats.mostRequestedServiceCount > 0
                  ? '${stats.mostRequestedServiceCount} requests'
                  : null,
              icon: Icons.construction,
              color: const Color(0xFF2ECC71),
              isLoading: isLoading,
              onTap: () => _navigateToServices(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Consumer<BookingsProvider>(
      builder: (context, bookingsProvider, _) {
        final newBookingsCount = bookingsProvider.getCountByStatus(
          BookingStatus.newBooking,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                QuickActionButton(
                  icon: Icons.add_business,
                  label: 'Add Project',
                  color: const Color(0xFF4A90E2),
                  onTap: () => _navigateToAddProject(context),
                ),
                QuickActionButton(
                  icon: Icons.notifications_active,
                  label: 'View New Bookings',
                  badge: newBookingsCount > 0 ? '$newBookingsCount' : null,
                  color: const Color(0xFFFF9500),
                  onTap: () => _navigateToBookings(context, filterNew: true),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Navigation methods - Switch tabs instead of pushing routes
  void _navigateToBookings(
    BuildContext context, {
    bool filterToday = false,
    bool filterOpen = false,
    bool filterNew = false,
  }) {
    // Apply filters to BookingsProvider before switching tabs
    final bookingsProvider = context.read<BookingsProvider>();

    if (filterToday) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      bookingsProvider.setDateRange(startOfDay, endOfDay);
    } else if (filterOpen) {
      bookingsProvider.setStatusFilter([
        'new',
        'contacted',
        'follow_up',
        'scheduled',
      ]);
    } else if (filterNew) {
      bookingsProvider.setStatusFilter(['new']);
    } else {
      // Clear filters for general navigation
      bookingsProvider.clearFilters();
    }

    // Switch to bookings tab (index 1)
    _switchTab(context, 1);
  }

  void _navigateToProjects(BuildContext context) {
    // Switch to projects tab (index 2)
    _switchTab(context, 2);
  }

  void _navigateToServices(BuildContext context) {
    // Switch to services tab (index 3)
    _switchTab(context, 3);
  }

  void _navigateToAddProject(BuildContext context) {
    // Switch to projects tab first
    _switchTab(context, 2);
    // Then trigger the add project flow (you can add a callback or use a provider)
    // For now, just switch to projects tab where they can manually add
  }

  // Helper method to switch tabs in AdminShell
  void _switchTab(BuildContext context, int index) {
    // Find the AdminShell ancestor and call its method
    final adminShellState = context.findAncestorStateOfType<AdminShellState>();
    if (adminShellState != null) {
      adminShellState.switchTab(index);
    }
  }
}
