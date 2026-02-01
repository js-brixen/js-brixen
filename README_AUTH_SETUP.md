# Firebase Authentication Setup Guide

This guide provides step-by-step instructions for deploying and testing the Firebase authentication infrastructure for the JS Construction CRM.

## 📋 Prerequisites

Before you begin, ensure you have:

- ✅ Node.js 18+ installed
- ✅ Firebase CLI installed globally (`npm install -g firebase-tools`)
- ✅ Firebase project created (`js-construction-811e4`)
- ✅ Firebase Auth Email/Password and Google Sign-In enabled
- ✅ Existing admin user: `sibijose331here@gmail.com` with `role: "admin"` in Firestore

## 🚀 Deployment Steps

### Step 1: Deploy Cloud Function

The `createUser` Cloud Function must be deployed before you can create new users from the admin interface.

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Login to Firebase (if not already logged in)
firebase login

# Deploy the createUser function
firebase deploy --only functions:createUser
```

**Expected Output:**
```
✔  Deploy complete!

Function URL (createUser): https://us-central1-js-construction-811e4.cloudfunctions.net/createUser
```

> **Note:** The function deployment may take 2-3 minutes. If you encounter permission errors, ensure you're logged in with an account that has access to the Firebase project.

### Step 2: Configure Environment Variables

The Firebase configuration is currently using fallback values from `register.js`. For production, you should use environment variables.

#### Option A: Using a Build Tool (Vite, Webpack, etc.)

Create a `.env` file in the project root:

```env
FIREBASE_API_KEY=AIzaSyBmE3dzzcbMXaustT4SBjhELZ4GWR9JKlU
FIREBASE_AUTH_DOMAIN=js-construction-811e4.firebaseapp.com
FIREBASE_PROJECT_ID=js-construction-811e4
FIREBASE_APP_ID=1:465344186766:web:382584d5d07ae059e03cdf
FIREBASE_STORAGE_BUCKET=js-construction-811e4.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=465344186766
FIREBASE_MEASUREMENT_ID=G-K1K5B5WHV8
```

> **⚠️ IMPORTANT:** Add `.env` to your `.gitignore` file to prevent committing secrets!

#### Option B: For Development (Temporary)

The current implementation includes fallback values, so you can test immediately without environment variables. However, **remove these fallbacks before production deployment**.

### Step 3: Set Up Local Development Server

Since the code uses ES modules, you need to serve the files through a local server (not just opening the HTML file directly).

#### Option 1: Using Python (if installed)

```bash
# Python 3
python -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

Then open: `http://localhost:8000/src/pages/login.html`

#### Option 2: Using Node.js http-server

```bash
# Install http-server globally
npm install -g http-server

# Run server
http-server -p 8000
```

Then open: `http://localhost:8000/src/pages/login.html`

#### Option 3: Using VS Code Live Server Extension

1. Install "Live Server" extension in VS Code
2. Right-click `login.html` and select "Open with Live Server"

## 🧪 Testing Guide

### Test 1: Login with Existing Admin

1. Open `http://localhost:8000/src/pages/login.html` in your browser
2. Enter credentials:
   - **Email:** `sibijose331here@gmail.com`
   - **Password:** [Your existing password - DO NOT CHANGE]
3. Click "Sign In"

**Expected Result:**
- ✅ Success message appears
- ✅ Console shows: `Login successful: { uid, email, role: "admin", name }`
- ✅ Redirects to `/dashboard.html` (will show 404 for now - that's expected)

**Troubleshooting:**
- ❌ "Invalid email or password" → Check password is correct
- ❌ "Access denied" → Verify Firestore `users/{uid}` document exists with `role: "admin"`
- ❌ Network error → Check Firebase project configuration

### Test 2: Google Sign-In

1. On the login page, click "Continue with Google"
2. Select the Google account associated with your admin user
3. Complete the OAuth flow

**Expected Result:**
- ✅ If the Google account has a Firestore document → Login successful
- ✅ If no Firestore document → "Access denied" error

### Test 3: Create New User (Admin Function)

After successfully logging in as admin, open the browser console and run:

```javascript
// Import the function
import { createUserByAdmin } from '../firebase/auth.js';

// Create a new staff user
const result = await createUserByAdmin(
  'newstaff@example.com',
  'SecurePassword123!',
  'John Doe',
  'staff'
);

console.log('User created:', result);
// Expected: { uid: "...", email: "newstaff@example.com", role: "staff", message: "User created successfully" }
```

**Verify in Firebase Console:**
1. Go to Firebase Console → Authentication
2. Check that `newstaff@example.com` appears in the user list
3. Go to Firestore → `users` collection
4. Verify document exists with correct `email`, `name`, `role`, and `createdAt` fields

### Test 4: Auth Guard Protection

Create a test protected page:

**File: `test-protected.html`**
```html
<!DOCTYPE html>
<html>
<head>
  <title>Protected Page</title>
</head>
<body>
  <h1>Admin Dashboard</h1>
  <p id="message">Loading...</p>

  <script type="module">
    import { requireAuth } from './src/middleware/authGuard.js';

    requireAuth(
      ['admin'],
      (user) => {
        document.getElementById('message').textContent = 
          `Welcome, ${user.name}! You have admin access.`;
      },
      () => {
        window.location.href = '/src/pages/login.html';
      }
    );
  </script>
</body>
</html>
```

**Test:**
1. Open `test-protected.html` while logged out → Should redirect to login
2. Login as admin → Open `test-protected.html` → Should show welcome message
3. Login as staff user → Open `test-protected.html` → Should redirect to login

## 📁 File Structure Reference

```
js website/
├── functions/
│   ├── index.js              # Cloud Function: createUser
│   ├── package.json          # Functions dependencies
│   └── node_modules/         # (created after npm install)
├── src/
│   ├── firebase/
│   │   ├── init.js           # Firebase initialization
│   │   └── auth.js           # Authentication functions
│   ├── middleware/
│   │   └── authGuard.js      # Page protection utilities
│   └── pages/
│       └── login.html        # Admin login page
├── register.js               # Original Firebase config (can be removed)
├── package.json              # Project dependencies
└── README_AUTH_SETUP.md      # This file
```

## 🔒 Security Best Practices

### ✅ DO:
- Use environment variables for Firebase config in production
- Keep `.env` files out of version control (add to `.gitignore`)
- Verify user roles on both client and server (Cloud Functions)
- Use HTTPS in production
- Enable Firebase App Check for additional security

### ❌ DON'T:
- Hardcode API keys in source code committed to Git
- Allow client-side writes to `users/{uid}` collection (use Cloud Functions)
- Skip role verification on protected pages
- Change the existing admin account credentials
- Use Firebase Storage (use Cloudinary instead, as planned)

## 🐛 Common Issues & Solutions

### Issue: "Module not found" errors
**Solution:** Ensure you're serving files through a local server, not opening HTML files directly (`file://` protocol doesn't support ES modules).

### Issue: Cloud Function deployment fails
**Solution:** 
- Check you're logged in: `firebase login`
- Verify project: `firebase use js-construction-811e4`
- Check Node.js version: `node --version` (should be 18+)

### Issue: "Access denied" after successful login
**Solution:** Verify the Firestore `users/{uid}` document exists and has a `role` field.

### Issue: Google Sign-In popup blocked
**Solution:** Allow popups for localhost in browser settings.

### Issue: CORS errors
**Solution:** Use a proper local server (http-server, Live Server, etc.) instead of opening files directly.

## 📝 Next Steps

After completing authentication setup:

1. **Create Dashboard Page** (`dashboard.html`) - The login page redirects here
2. **Implement User Management UI** - Interface for admins to create/manage users
3. **Add Cloudinary Integration** - For image uploads (not Firebase Storage)
4. **Create Additional Protected Pages** - Projects, clients, etc.
5. **Implement Firestore Security Rules** - Ensure proper access control

## 🔗 Useful Commands

```bash
# View Cloud Function logs
firebase functions:log

# Deploy all functions
firebase deploy --only functions

# Test functions locally (requires Firebase Emulator Suite)
firebase emulators:start

# Check Firebase project
firebase projects:list

# Switch Firebase project
firebase use js-construction-811e4
```

## 📞 Support

If you encounter issues:

1. Check the browser console for error messages
2. Review Cloud Function logs: `firebase functions:log`
3. Verify Firebase Console settings (Auth, Firestore)
4. Ensure all dependencies are installed: `npm install`

---

**Last Updated:** January 25, 2026  
**Firebase Project:** js-construction-811e4  
**Admin Email:** sibijose331here@gmail.com
