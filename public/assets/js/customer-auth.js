/**
 * JS Brixen - Customer Authentication Module
 * 
 * Handles customer authentication for booking and contact forms.
 * Uses Firebase Auth with Google Sign-In as the primary method.
 */

(function () {
    'use strict';

    let auth, db;
    let currentCustomer = null;

    // Initialize Firebase (using CDN modules)
    async function initFirebase() {
        if (auth && db) return { auth, db }; // Already initialized

        const { initializeApp, getApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
        const { getAuth, signInWithPopup, GoogleAuthProvider, signOut, onAuthStateChanged, setPersistence, browserLocalPersistence, signInWithEmailAndPassword, createUserWithEmailAndPassword, updateProfile } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');
        const { getFirestore, doc, getDoc, setDoc, serverTimestamp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

        const firebaseConfig = {
            apiKey: "AIzaSyBmE3dzzcbMXaustT4SBjhELZ4GWR9JKlU",
            authDomain: "js-construction-811e4.firebaseapp.com",
            projectId: "js-construction-811e4",
            storageBucket: "js-construction-811e4.firebasestorage.app",
            messagingSenderId: "465344186766",
            appId: "1:465344186766:web:382584d5d07ae059e03cdf",
            measurementId: "G-K1K5B5WHV8"
        };

        // Initialize Firebase
        let app;
        try {
            app = initializeApp(firebaseConfig);
        } catch (error) {
            if (error.code === 'app/duplicate-app') {
                app = getApp();
            } else {
                throw error;
            }
        }

        auth = getAuth(app);
        db = getFirestore(app);

        // Set persistence to LOCAL (login persists across browser sessions)
        await setPersistence(auth, browserLocalPersistence);

        return { auth, db };
    }

    /**
     * Check if user is currently logged in
     * @returns {boolean}
     */
    function isLoggedIn() {
        return currentCustomer !== null;
    }

    /**
     * Get current customer data
     * @returns {Object|null}
     */
    function getCurrentCustomer() {
        return currentCustomer;
    }

    /**
     * Check if an email address is registered
     * @param {string} email - Email address to check
     * @returns {Promise<boolean>} True if email exists
     */
    async function checkIfEmailExists(email) {
        try {
            const { auth } = await initFirebase();
            const { fetchSignInMethodsForEmail } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');

            const methods = await fetchSignInMethodsForEmail(auth, email);
            return methods.length > 0;
        } catch (error) {
            console.error('Error checking email existence:', error);
            // If we can't check, assume it exists to prevent false redirects
            return true;
        }
    }

    /**
     * Sign in with Google (existing users)
     * @returns {Promise<Object>} Customer data
     */
    async function signInWithGoogle() {
        try {
            const { auth } = await initFirebase();
            const { GoogleAuthProvider, signInWithPopup } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');

            console.log('Starting Google sign-in...');
            const provider = new GoogleAuthProvider();
            const result = await signInWithPopup(auth, provider);
            const user = result.user;

            console.log('Google sign-in successful, checking customer profile...');

            // Check if customer exists in Firestore
            const customerData = await getCustomerData(user.uid);

            if (customerData) {
                // Existing customer - update last login
                await updateLastLogin(user.uid);
                currentCustomer = customerData;
                console.log('Existing customer logged in:', currentCustomer);
                return { isNewUser: false, customer: customerData };
            } else {
                // New user - NOT ALLOWED on sign-in, must sign up first
                console.log('New user detected - signing them out');
                const { signOut } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');
                await signOut(auth);
                throw new Error('NO_ACCOUNT_FOUND'); // Special error code for handling in UI
            }
        } catch (error) {
            console.error('Google sign-in error:', error);
            console.error('Error code:', error.code);
            console.error('Error message:', error.message);
            if (error.code === 'auth/popup-closed-by-user') {
                throw new Error('Sign-in cancelled. Please try again.');
            } else if (error.code === 'auth/popup-blocked') {
                throw new Error('Popup was blocked. Please allow popups for this site.');
            } else if (error.code === 'auth/unauthorized-domain') {
                throw new Error('This domain (' + window.location.hostname + ') is not authorized for Google Sign-In. Please contact support.');
            } else {
                throw new Error('Sign-in failed: ' + error.message);
            }
        }
    }

    /**
     * Initiate Google Sign-Up (Step 1)
     * Launches popup and returns Firebase User object
     * @returns {Promise<Object>} Firebase User
     */
    async function initiateGoogleSignUp() {
        try {
            const { auth } = await initFirebase();
            const { GoogleAuthProvider, signInWithPopup } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');

            console.log('Initiating Google sign-up...');
            const provider = new GoogleAuthProvider();
            const result = await signInWithPopup(auth, provider);
            return result.user;
        } catch (error) {
            console.error('Google sign-up init error:', error);
            if (error.code === 'auth/popup-closed-by-user') {
                throw new Error('Sign-up cancelled. Please try again.');
            } else if (error.code === 'auth/popup-blocked') {
                throw new Error('Popup was blocked. Please allow popups for this site.');
            } else if (error.code === 'auth/email-already-in-use') {
                throw new Error('Account already exists. Please sign in.');
            } else {
                throw new Error('Sign-up failed: ' + error.message);
            }
        }
    }

    /**
     * Complete Google Sign-Up (Step 2 & 3)
     * Links password credential and creates customer profile
     * @param {Object} user - Firebase User object from step 1
     * @param {string} password - User-provided password
     * @param {string} phoneNumber - User's phone number
     * @returns {Promise<Object>} Customer data
     */
    async function completeGoogleSignUp(user, password, phoneNumber) {
        try {
            const { db } = await initFirebase();
            const { linkWithCredential, EmailAuthProvider } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');
            const { doc, setDoc, serverTimestamp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

            console.log('Linking password to Google account...');
            // Link email/password credential to Google account
            const credential = EmailAuthProvider.credential(user.email, password);
            await linkWithCredential(user, credential);

            console.log('Password linked, creating profile...');

            // Validate phone number (10 digits)
            const phoneRegex = /^\d{10}$/;
            if (!phoneRegex.test(phoneNumber)) {
                throw new Error('Please enter a valid 10-digit phone number');
            }

            // Create customer document in Firestore
            const customerData = {
                uid: user.uid,
                email: user.email,
                displayName: user.displayName || '',
                phone: phoneNumber,
                photoURL: user.photoURL || '',
                createdAt: serverTimestamp(),
                lastLoginAt: serverTimestamp()
            };

            await setDoc(doc(db, 'customers', user.uid), customerData);

            currentCustomer = customerData;
            console.log('Customer profile created:', currentCustomer);

            return customerData;
        } catch (error) {
            console.error('Google sign-up completion error:', error);
            throw error;
        }
    }

    /**
     * Sign in with Email and Password
     * @param {string} email
     * @param {string} password
     * @returns {Promise<Object>} Customer data
     */
    async function signInWithEmail(email, password) {
        try {
            const { auth } = await initFirebase();
            const { signInWithEmailAndPassword } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');

            console.log('Starting Email sign-in...');
            const result = await signInWithEmailAndPassword(auth, email, password);
            const user = result.user;

            console.log('Email sign-in successful, checking profile...');

            // Check if customer exists in Firestore
            let customerData = await getCustomerData(user.uid);

            if (customerData) {
                await updateLastLogin(user.uid);
                currentCustomer = customerData;
                return { isNewUser: false, customer: customerData };
            } else {
                // User exists in Auth but not in Firestore - treat as no account found
                // preventing confusing "partial" states
                console.warn('User in Auth but no Firestore profile found');
                const { signOut } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');
                await signOut(auth);
                throw new Error('FORCE_REDIRECT_TO_SIGNUP');
            }
        } catch (error) {
            console.error('Email sign-in error:', error);
            throw error;
        }
    }

    /**
     * Sign up with Email and Password
     * @param {string} email 
     * @param {string} password 
     * @param {string} name 
     * @returns {Promise<Object>}
     */
    async function signUpWithEmail(email, password, name) {
        try {
            const { auth } = await initFirebase();
            const { createUserWithEmailAndPassword, updateProfile } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');

            console.log('Creating account...');
            const result = await createUserWithEmailAndPassword(auth, email, password);
            const user = result.user;

            // Update profile with name
            await updateProfile(user, {
                displayName: name
            });

            // We return the user object, but the consuming code might want to immediately 
            // prompt for phone number to complete the "Customer" profile in Firestore.
            // So we return a structure indicating we are at the "phone number required" stage,
            // similar to Google Sign In for new users.

            return {
                isNewUser: true,
                user: {
                    uid: user.uid,
                    email: user.email,
                    displayName: name,
                    photoURL: null
                }
            };

        } catch (error) {
            console.error('Sign up error:', error);
            throw error;
        }
    }

    /**
     * Complete signup with phone number (for new users)
     * @param {string} phoneNumber - Customer's phone number
     * @returns {Promise<Object>} Customer data
     */
    async function completeSignup(phoneNumber) {
        try {
            const { auth, db } = await initFirebase();
            const { doc, setDoc, serverTimestamp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

            const user = auth.currentUser;
            if (!user) {
                throw new Error('No authenticated user found');
            }

            // Validate phone number (10 digits)
            const phoneRegex = /^\d{10}$/;
            if (!phoneRegex.test(phoneNumber)) {
                throw new Error('Please enter a valid 10-digit phone number');
            }

            console.log('Creating customer profile...');

            // Create customer document in Firestore
            const customerData = {
                uid: user.uid,
                email: user.email,
                displayName: user.displayName || '',
                phone: phoneNumber,
                photoURL: user.photoURL || '',
                createdAt: serverTimestamp(),
                lastLoginAt: serverTimestamp()
            };

            await setDoc(doc(db, 'customers', user.uid), customerData);

            currentCustomer = customerData;
            console.log('Customer profile created:', currentCustomer);

            return customerData;
        } catch (error) {
            console.error('Signup error:', error);
            throw error;
        }
    }

    /**
     * Get customer data from Firestore
     * @param {string} uid - Customer UID
     * @returns {Promise<Object|null>}
     */
    async function getCustomerData(uid) {
        try {
            const { db } = await initFirebase();
            const { doc, getDoc } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

            const customerDoc = await getDoc(doc(db, 'customers', uid));

            if (customerDoc.exists()) {
                return { uid, ...customerDoc.data() };
            }
            return null;
        } catch (error) {
            console.error('Error fetching customer data:', error);
            return null;
        }
    }

    /**
     * Update last login timestamp
     * @param {string} uid - Customer UID
     */
    async function updateLastLogin(uid) {
        try {
            const { db } = await initFirebase();
            const { doc, updateDoc, serverTimestamp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

            await updateDoc(doc(db, 'customers', uid), {
                lastLoginAt: serverTimestamp()
            });
        } catch (error) {
            console.error('Error updating last login:', error);
        }
    }

    /**
     * Sign out current customer
     * @returns {Promise<void>}
     */
    async function signOutCustomer() {
        try {
            const { auth } = await initFirebase();
            const { signOut } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');

            await signOut(auth);
            currentCustomer = null;
            console.log('Customer signed out');
        } catch (error) {
            console.error('Sign-out error:', error);
            throw new Error('Failed to sign out. Please try again.');
        }
    }

    /**
     * Listen to auth state changes and restore session
     * @param {Function} callback - Called with customer data or null
     */
    async function onAuthStateChange(callback) {
        const { auth } = await initFirebase();
        const { onAuthStateChanged } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js');

        return onAuthStateChanged(auth, async (user) => {
            if (user) {
                console.log('Auth state: User signed in');
                const customerData = await getCustomerData(user.uid);
                currentCustomer = customerData;
                callback(customerData);
                window.dispatchEvent(new CustomEvent('customerAuthStateChanged', { detail: customerData }));
            } else {
                console.log('Auth state: User signed out');
                currentCustomer = null;
                callback(null);
                window.dispatchEvent(new CustomEvent('customerAuthStateChanged', { detail: null }));
            }
        });
    }

    /**
     * Require authentication before executing callback
     * Shows auth modal if not logged in
     * @param {Function} onAuthenticated - Called when user is authenticated
     * @param {Function} onCancel - Called when user cancels (optional)
     * @returns {Promise<void>}
     */
    async function requireAuth(onAuthenticated, onCancel) {
        // Initialize Firebase first
        await initFirebase();

        if (isLoggedIn()) {
            // Already logged in
            onAuthenticated(currentCustomer);
            return;
        }

        // Show auth modal
        const modal = window.customerAuthModal;
        if (modal) {
            modal.show(onAuthenticated, onCancel);
        } else {
            console.error('Auth modal not initialized');
            if (onCancel) onCancel();
        }
    }

    // Export public API
    window.CustomerAuth = {
        isLoggedIn,
        getCurrentCustomer,
        checkIfEmailExists,
        signInWithGoogle,
        initiateGoogleSignUp,
        completeGoogleSignUp,
        signInWithEmail,
        signUpWithEmail,
        completeSignup,
        signOutCustomer,
        onAuthStateChange,
        requireAuth,
        initFirebase
    };

    console.log('CustomerAuth module loaded');

    // Auto-restore session on page load
    initFirebase().then(() => {
        onAuthStateChange((customer) => {
            console.log('[CustomerAuth] Session restored:', customer ? customer.email : 'none');
        });
    }).catch(err => {
        console.error('[CustomerAuth] Failed to restore session:', err);
    });
})();

