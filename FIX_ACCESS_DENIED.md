# Fix Access Denied Issue

## Problem
Your user document in Firestore only has `role: "admin"` but is missing other required fields.

## Solution: Add Missing Fields to Your User Document

### Step 1: Go to Firestore Console
1. Open Firebase Console → Firestore Database
2. Navigate to `users` collection
3. Click on your user document (the one with your UID: `gYwZsNkATOWe...`)

### Step 2: Add These Fields

Click **"+ Add field"** for each of these:

| Field Name | Type | Value |
|------------|------|-------|
| `uid` | string | `gYwZsNkATOWeJFwMMyR956...` (your full UID) |
| `email` | string | `sibijose331here@gmail.com` |
| `displayName` | string | `Admin` (or your name) |
| `status` | string | `active` |
| `createdAt` | timestamp | Click "Set to current time" |
| `createdBy` | string | `manual` |
| `updatedAt` | timestamp | Click "Set to current time" |
| `notificationPrefs` | map | (see below) |

### Step 3: Add notificationPrefs Map

For the `notificationPrefs` field:
1. Type: **map**
2. Click the expand arrow
3. Add these sub-fields:
   - `bookingAlerts`: boolean → `true`
   - `systemNotifications`: boolean → `true`

### Step 4: Save and Test

1. Click **Save**
2. Go back to your Flutter app
3. **Logout** (if you can access settings)
4. **Login again** with your credentials
5. Navigate to **Users** screen
6. You should now see the user list instead of "Access Denied"

---

## Alternative: Delete and Recreate

If you prefer to start fresh:

1. **Delete** the current user document in Firestore
2. **Keep** the user in Firebase Authentication
3. **Create a new document** in the `users` collection:
   - Document ID: `gYwZsNkATOWeJFwMMyR956...` (your UID from Authentication)
   - Add all fields from the table above

---

## Quick Copy-Paste Values

Here are the exact values for your user:

```
uid: gYwZsNkATOWeJFwMMyR956...
email: sibijose331here@gmail.com
displayName: Admin
role: admin
status: active
createdAt: [timestamp - current time]
createdBy: manual
updatedAt: [timestamp - current time]
notificationPrefs: {
  bookingAlerts: true,
  systemNotifications: true
}
```

---

## Why This Happened

The app checks if you're an admin by:
1. Reading your user document from Firestore
2. Checking the `role` field

But the `AppUser` model expects ALL fields to exist. When fields are missing, the app can't load your profile, so it thinks you're not an admin.

---

## After Fixing

Once you add all fields:
- ✅ Users screen will show your user
- ✅ Settings screen will show your profile
- ✅ You can add new users
- ✅ All admin features will work
