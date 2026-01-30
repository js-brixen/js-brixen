import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/app_user.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/edit_user_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  String _filterRole = 'all';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.isAdmin) {
        userProvider.streamAllUsers();
      }
    });
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        onCreateUser:
            ({
              required String email,
              required String password,
              required String displayName,
              required String role,
            }) async {
              await context.read<UserProvider>().createUser(
                email: email,
                password: password,
                displayName: displayName,
                role: role,
              );
            },
      ),
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User created successfully!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    });
  }

  void _showEditUserDialog(AppUser user) {
    final userProvider = context.read<UserProvider>();
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        onUpdateDisplayName: userProvider.updateDisplayName,
        onUpdateRole: userProvider.updateUserRole,
        onUpdateStatus: userProvider.updateUserStatus,
        onDeleteUser: userProvider.deleteUser,
      ),
    );
  }

  List<AppUser> _getFilteredUsers(List<AppUser> users) {
    return users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!user.displayName.toLowerCase().contains(query) &&
            !user.email.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Role filter
      if (_filterRole != 'all' && user.role != _filterRole) {
        return false;
      }

      // Status filter
      if (_filterStatus != 'all' && user.status != _filterStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Check if user is admin
        if (!userProvider.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('User Management'), elevation: 0),
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.shade400.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        Icons.block,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Only administrators can manage users',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final filteredUsers = _getFilteredUsers(userProvider.allUsers);

        return Scaffold(
          appBar: AppBar(
            title: const Text('User Management'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => userProvider.streamAllUsers(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddUserDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add User'),
            backgroundColor: Colors.lime.shade600,
            foregroundColor: Colors.black,
          ),
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
            child: Column(
              children: [
                // Search and Filters
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name or email...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filters
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterRole,
                              dropdownColor: const Color(0xFF16213e),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Role',
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All Roles'),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('Admin'),
                                ),
                                DropdownMenuItem(
                                  value: 'staff',
                                  child: Text('Staff'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _filterRole = value!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterStatus,
                              dropdownColor: const Color(0xFF16213e),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Status',
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All Status'),
                                ),
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: 'disabled',
                                  child: Text('Disabled'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _filterStatus = value!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // User List
                Expanded(
                  child: filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty ||
                                        _filterRole != 'all' ||
                                        _filterStatus != 'all'
                                    ? 'No users match your filters'
                                    : 'No users found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _UserCard(
                              user: user,
                              onTap: () => _showEditUserDialog(user),
                            );
                          },
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

class _UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: user.isAdmin
                    ? Colors.lime.shade600
                    : Colors.blue.shade600,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.isAdmin
                                ? Colors.lime.shade600
                                : Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? Colors.green.shade600.withValues(alpha: 0.2)
                      : Colors.red.shade600.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: user.isActive
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isActive ? Icons.check_circle : Icons.block,
                      size: 16,
                      color: user.isActive
                          ? Colors.green.shade400
                          : Colors.red.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: user.isActive
                            ? Colors.green.shade400
                            : Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
