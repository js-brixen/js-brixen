# Firebase Setup Checklist for Services

## Issues Fixed:
1. ✅ **Overflow in ServiceCard** - Changed Row to Wrap for action buttons
2. ✅ **Firestore Integration** - Created services-firestore.js to fetch live services
3. ✅ **Website Integration** - Updated services.html and services.js to load from Firestore

## Firebase Console Checks:

### 1. Firestore Database Structure
Your services should be stored in Firestore with this structure:

```
services (collection)
  └── {serviceId} (document)
      ├── slug: "plumbing" (string)
      ├── title: "Plumbing" (string)
      ├── shortDescription: "hahaa" (string)
      ├── fullDescription: "..." (string)
      ├── images: (array)
      │   └── 0:
      │       ├── url: "https://..." (string)
      │       └── alt: "..." (string)
      ├── tags: ["poll"] (array of strings)
      ├── features: [] (array of strings)
      ├── process: [] (array of objects)
      ├── faqs: [] (array of objects)
      ├── areaServed: [] (array of strings)
      ├── status: "live" (string) ⚠️ MUST BE "live" to show on website
      ├── createdAt: (timestamp)
      └── updatedAt: (timestamp)
```

### 2. Firestore Security Rules
Make sure your Firestore rules allow reading services:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Services - Public read, admin write
    match /services/{serviceId} {
      allow read: if true;  // Anyone can read
      allow write: if request.auth != null;  // Only authenticated users can write
    }
  }
}
```

### 3. Check Your Service Status
In the Firebase Console:
1. Go to Firestore Database
2. Find the `services` collection
3. Click on your "plumbing" service document
4. **IMPORTANT**: Make sure the `status` field is set to **"live"** (not "disabled")
5. If it's "disabled", change it to "live" or use the Flutter app to toggle it

### 4. Firestore Indexes
You may need to create a composite index for the query:
- Collection: `services`
- Fields: `status` (Ascending), `createdAt` (Descending)

If you get an error in the browser console about missing indexes, Firebase will provide a direct link to create the index.

## How to Test:

1. **Check Browser Console**:
   - Open `http://localhost:8000/services.html`
   - Open Developer Tools (F12)
   - Look for: `[Services] Loaded X services from Firestore`
   - If X = 0, check the status field in Firestore

2. **Check Network Tab**:
   - Look for Firestore API calls
   - Check for any 403 (permission) errors

3. **Verify Service Status in Flutter App**:
   - Open the Services screen
   - Make sure the service shows a green "Live" badge
   - If it shows "Disabled", tap the "Enable" button

## Common Issues:

### "Showing 0 services"
**Causes:**
- Service status is "disabled" instead of "live"
- Firestore security rules are blocking reads
- Firebase config is incorrect

**Solution:**
1. Check service status in Firestore Console
2. Verify security rules allow public read
3. Check browser console for errors

### "Permission Denied" Error
**Cause:** Firestore security rules are too restrictive

**Solution:**
Update rules to allow public read access for services collection

### Images Not Loading
**Cause:** Image URLs from Cloudinary might be incorrect

**Solution:**
Check that the image URLs in Firestore are valid and accessible
