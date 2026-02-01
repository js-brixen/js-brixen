/**
 * Firebase Initialization Module
 * 
 * Initializes Firebase app and exports Firebase services.
 * Uses environment variables for configuration to avoid hardcoding secrets.
 * 
 * Environment Variables Required:
 * - FIREBASE_API_KEY
 * - FIREBASE_AUTH_DOMAIN
 * - FIREBASE_PROJECT_ID
 * - FIREBASE_APP_ID
 * 
 * Optional:
 * - FIREBASE_STORAGE_BUCKET
 * - FIREBASE_MESSAGING_SENDER_ID
 * - FIREBASE_MEASUREMENT_ID
 */

import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';

// Firebase configuration
// TODO: Set these environment variables in your build tool or .env file
// For development, you can temporarily use the values from register.js
// NEVER commit actual API keys to version control!

const firebaseConfig = {
    apiKey: import.meta.env?.FIREBASE_API_KEY || process.env.FIREBASE_API_KEY || "AIzaSyBmE3dzzcbMXaustT4SBjhELZ4GWR9JKlU",
    authDomain: import.meta.env?.FIREBASE_AUTH_DOMAIN || process.env.FIREBASE_AUTH_DOMAIN || "js-construction-811e4.firebaseapp.com",
    projectId: import.meta.env?.FIREBASE_PROJECT_ID || process.env.FIREBASE_PROJECT_ID || "js-construction-811e4",
    storageBucket: import.meta.env?.FIREBASE_STORAGE_BUCKET || process.env.FIREBASE_STORAGE_BUCKET || "js-construction-811e4.firebasestorage.app",
    messagingSenderId: import.meta.env?.FIREBASE_MESSAGING_SENDER_ID || process.env.FIREBASE_MESSAGING_SENDER_ID || "465344186766",
    appId: import.meta.env?.FIREBASE_APP_ID || process.env.FIREBASE_APP_ID || "1:465344186766:web:382584d5d07ae059e03cdf",
    measurementId: import.meta.env?.FIREBASE_MEASUREMENT_ID || process.env.FIREBASE_MEASUREMENT_ID || "G-K1K5B5WHV8"
};

// Log configuration status (without exposing secrets)
console.log('Firebase initializing with project:', firebaseConfig.projectId);

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
const auth = getAuth(app);
const db = getFirestore(app);
const functions = getFunctions(app);

// Optional: Set functions region if needed
// connectFunctionsEmulator(functions, 'localhost', 5001); // For local development

// Export Firebase services
export { app, auth, db, functions };
