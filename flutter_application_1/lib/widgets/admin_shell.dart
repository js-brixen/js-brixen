import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_nav_drawer.dart';
import '../screens/dashboard_screen.dart';
import '../screens/bookings_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/services_screen.dart';
import '../providers/user_provider.dart';
import '../routes.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => AdminShellState();
}

class AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load current user profile when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadCurrentUser();
    });
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    BookingsScreen(),
    ProjectsScreen(),
    ServicesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToSection(String route) {
    // Map routes to tab indices
    final routeToIndex = {
      AppRoutes.dashboard: 0,
      AppRoutes.bookings: 1,
      AppRoutes.projects: 2,
      AppRoutes.services: 3,
    };

    if (routeToIndex.containsKey(route)) {
      _onItemTapped(routeToIndex[route]!);
    } else {
      // For non-main sections, navigate normally
      Navigator.of(context).pushNamed(route);
    }
  }

  // Public method to switch tabs programmatically
  void switchTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AdminNavDrawer(onNavigate: _navigateToSection),
      appBar: _selectedIndex != 0
          ? AppBar(
              title: Text(_getTitle()),
              elevation: 0,
              backgroundColor: const Color(0xFF1a1a2e),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            )
          : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF1a1a2e),
        selectedItemColor: Colors.cyan.shade400,
        unselectedItemColor: Colors.white.withValues(alpha: 0.6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.design_services),
            label: 'Services',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Bookings';
      case 2:
        return 'Projects';
      case 3:
        return 'Services';
      default:
        return 'JS Construction Admin';
    }
  }
}
