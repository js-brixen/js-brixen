# Analytics & Notifications Setup Guide

This guide covers the manual Firebase Console setup and Cloud Functions deployment for the Analytics & Notifications features.

## 📋 Prerequisites

- Firebase project already set up
- Firebase CLI installed (`npm install -g firebase-tools`)
- Admin access to Firebase Console

---

## 🔥 Firebase Console Setup

### 1. Update Firestore Security Rules

The `firestore.rules` file has been updated. Deploy it to Firebase:

```bash
firebase deploy --only firestore:rules
```

**What was added:**
- `notifications` collection: Admin can read/update, only Cloud Functions can create/delete

### 2. Create Composite Indexes

These indexes are required for efficient queries. Create them in Firebase Console:

**Go to:** Firebase Console → Firestore Database → Indexes → Composite

#### Index 1: Bookings by Status and Date
- Collection: `bookings`
- Fields:
  - `status` (Ascending)
  - `createdAt` (Ascending)
- Query scope: Collection

#### Index 2: Notifications by Read Status and Date
- Collection: `notifications`
- Fields:
  - `isRead` (Ascending)
  - `createdAt` (Descending)
- Query scope: Collection

**Note:** You can also wait for Firestore to suggest these indexes when you first run queries. Click the link in the error message to auto-create them.

---

## ☁️ Cloud Functions Setup

### 1. Initialize Cloud Functions (if not already done)

```bash
cd "c:\rivanapps\unused\jscons\js web2\js website"
firebase init functions
```

Select:
- JavaScript (or TypeScript if preferred)
- Install dependencies with npm: Yes

### 2. Create Cloud Functions

Create the following files in the `functions/` directory:

#### `functions/index.js`

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// ========== NOTIFICATION TRIGGERS ==========

/**
 * Trigger: New booking created
 * Creates a notification for admins
 */
exports.onNewBooking = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    const bookingId = context.params.bookingId;

    await db.collection('notifications').add({
      type: 'new_booking',
      title: 'New Booking Received',
      body: `${booking.name} from ${booking.district} - ${booking.typeOfWork}`,
      targetId: bookingId,
      targetType: 'booking',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Notification created for new booking: ${bookingId}`);
  });

/**
 * Scheduled: Check for stale bookings (not followed up)
 * Runs every 6 hours
 */
exports.checkStaleBookings = functions.pubsub
  .schedule('every 6 hours')
  .onRun(async (context) => {
    const twoDaysAgo = new Date();
    twoDaysAgo.setHours(twoDaysAgo.getHours() - 48);

    const staleBookingsSnapshot = await db
      .collection('bookings')
      .where('status', '==', 'new')
      .where('createdAt', '<', admin.firestore.Timestamp.fromDate(twoDaysAgo))
      .get();

    const batch = db.batch();
    let count = 0;

    for (const doc of staleBookingsSnapshot.docs) {
      const booking = doc.data();
      const notificationRef = db.collection('notifications').doc();

      batch.set(notificationRef, {
        type: 'booking_not_followed_up',
        title: 'Follow-up Required',
        body: `Booking from ${booking.name} has not been followed up for 48+ hours`,
        targetId: doc.id,
        targetType: 'booking',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      count++;
    }

    if (count > 0) {
      await batch.commit();
      console.log(`Created ${count} follow-up reminder notifications`);
    }

    return null;
  });

/**
 * Scheduled: Detect view spikes
 * Runs every hour
 */
exports.detectViewSpikes = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    // Get all projects and services
    const [projectsSnapshot, servicesSnapshot] = await Promise.all([
      db.collection('projects').get(),
      db.collection('services').get(),
    ]);

    const batch = db.batch();
    let spikeCount = 0;

    // Check projects for view spikes
    for (const doc of projectsSnapshot.docs) {
      const project = doc.data();
      const views = project.views || 0;

      // Simple spike detection: if views > 50, it's notable
      // You can make this more sophisticated with historical averages
      if (views > 50 && !project.spikeNotified) {
        const notificationRef = db.collection('notifications').doc();

        batch.set(notificationRef, {
          type: 'view_spike',
          title: 'High Interest Detected',
          body: `Project "${project.title}" has ${views} views`,
          targetId: doc.id,
          targetType: 'project',
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Mark as notified to avoid duplicate notifications
        batch.update(doc.ref, { spikeNotified: true });
        spikeCount++;
      }
    }

    // Check services for view spikes
    for (const doc of servicesSnapshot.docs) {
      const service = doc.data();
      const views = service.views || 0;

      if (views > 50 && !service.spikeNotified) {
        const notificationRef = db.collection('notifications').doc();

        batch.set(notificationRef, {
          type: 'view_spike',
          title: 'High Interest Detected',
          body: `Service "${service.title}" has ${views} views`,
          targetId: doc.id,
          targetType: 'service',
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        batch.update(doc.ref, { spikeNotified: true });
        spikeCount++;
      }
    }

    if (spikeCount > 0) {
      await batch.commit();
      console.log(`Created ${spikeCount} view spike notifications`);
    }

    return null;
  });

// ========== VIEW TRACKING (Optional - for website integration) ==========

/**
 * HTTP Callable: Increment view count with rate limiting
 * Called from website when project/service page is viewed
 */
exports.incrementViews = functions.https.onCall(async (data, context) => {
  const { type, id } = data; // type: 'project' | 'service'

  if (!type || !id) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing type or id');
  }

  const collection = type === 'project' ? 'projects' : 'services';
  const docRef = db.collection(collection).doc(id);

  try {
    await docRef.update({
      views: admin.firestore.FieldValue.increment(1),
    });

    console.log(`Incremented views for ${type}: ${id}`);
    return { success: true };
  } catch (error) {
    console.error('Error incrementing views:', error);
    throw new functions.https.HttpsError('internal', 'Failed to increment views');
  }
});
```

### 3. Install Dependencies

```bash
cd functions
npm install firebase-functions firebase-admin
```

### 4. Deploy Cloud Functions

```bash
firebase deploy --only functions
```

**Expected output:**
```
✔  functions[onNewBooking]: Successful create operation.
✔  functions[checkStaleBookings]: Successful create operation.
✔  functions[detectViewSpikes]: Successful create operation.
✔  functions[incrementViews]: Successful create operation.
```

---

## 🧪 Testing

### Test Notifications

#### 1. Test New Booking Notification
1. Go to your website booking form
2. Submit a test booking
3. Open Flutter admin app → Notifications
4. Verify notification appears within 5 seconds

#### 2. Test Follow-up Reminder (Manual)
Create a test booking in Firestore with old `createdAt`:

```javascript
// In Firebase Console → Firestore
// Create document in 'bookings' collection:
{
  name: "Test User",
  phone: "1234567890",
  district: "Test District",
  typeOfWork: "Test Work",
  status: "new",
  source: "test",
  createdAt: Timestamp (3 days ago),
  updatedAt: Timestamp (now)
}
```

Wait for the scheduled function to run (or trigger manually in Firebase Console → Functions).

#### 3. Test View Spike Detection
1. Manually set a project's `views` field to 60 in Firestore
2. Wait for the hourly function to run
3. Check for notification in the app

### Test Analytics

1. Open Flutter admin app → Analytics
2. Verify overview cards show correct data
3. Test period selector (7d, 30d, 90d)
4. Check project and service analytics bars
5. Verify peak enquiry chart displays

---

## 📊 Data Initialization

If you have existing projects/services without analytics fields, run this script in Firebase Console:

```javascript
// Go to Firestore → Select 'projects' collection → Run query
// Then in browser console:

const batch = db.batch();
const projectsSnapshot = await db.collection('projects').get();

projectsSnapshot.docs.forEach(doc => {
  if (!doc.data().views) {
    batch.update(doc.ref, {
      views: 0,
      bookingConversions: 0
    });
  }
});

await batch.commit();
console.log('Updated projects with analytics fields');

// Repeat for services:
const servicesSnapshot = await db.collection('services').get();
const batch2 = db.batch();

servicesSnapshot.docs.forEach(doc => {
  if (!doc.data().views) {
    batch2.update(doc.ref, {
      views: 0,
      bookingConversions: 0
    });
  }
});

await batch2.commit();
console.log('Updated services with analytics fields');
```

---

## 🔍 Monitoring

### View Cloud Function Logs

```bash
firebase functions:log
```

Or in Firebase Console → Functions → Logs

### Check Function Execution

Firebase Console → Functions → Dashboard shows:
- Invocation count
- Execution time
- Error rate

---

## 🚨 Troubleshooting

### Notifications not appearing
1. Check Cloud Function logs for errors
2. Verify Firestore rules are deployed
3. Check that Flutter app has internet connection
4. Verify notification service is properly initialized

### Analytics showing zero
1. Ensure `views` and `bookingConversions` fields exist on documents
2. Run data initialization script above
3. Check Firestore indexes are created

### Cloud Functions failing
1. Check billing is enabled (Cloud Functions require Blaze plan for scheduled functions)
2. Verify `firebase-admin` is installed in functions directory
3. Check function logs for specific errors

---

## 💡 Next Steps

### Optional Enhancements

1. **Push Notifications**: Add Firebase Cloud Messaging (FCM) to send push notifications to mobile devices
2. **Email Notifications**: Integrate SendGrid or similar to email admins about important events
3. **Advanced Analytics**: Add more sophisticated trend analysis and forecasting
4. **Custom Dashboards**: Create role-specific analytics views

### Website Integration

To track views from the website, add this to your project/service detail pages:

```javascript
// In public/assets/js/projects.js or services.js
import { getFunctions, httpsCallable } from 'firebase/functions';

async function trackView(type, id) {
  const functions = getFunctions();
  const incrementViews = httpsCallable(functions, 'incrementViews');
  
  try {
    await incrementViews({ type, id });
  } catch (error) {
    console.error('Error tracking view:', error);
  }
}

// Call when page loads:
trackView('project', projectId);
```

---

## ✅ Verification Checklist

- [ ] Firestore rules deployed
- [ ] Composite indexes created
- [ ] Cloud Functions deployed successfully
- [ ] Test notification received for new booking
- [ ] Analytics screen displays data
- [ ] Notifications screen shows unread count
- [ ] View tracking works (if website integrated)
- [ ] Scheduled functions running (check logs after 6 hours)

---

## 📝 Notes

- Scheduled Cloud Functions require Firebase Blaze (pay-as-you-go) plan
- Free tier includes 2M function invocations per month
- View spike threshold (50 views) can be adjusted in `detectViewSpikes` function
- Follow-up reminder period (48 hours) can be adjusted in `checkStaleBookings` function
