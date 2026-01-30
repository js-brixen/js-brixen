import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  AppUser? _currentUser;
  List<AppUser> _allUsers = [];
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  List<AppUser> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;

  // Load current user profile
  Future<void> loadCurrentUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentUser = await _userService.getCurrentUserProfile();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream all users (admin only)
  void streamAllUsers() {
    _userService.streamAllUsers().listen(
      (users) {
        _allUsers = users;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // Create user with role
  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.createUserWithRole(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update user role
  Future<void> updateUserRole(String uid, String role) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.updateUserRole(uid, role);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update user status
  Future<void> updateUserStatus(String uid, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.updateUserStatus(uid, status);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update display name
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.updateDisplayName(uid, displayName);

      // Refresh current user if it's them
      if (_currentUser?.uid == uid) {
        await loadCurrentUser();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.deleteUser(uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPrefs(NotificationPrefs prefs) async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.updateNotificationPrefs(_currentUser!.uid, prefs);

      // Update local state
      _currentUser = _currentUser!.copyWith(notificationPrefs: prefs);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update last login
  Future<void> updateLastLogin() async {
    if (_currentUser == null) return;
    await _userService.updateLastLogin(_currentUser!.uid);
  }

  // Clear state on logout
  void clearUser() {
    _currentUser = null;
    _allUsers = [];
    _error = null;
    notifyListeners();
  }
}
