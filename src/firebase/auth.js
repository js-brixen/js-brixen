/**
 * Firebase Authentication Module
 * 
 * Provides authentication functions for the JS Construction CRM.
 * All sign-in methods verify that the user has a Firestore document with a role.
 */

import {
    signInWithEmailAndPassword,
    signInWithPopup,
    GoogleAuthProvider,
    signOut,
    onAuthStateChanged
} from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { auth, db, functions } from './init.js';

/**
 * Sign in with email and password
 * Verifies user has a Firestore document with role before allowing access
 * 
 * @param {string} email - User's email
 * @param {string} password - User's password
 * @returns {Promise<Object>} User data { uid, email, role }
 * @throws {Error} If credentials invalid or user lacks Firestore document
 */
export async function signInEmail(email, password) {
    try {
        console.log('Attempting email/password sign-in for:', email);

        // Sign in with Firebase Auth
        const userCredential = await signInWithEmailAndPassword(auth, email, password);
        const user = userCredential.user;

        console.log('Firebase Auth successful, checking Firestore document...');

        // Fetch user document from Firestore
        const userDocRef = doc(db, 'users', user.uid);
        const userDoc = await getDoc(userDocRef);

        if (!userDoc.exists()) {
            console.error('User authenticated but no Firestore document found');
            // Sign out the user since they don't have proper access
            await signOut(auth);
            throw new Error('Access denied. Your account is not properly configured.');
        }

        const userData = userDoc.data();
        console.log('Sign-in successful. User role:', userData.role);

        return {
            uid: user.uid,
            email: user.email,
            role: userData.role,
            name: userData.name
        };

    } catch (error) {
        console.error('Sign-in error:', error.code, error.message);

        // Provide user-friendly error messages
        if (error.code === 'auth/invalid-credential' || error.code === 'auth/wrong-password') {
            throw new Error('Invalid email or password.');
        } else if (error.code === 'auth/user-not-found') {
            throw new Error('No account found with this email.');
        } else if (error.code === 'auth/too-many-requests') {
            throw new Error('Too many failed attempts. Please try again later.');
        } else if (error.message.includes('Access denied')) {
            throw error; // Re-throw our custom access denied error
        } else {
            throw new Error('Sign-in failed. Please try again.');
        }
    }
}

/**
 * Sign in with Google popup
 * Verifies user has a Firestore document with role before allowing access
 * 
 * @returns {Promise<Object>} User data { uid, email, role }
 * @throws {Error} If user cancels or lacks Firestore document
 */
export async function signInWithGoogle() {
    try {
        console.log('Attempting Google sign-in...');

        const provider = new GoogleAuthProvider();
        const userCredential = await signInWithPopup(auth, provider);
        const user = userCredential.user;

        console.log('Google Auth successful, checking Firestore document...');

        // Fetch user document from Firestore
        const userDocRef = doc(db, 'users', user.uid);
        const userDoc = await getDoc(userDocRef);

        if (!userDoc.exists()) {
            console.error('User authenticated but no Firestore document found');
            // Sign out the user since they don't have proper access
            await signOut(auth);
            throw new Error('Access denied. Your account is not authorized for this application.');
        }

        const userData = userDoc.data();
        console.log('Google sign-in successful. User role:', userData.role);

        return {
            uid: user.uid,
            email: user.email,
            role: userData.role,
            name: userData.name
        };

    } catch (error) {
        console.error('Google sign-in error:', error.code, error.message);

        // Provide user-friendly error messages
        if (error.code === 'auth/popup-closed-by-user') {
            throw new Error('Sign-in cancelled.');
        } else if (error.code === 'auth/popup-blocked') {
            throw new Error('Popup blocked. Please allow popups for this site.');
        } else if (error.message.includes('Access denied')) {
            throw error; // Re-throw our custom access denied error
        } else {
            throw new Error('Google sign-in failed. Please try again.');
        }
    }
}

/**
 * Sign out the current user
 * 
 * @returns {Promise<void>}
 */
export async function signOutUser() {
    try {
        console.log('Signing out user...');
        await signOut(auth);
        console.log('Sign-out successful');
    } catch (error) {
        console.error('Sign-out error:', error);
        throw new Error('Failed to sign out. Please try again.');
    }
}

/**
 * Create a new user (Admin only)
 * Calls the Cloud Function to create user in Firebase Auth and Firestore
 * 
 * @param {string} email - New user's email
 * @param {string} password - New user's password
 * @param {string} name - New user's display name
 * @param {string} role - New user's role (admin, staff, manager, viewer)
 * @returns {Promise<Object>} Created user info { uid, email, role }
 * @throws {Error} If caller is not admin or creation fails
 */
export async function createUserByAdmin(email, password, name, role) {
    try {
        console.log('Calling createUser Cloud Function...');

        // Get reference to the callable function
        const createUserFunction = httpsCallable(functions, 'createUser');

        // Call the function with user data
        const result = await createUserFunction({
            email,
            password,
            name,
            role
        });

        console.log('User created successfully:', result.data);
        return result.data;

    } catch (error) {
        console.error('Create user error:', error);

        // Parse Cloud Function errors
        if (error.code === 'functions/unauthenticated') {
            throw new Error('You must be logged in to create users.');
        } else if (error.code === 'functions/permission-denied') {
            throw new Error('Only administrators can create users.');
        } else if (error.code === 'functions/invalid-argument') {
            throw new Error(error.message || 'Invalid user data provided.');
        } else if (error.code === 'functions/already-exists') {
            throw new Error('A user with this email already exists.');
        } else {
            throw new Error('Failed to create user. Please try again.');
        }
    }
}

/**
 * Listen to authentication state changes
 * Automatically fetches user role from Firestore when user signs in
 * 
 * @param {Function} callback - Called with user data or null
 * @returns {Function} Unsubscribe function
 */
export function onAuthStateChange(callback) {
    return onAuthStateChanged(auth, async (user) => {
        if (user) {
            console.log('Auth state changed: User signed in');

            try {
                // Fetch user document from Firestore
                const userDocRef = doc(db, 'users', user.uid);
                const userDoc = await getDoc(userDocRef);

                if (userDoc.exists()) {
                    const userData = userDoc.data();
                    callback({
                        uid: user.uid,
                        email: user.email,
                        role: userData.role,
                        name: userData.name
                    });
                } else {
                    console.warn('User authenticated but no Firestore document found');
                    callback(null);
                }
            } catch (error) {
                console.error('Error fetching user data:', error);
                callback(null);
            }
        } else {
            console.log('Auth state changed: User signed out');
            callback(null);
        }
    });
}
