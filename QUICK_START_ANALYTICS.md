# 🚀 Quick Start Guide - Analytics & Notifications

## ✅ What's Ready

### Flutter App
- ✅ Analytics screen with charts and stats
- ✅ Notifications screen with real-time updates
- ✅ Service model updated with analytics fields
- ✅ All dependencies installed

### Cloud Functions
- ✅ `onNewBooking` - Creates notification on new booking
- ✅ `checkStaleBookings` - Checks for follow-ups every 6 hours
- ✅ `detectViewSpikes` - Detects high-interest items hourly
- ✅ `incrementViews` - Tracks views from website

### Firestore
- ✅ Rules updated for notifications collection
- ✅ Ready for composite indexes

---

## 📋 Next Steps (In Order)

### 1. Deploy Firestore Rules (2 minutes)
```bash
cd "c:\rivanapps\unused\jscons\js web2\js website"
firebase deploy --only firestore:rules
```

### 2. Deploy Cloud Functions (5 minutes)
```bash
cd functions
firebase deploy --only functions
```

**Note:** Scheduled functions require Firebase Blaze (pay-as-you-go) plan.

### 3. Create Firestore Indexes
When you first use the app, Firestore will show error messages with links to create indexes. Click those links, or manually create:

**Firebase Console → Firestore → Indexes → Composite**

| Collection | Fields |
|------------|--------|
| `bookings` | status (ASC), createdAt (ASC) |
| `notifications` | isRead (ASC), createdAt (DESC) |

### 4. Test the Features

#### Test Notifications:
1. Submit a booking via website
2. Open Flutter app → Notifications
3. Verify notification appears

#### Test Analytics:
1. Open Flutter app → Analytics
2. Check if data displays
3. Try different period filters (7d, 30d, 90d)

### 5. Initialize Existing Data (Optional)
If you have existing projects/services, add analytics fields:

**Firebase Console → Firestore → Run in browser console:**
```javascript
// For projects
const batch = db.batch();
const snapshot = await db.collection('projects').get();
snapshot.docs.forEach(doc => {
  if (!doc.data().views) {
    batch.update(doc.ref, { views: 0, bookingConversions: 0 });
  }
});
await batch.commit();

// For services
const batch2 = db.batch();
const snapshot2 = await db.collection('services').get();
snapshot2.docs.forEach(doc => {
  if (!doc.data().views) {
    batch2.update(doc.ref, { views: 0, bookingConversions: 0 });
  }
});
await batch2.commit();
```

---

## 🎯 Features Overview

### Analytics Dashboard
- **Overview Cards**: Total views, bookings, conversions, conversion rate
- **Project Analytics**: Top 5 projects by views with progress bars
- **Service Analytics**: Top 5 services by views with progress bars
- **Lead Analytics**: Bookings from services vs projects
- **Peak Enquiry Chart**: Bar chart showing booking times
- **Period Filters**: 7 days, 30 days, 90 days

### Notifications
- **Real-time List**: Auto-updates when new notifications arrive
- **Types**:
  - 🟢 New Booking
  - 🟠 Follow-up Required (>48h)
  - 🔵 High Interest (>50 views)
  - ⚪ System Alert
- **Actions**:
  - Tap to view related item
  - Swipe left to delete
  - Mark all as read button
- **Badge**: Unread count (will be added to navigation)

---

## 📊 Sample Data for Testing

### Create Test Notification Manually
**Firebase Console → Firestore → notifications → Add Document:**
```json
{
  "type": "new_booking",
  "title": "Test Notification",
  "body": "This is a test notification",
  "targetId": null,
  "targetType": null,
  "isRead": false,
  "createdAt": [Current timestamp]
}
```

### Create Test Analytics Data
**Firebase Console → Firestore → projects → Edit existing project:**
Add fields:
```json
{
  "views": 25,
  "bookingConversions": 3
}
```

---

## 🔍 Troubleshooting

### "Missing or insufficient permissions"
→ Deploy Firestore rules: `firebase deploy --only firestore:rules`

### "Index required" error
→ Click the link in the error message to auto-create the index

### Notifications not appearing
→ Check Cloud Functions logs: `firebase functions:log`

### Analytics showing zero
→ Run the data initialization script above

### Cloud Functions deployment fails
→ Ensure you're on Firebase Blaze plan (required for scheduled functions)

---

## 📚 Documentation Files

- `ANALYTICS_NOTIFICATIONS_SETUP.md` - Detailed setup guide
- `ANALYTICS_NOTIFICATIONS_SUMMARY.md` - Implementation summary
- `firestore.rules` - Updated security rules
- `functions/index.js` - Cloud Functions code

---

## 💡 Tips

1. **Test locally first**: Use Firebase Emulator Suite for local testing
2. **Monitor costs**: Check Firebase Console → Usage for function invocations
3. **Adjust thresholds**: Edit `detectViewSpikes` function to change view spike threshold (currently 50)
4. **Customize periods**: Edit `checkStaleBookings` to change follow-up time (currently 48 hours)

---

## ✨ You're All Set!

The Analytics & Notifications system is fully implemented and ready to deploy. Follow the steps above to get it running! 🎉

**Questions?** Check the detailed setup guide in `ANALYTICS_NOTIFICATIONS_SETUP.md`
