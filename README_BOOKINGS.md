# Bookings / Leads Management - Implementation Guide

## Overview

This document explains how to set up, test, and maintain the Bookings/Leads Management system for the JS Construction admin app.

---

## Firebase Console Setup (REQUIRED)

### 1. Enable Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/project/js-construction-811e4)
2. Navigate to **Firestore Database** in the left sidebar
3. Click **Create database** (if not already created)
4. Choose **Start in production mode** (we'll add rules next)
5. Select region: `asia-south1` (Mumbai) for best performance

### 2. Update Firestore Security Rules

Go to **Firestore > Rules** tab and paste the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdminOrStaff() {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'staff'];
    }
    
    // Bookings collection
    match /bookings/{bookingId} {
      // Website can CREATE new bookings (public)
      allow create: if request.resource.data.keys().hasAll(['name', 'phone', 'district', 'typeOfWork', 'status', 'source', 'createdAt'])
                    && request.resource.data.status == 'new'
                    && request.resource.data.source in ['website', 'service_page', 'project_page', 'whatsapp'];
      
      // Only admin/staff can READ bookings
      allow read: if isAdminOrStaff();
      
      // Only admin/staff can UPDATE bookings
      allow update: if isAdminOrStaff();
      
      // Only admin can DELETE bookings
      allow delete: if isAdminOrStaff() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      
      // Internal Notes subcollection
      match /internalNotes/{noteId} {
        allow read, write: if isAdminOrStaff();
      }
      
      // Attachments subcollection
      match /attachments/{attachmentId} {
        allow read, write: if isAdminOrStaff();
      }
      
      // Audit log subcollection
      match /audit/{auditId} {
        allow read: if isAdminOrStaff();
        allow create: if isAdminOrStaff();
      }
    }
    
    // Users collection (for role checking)
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAdminOrStaff();
    }
  }
}
```

Click **Publish** to save the rules.

### 3. Create Admin User Document

For the currently logged-in admin user to access bookings:

1. Sign in to the Flutter app
2. Note your Firebase Auth UID (you can find it in Firebase Console > Authentication > Users)
3. Go to **Firestore > Data**
4. Create a new collection called `users`
5. Add a document with ID = your Firebase Auth UID
6. Add the following fields:
   - `role` (string): `"admin"`
   - `email` (string): your email
   - `name` (string): your name
   - `createdAt` (timestamp): current timestamp

**Example:**
```
Collection: users
Document ID: abc123xyz (your Firebase Auth UID)
Fields:
  - role: "admin"
  - email: "admin@jsconstruction.com"
  - name: "Admin User"
  - createdAt: January 26, 2026 at 12:00:00 PM UTC+5:30
```

### 4. Create Composite Indexes

Firestore requires composite indexes for complex queries. Create these indexes:

#### Method 1: Via Firebase Console

1. Go to **Firestore > Indexes** tab
2. Click **Add Index**
3. Create the following indexes:

| Collection | Fields | Order |
|------------|--------|-------|
| `bookings` | `status` (Ascending), `createdAt` (Descending) | |
| `bookings` | `relatedServiceId` (Ascending), `createdAt` (Descending) | |
| `bookings` | `assignedTo` (Ascending), `status` (Ascending), `createdAt` (Descending) | |

#### Method 2: Auto-create from errors

When you first run queries, Firestore will show error messages with links to create the required indexes automatically. Click those links.

---

## Testing the Implementation

### Test 1: Website → Firestore → App Flow

1. **Open website booking form:**
   - Navigate to `http://localhost:5500/public/book-consultation.html` (or your local server)
   
2. **Submit a test booking:**
   - Name: "Test Lead 123"
   - Phone: "9876543210"
   - District: "Ernakulam"
   - Type of Work: "New House Construction"
   - Click "Book Free Consultation"

3. **Verify in Firestore Console:**
   - Go to Firestore > Data > `bookings` collection
   - You should see a new document with the test data
   - Status should be `"new"`

4. **Verify in Flutter app:**
   - Open the Flutter app (should already be running)
   - Navigate to **Bookings** screen
   - Within 2-3 seconds, "Test Lead 123" should appear in the list
   - This confirms real-time sync is working ✅

### Test 2: Status Update

1. In the Flutter app, tap on a booking
2. Tap the overflow menu (⋮) and select "Mark as Contacted"
3. Verify the status chip updates immediately
4. Check Firestore Console → the booking document should have `status: "contacted"`
5. Check the `audit` subcollection → should have a new entry

### Test 3: Add Internal Note

1. Open a booking detail sheet
2. Type a note: "Called customer, will visit tomorrow"
3. Tap send
4. Verify the note appears in the list with your name and timestamp
5. Check Firestore Console → `bookings/{id}/internalNotes/` should have a new document

### Test 4: Filtering

1. Create multiple bookings with different statuses (use website or manually in Firestore)
2. In the app, tap the filter FAB
3. Select only "New" status
4. Tap "Apply"
5. Verify only new bookings are shown

### Test 5: Search

1. In the search bar, type a booking name or phone number
2. Verify the list filters to matching results
3. Clear the search → all bookings reappear

---

## Cloudinary Configuration

The app is configured to use Cloudinary for image attachments:

- **Cloud Name:** `dvtuiyqra`
- **Upload Preset:** `jsconstruct` (unsigned)

### For Production: Switch to Signed Uploads

Unsigned uploads are convenient for development but less secure. For production:

1. Create a Cloud Function to generate signed upload signatures
2. Update `CloudinaryService` to use signed uploads
3. Example Cloud Function:

```javascript
exports.getCloudinarySignature = functions.https.onCall((data, context) => {
  // Verify user is admin/staff
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const timestamp = Math.round(new Date().getTime() / 1000);
  const signature = cloudinary.utils.api_sign_request(
    {
      timestamp: timestamp,
      folder: data.folder || 'bookings',
    },
    process.env.CLOUDINARY_API_SECRET
  );

  return { signature, timestamp };
});
```

---

## Cloud Functions (Stubs Included)

The following Cloud Functions are stubbed in `functions_admin_service.dart`. Implement them for production:

### 1. onBookingCreate Trigger

**Purpose:** Send FCM notifications to admin/staff when a new booking is created from the website.

**Location:** `functions/index.js`

```javascript
exports.onBookingCreate = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    
    // Get all admin/staff FCM tokens
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('role', 'in', ['admin', 'staff'])
      .get();
    
    const tokens = [];
    usersSnapshot.forEach(doc => {
      const userData = doc.data();
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    });
    
    // Send notification
    if (tokens.length > 0) {
      await admin.messaging().sendMulticast({
        tokens: tokens,
        notification: {
          title: '🔔 New Booking',
          body: `${booking.name} - ${booking.typeOfWork}`,
        },
        data: {
          bookingId: context.params.bookingId,
          type: 'new_booking',
        },
      });
    }
    
    // Increment counters (optional)
    await admin.firestore().collection('stats').doc('bookings').set({
      total: admin.firestore.FieldValue.increment(1),
      [`by_status_${booking.status}`]: admin.firestore.FieldValue.increment(1),
    }, { merge: true });
  });
```

### 2. onBookingUpdate Trigger

**Purpose:** Update counters and notify assigned staff when booking status changes.

```javascript
exports.onBookingUpdate = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // If status changed, update counters
    if (before.status !== after.status) {
      await admin.firestore().collection('stats').doc('bookings').set({
        [`by_status_${before.status}`]: admin.firestore.FieldValue.increment(-1),
        [`by_status_${after.status}`]: admin.firestore.FieldValue.increment(1),
      }, { merge: true });
    }
    
    // If assigned, notify the staff member
    if (before.assignedTo !== after.assignedTo && after.assignedTo) {
      const staffDoc = await admin.firestore().collection('users').doc(after.assignedTo).get();
      const staffData = staffDoc.data();
      
      if (staffData?.fcmToken) {
        await admin.messaging().send({
          token: staffData.fcmToken,
          notification: {
            title: '📋 New Assignment',
            body: `You've been assigned to ${after.name}'s booking`,
          },
          data: {
            bookingId: context.params.bookingId,
          },
        });
      }
    }
  });
```

### 3. Scheduled Reminders (Cron)

**Purpose:** Send reminders for bookings that haven't been addressed in 6 hours.

```javascript
exports.scheduledReminders = functions.pubsub
  .schedule('every 6 hours')
  .onRun(async (context) => {
    const sixHoursAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 6 * 60 * 60 * 1000)
    );
    
    const staleBookings = await admin.firestore()
      .collection('bookings')
      .where('status', '==', 'new')
      .where('createdAt', '<', sixHoursAgo)
      .get();
    
    const adminTokens = await getAdminFCMTokens();
    
    for (const doc of staleBookings.docs) {
      const booking = doc.data();
      
      await admin.messaging().sendMulticast({
        tokens: adminTokens,
        notification: {
          title: '⏰ Reminder',
          body: `${booking.name}'s booking hasn't been addressed yet`,
        },
        data: {
          bookingId: doc.id,
        },
      });
    }
  });
```

### 4. Export Bookings CSV

**Purpose:** Generate CSV export of filtered bookings.

```javascript
exports.exportBookingsCSV = functions.https.onCall(async (data, context) => {
  // Verify admin/staff
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  // Query bookings with filters
  let query = admin.firestore().collection('bookings');
  
  if (data.statuses) {
    query = query.where('status', 'in', data.statuses);
  }
  
  const snapshot = await query.get();
  
  // Generate CSV
  const csv = generateCSV(snapshot.docs.map(doc => doc.data()));
  
  // Upload to Cloud Storage
  const bucket = admin.storage().bucket();
  const filename = `exports/bookings_${Date.now()}.csv`;
  const file = bucket.file(filename);
  
  await file.save(csv, { contentType: 'text/csv' });
  
  // Generate signed URL (valid for 1 hour)
  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 60 * 60 * 1000,
  });
  
  return { downloadUrl: url };
});
```

---

## Billing Considerations

### Firestore Reads

- **Real-time listeners:** Each document change triggers a read for all connected clients
- **Recommendation:** Use server-side counters for dashboard stats instead of client-side queries
- **Cost:** ~$0.06 per 100,000 reads (as of 2026)

### Cloud Functions

- **onBookingCreate/Update:** Triggered on every booking change
- **Scheduled reminders:** Runs every 6 hours
- **Cost:** Free tier includes 2M invocations/month

### Cloud Storage (for CSV exports)

- **Storage:** ~$0.026/GB/month
- **Downloads:** ~$0.12/GB

### Optimization Tips

1. Use pagination (limit queries to 20-50 items)
2. Implement server-side counters for stats
3. Cache frequently accessed data
4. Use Firestore `count()` aggregation queries where available

---

## Troubleshooting

### Issue: "Permission denied" when reading bookings

**Solution:** Ensure you've created the `users/{uid}` document with `role: "admin"` for your Firebase Auth user.

### Issue: "Index required" error

**Solution:** Click the link in the error message to auto-create the index, or manually create it in Firebase Console.

### Issue: Bookings not appearing in real-time

**Solution:**
1. Check that the website is writing to Firestore (check browser console for errors)
2. Verify Firestore rules allow public writes to `bookings` collection
3. Ensure Flutter app has internet connection

### Issue: "Module not found" error in booking.js

**Solution:** Ensure `booking.js` script tag has `type="module"` attribute in the HTML.

---

## Next Steps

1. ✅ Test the complete flow (website → Firestore → app)
2. ✅ Create admin user document in Firestore
3. ✅ Create composite indexes
4. 🔄 Deploy Cloud Functions for notifications (optional)
5. 🔄 Implement FCM token storage in user documents
6. 🔄 Add role-based access control for staff vs admin
7. 🔄 Implement CSV export Cloud Function
8. 🔄 Switch to signed Cloudinary uploads for production

---

## Support

For issues or questions, refer to:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Flutter Provider Documentation](https://pub.dev/packages/provider)
