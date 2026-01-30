import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream all users (admin only)
  Stream<List<AppUser>> streamAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList(),
        );
  }

  // Get user by ID
  Future<AppUser?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      throw 'Failed to get user: $e';
    }
  }

  // Get current user profile
  Future<AppUser?> getCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    return getUserById(currentUser.uid);
  }

  // Create user with role (admin only)
  // Uses a secondary auth instance to avoid signing out the current admin
  Future<String> createUserWithRole({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    // Store current admin user
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw 'You must be logged in to create users';
    }

    try {
      // Create a secondary Firebase Auth instance
      final secondaryAuth = FirebaseAuth.instanceFor(app: _auth.app);

      // Create the new user using the secondary instance
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUid = userCredential.user!.uid;

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);

      // Create user document in Firestore
      await _firestore.collection('users').doc(newUid).set({
        'uid': newUid,
        'email': email,
        'displayName': displayName,
        'role': role,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'notificationPrefs': {
          'bookingAlerts': true,
          'systemNotifications': true,
        },
      });

      // Sign out the new user from the secondary instance
      await secondaryAuth.signOut();

      return newUid;
    } catch (e) {
      throw 'Failed to create user: $e';
    }
  }

  // Update user role (admin only)
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update user role: $e';
    }
  }

  // Update user status (admin only)
  Future<void> updateUserStatus(String uid, String status) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update user status: $e';
    }
  }

  // Update display name
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update Firebase Auth display name if it's the current user
      if (_auth.currentUser?.uid == uid) {
        await _auth.currentUser!.updateDisplayName(displayName);
      }
    } catch (e) {
      throw 'Failed to update display name: $e';
    }
  }

  // Delete user (admin only)
  // Note: This only deletes from Firestore, not from Firebase Auth
  // Deleting from Auth requires Cloud Functions or Admin SDK
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw 'Failed to delete user: $e';
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPrefs(
    String uid,
    NotificationPrefs prefs,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'notificationPrefs': prefs.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update notification preferences: $e';
    }
  }

  // Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - not critical
      print('Failed to update last login: $e');
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String uid) async {
    final user = await getUserById(uid);
    return user?.isAdmin ?? false;
  }

  // Check if user is active
  Future<bool> isUserActive(String uid) async {
    final user = await getUserById(uid);
    return user?.isActive ?? false;
  }
}
