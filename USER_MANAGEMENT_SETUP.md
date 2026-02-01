# User Management & Settings Setup Guide

This guide will help you set up and test the User Management and Settings features for the JS Construction Admin App.

---

## Prerequisites

Before you begin, ensure you have:
- Firebase project configured
- Flutter app connected to Firebase
- Firebase Authentication enabled (Email/Password provider)
- Firestore Database created

---

## Step 1: Deploy Updated Firestore Security Rules

The security rules have been updated to support user management with role-based access control.

### Deploy the rules:

```bash
firebase deploy --only firestore:rules
```

### Verify deployment:
1. Go to Firebase Console → Firestore Database → Rules
2. Confirm the rules include `isAdmin()` and `isAuthenticated()` helper functions
3. Confirm `users` collection rules are present

---

## Step 2: Create First Admin User

**IMPORTANT**: The first admin user MUST be created manually in Firebase Console.

### 2.1 Create User in Firebase Authentication

1. Go to **Firebase Console** → **Authentication** → **Users**
2. Click **Add User**
3. Enter:
   - Email: `admin@jsconstruction.com` (or your preferred admin email)
   - Password: Choose a secure password (min 6 characters)
4. Click **Add User**
5. **COPY THE USER UID** shown in the users list (you'll need this in the next step)

### 2.2 Create User Document in Firestore

1. Go to **Firebase Console** → **Firestore Database**
2. If the `users` collection doesn't exist, click **+ Start collection**
   - Collection ID: `users`
   - Click **Next**
3. Create a document:
   - **Document ID**: Paste the **User UID** from step 2.1
   - Click **Auto-ID** if you want to use a different ID (not recommended)
4. Add the following fields (click **+ Add field** for each):

| Field Name | Type | Value |
|------------|------|-------|
| `uid` | string | [paste the User UID] |
| `email` | string | admin@jsconstruction.com |
| `displayName` | string | Admin |
| `role` | string | admin |
| `status` | string | active |
| `createdAt` | timestamp | [click "Set to current time"] |
| `createdBy` | string | manual |
| `updatedAt` | timestamp | [click "Set to current time"] |
| `notificationPrefs` | map | (see below) |

5. For `notificationPrefs` map, add these fields:
   - `bookingAlerts`: boolean → `true`
   - `systemNotifications`: boolean → `true`

6. Click **Save**

---

## Step 3: Test Login with Admin User

1. Stop and restart your Flutter app:
   ```bash
   # In the terminal where flutter run is active, press 'r' to hot reload
   # Or stop and run again:
   flutter run
   ```

2. On the login screen:
   - Enter the admin email you created
   - Enter the password
   - Click **Login**

3. You should be redirected to the admin dashboard

---

## Step 4: Verify User Management Features

### 4.1 Access Users Screen
1. From the admin dashboard, navigate to **Users** (from the drawer menu)
2. You should see the admin user you created listed
3. Verify the user card shows:
   - Display name
   - Email
   - "ADMIN" role badge (lime green)
   - "ACTIVE" status indicator (green)

### 4.2 Add a New User
1. Click the **+ Add User** floating action button
2. Fill in the form:
   - Email: `staff@jsconstruction.com`
   - Display Name: `Staff User`
   - Password: Click the refresh icon to generate a password (or enter manually)
   - Role: Select **Staff**
3. Click **Create User**
4. **IMPORTANT**: You will be temporarily signed out. Sign back in with your admin credentials.
5. Navigate back to Users screen and verify the new staff user appears

### 4.3 Edit a User
1. Click on the staff user card
2. In the edit dialog:
   - Change the display name to `Test Staff`
   - Change role to **Admin** (then back to **Staff**)
   - Toggle status to **Disabled** (then back to **Active**)
   - Click **Save Changes**
3. Verify the changes are reflected in the user list

### 4.4 Reset Password
1. Click on a user card to edit
2. Click **Send Password Reset Email**
3. Confirm the action
4. Check the user's email inbox for the password reset email

### 4.5 Test Staff Access Restrictions
1. Logout from admin account
2. Login as the staff user (use password reset email if needed)
3. Navigate to **Users** screen
4. Verify you see "Access Denied" message
5. Verify staff cannot access user management

---

## Step 5: Verify Settings Features

### 5.1 Access Settings Screen
1. Login as admin
2. Navigate to **Settings** from the drawer menu
3. Verify you see:
   - Profile card with avatar, name, email, role badge
   - Last login timestamp (if available)

### 5.2 Test Notification Preferences
1. Toggle **Booking Alerts** off
2. Navigate away and come back to Settings
3. Verify the toggle state is persisted
4. Check Firestore → `users` → [your UID] → `notificationPrefs.bookingAlerts` is `false`
5. Toggle it back on

### 5.3 Test Logout
1. Click **Logout** in Session Management section
2. Confirm the logout dialog
3. Verify you're redirected to the login screen
4. Verify you cannot access protected routes without logging in

---

## Step 6: Test Forgot Password

1. On the login screen, enter an email address
2. Click **Forgot Password?**
3. Check the email inbox for password reset link
4. Click the link and set a new password
5. Login with the new password

---

## Troubleshooting

### Issue: "Permission denied" when creating user
**Solution**: Ensure you're logged in as an admin user and Firestore rules are deployed correctly.

### Issue: "User created successfully but I can't see them in the list"
**Solution**: 
1. Check Firestore console to verify the user document was created
2. Refresh the Users screen
3. Check that the user has a valid `role` field

### Issue: "Cannot read user profile"
**Solution**: 
1. Verify the user document exists in Firestore with the correct UID
2. Check that all required fields are present
3. Ensure Firestore rules allow reading your own profile

### Issue: "Temporarily signed out when creating user"
**Solution**: This is expected behavior with the client-side user creation approach. Simply sign back in with your admin credentials.

### Issue: Settings screen shows "Loading user profile..." forever
**Solution**:
1. Check that UserProvider is added to main.dart
2. Verify the user document exists in Firestore
3. Check browser/app console for errors

---

## Security Notes

1. **First Admin**: Always create the first admin manually in Firebase Console
2. **Password Reset**: Only works for users with verified email addresses
3. **User Deletion**: Currently only deletes from Firestore, not from Firebase Auth (requires Cloud Functions for full deletion)
4. **Role Changes**: Take effect immediately but may require app restart to reflect in UI

---

## Next Steps

After successful setup:
1. Create additional admin or staff users as needed
2. Configure notification preferences for each user
3. Test role-based access control across all features
4. Consider implementing Cloud Functions for server-side user creation (optional)

---

## Support

If you encounter issues:
1. Check the Flutter console for error messages
2. Check Firebase Console → Firestore → Rules for rule errors
3. Verify all Firestore documents have the correct structure
4. Ensure Firebase Authentication Email/Password provider is enabled
