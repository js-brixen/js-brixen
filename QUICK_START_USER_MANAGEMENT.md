# 🚀 Quick Start: User Management & Settings

## 1️⃣ Deploy Firestore Rules

```bash
cd "c:\rivanapps\unused\jscons\js web2\js website"
firebase deploy --only firestore:rules
```

---

## 2️⃣ Create First Admin User

### In Firebase Console:

**Authentication → Users → Add User**
- Email: `admin@jsconstruction.com`
- Password: [your secure password]
- **Copy the User UID!**

**Firestore Database → users collection → Add Document**
- Document ID: [paste User UID]
- Fields:
```json
{
  "uid": "[User UID]",
  "email": "admin@jsconstruction.com",
  "displayName": "Admin",
  "role": "admin",
  "status": "active",
  "createdAt": [timestamp - current time],
  "createdBy": "manual",
  "updatedAt": [timestamp - current time],
  "notificationPrefs": {
    "bookingAlerts": true,
    "systemNotifications": true
  }
}
```

---

## 3️⃣ Test the App

1. **Hot reload Flutter app** (press `R` in terminal or restart)
2. **Login** with admin credentials
3. **Navigate to Users** → Verify admin user appears
4. **Click "+ Add User"** → Create a staff user
5. **Sign back in** (you'll be logged out temporarily)
6. **Navigate to Settings** → Test notification toggles
7. **Test logout** → Verify redirects to login

---

## 📝 Key Features

### User Management (Admin Only)
- ✅ Add/Edit/Delete users
- ✅ Assign roles (Admin/Staff)
- ✅ Enable/Disable users
- ✅ Send password reset emails
- ✅ Search and filter users

### Settings (All Users)
- ✅ View profile
- ✅ Manage notification preferences
- ✅ Logout
- ✅ View last login time

### Login Screen
- ✅ Removed self-registration
- ✅ Added "Forgot Password" link
- ✅ Auto-load user profile on login

---

## ⚠️ Important Notes

1. **First admin MUST be created in Firebase Console**
2. **Creating a user will temporarily sign you out** (expected behavior)
3. **Firestore rules must be deployed** before testing
4. **User deletion only removes from Firestore**, not Firebase Auth

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied | Deploy Firestore rules |
| Can't see users | Refresh screen, check Firestore console |
| Temporarily signed out | Expected - sign back in with admin |
| Settings loading forever | Verify UserProvider in main.dart |

---

## 📚 Full Documentation

- **Setup Guide**: `USER_MANAGEMENT_SETUP.md`
- **Implementation Summary**: `USER_MANAGEMENT_SUMMARY.md`
