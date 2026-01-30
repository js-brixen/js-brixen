/**
 * Authentication Guard Middleware
 * 
 * Provides utilities to protect pages and routes based on user authentication
 * and role-based access control.
 */

import { onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../firebase/init.js';

/**
 * Require authentication and specific roles to access a page
 * 
 * @param {string[]} allowedRoles - Array of roles that can access the page (e.g., ['admin', 'staff'])
 * @param {Function} onAllowed - Callback when user is authenticated and has required role
 * @param {Function} onDenied - Callback when user is not authenticated or lacks required role
 * 
 * @example
 * // Protect dashboard page (admin only)
 * requireAuth(
 *   ['admin'],
 *   (user) => {
 *     console.log('Access granted:', user);
 *     // Initialize dashboard
 *   },
 *   () => {
 *     window.location.href = '/src/pages/login.html';
 *   }
 * );
 * 
 * @example
 * // Protect projects page (admin and staff)
 * requireAuth(
 *   ['admin', 'staff'],
 *   (user) => {
 *     console.log('User role:', user.role);
 *     // Load projects
 *   },
 *   () => {
 *     alert('Access denied. Admin or staff role required.');
 *     window.location.href = '/src/pages/login.html';
 *   }
 * );
 */
export function requireAuth(allowedRoles, onAllowed, onDenied) {
    // Show loading state (optional - you can add a loading overlay here)
    console.log('Checking authentication...');

    onAuthStateChanged(auth, async (user) => {
        if (!user) {
            // User is not authenticated
            console.log('No user authenticated');
            onDenied();
            return;
        }

        try {
            // Fetch user document from Firestore
            const userDocRef = doc(db, 'users', user.uid);
            const userDoc = await getDoc(userDocRef);

            if (!userDoc.exists()) {
                // User authenticated but no Firestore document
                console.error('User authenticated but no Firestore document found');
                onDenied();
                return;
            }

            const userData = userDoc.data();
            const userRole = userData.role;

            console.log('User role:', userRole, 'Allowed roles:', allowedRoles);

            // Check if user's role is in the allowed roles
            if (allowedRoles.includes(userRole)) {
                // User has required role
                onAllowed({
                    uid: user.uid,
                    email: user.email,
                    role: userRole,
                    name: userData.name
                });
            } else {
                // User lacks required role
                console.warn('User role not authorized:', userRole);
                onDenied();
            }
        } catch (error) {
            console.error('Error checking user role:', error);
            onDenied();
        }
    });
}

/**
 * Check if user is authenticated (without role check)
 * Useful for pages that just need to know if someone is logged in
 * 
 * @param {Function} onAuthenticated - Callback when user is authenticated
 * @param {Function} onUnauthenticated - Callback when user is not authenticated
 * 
 * @example
 * checkAuth(
 *   (user) => {
 *     console.log('User is logged in:', user.email);
 *   },
 *   () => {
 *     window.location.href = '/src/pages/login.html';
 *   }
 * );
 */
export function checkAuth(onAuthenticated, onUnauthenticated) {
    onAuthStateChanged(auth, async (user) => {
        if (user) {
            try {
                // Fetch user document from Firestore
                const userDocRef = doc(db, 'users', user.uid);
                const userDoc = await getDoc(userDocRef);

                if (userDoc.exists()) {
                    const userData = userDoc.data();
                    onAuthenticated({
                        uid: user.uid,
                        email: user.email,
                        role: userData.role,
                        name: userData.name
                    });
                } else {
                    onUnauthenticated();
                }
            } catch (error) {
                console.error('Error fetching user data:', error);
                onUnauthenticated();
            }
        } else {
            onUnauthenticated();
        }
    });
}

/**
 * Get current user data (one-time check, not a listener)
 * Returns a promise that resolves with user data or null
 * 
 * @returns {Promise<Object|null>} User data or null if not authenticated
 * 
 * @example
 * const user = await getCurrentUser();
 * if (user && user.role === 'admin') {
 *   // Show admin features
 * }
 */
export async function getCurrentUser() {
    return new Promise((resolve) => {
        const unsubscribe = onAuthStateChanged(auth, async (user) => {
            unsubscribe(); // Unsubscribe immediately after first check

            if (!user) {
                resolve(null);
                return;
            }

            try {
                const userDocRef = doc(db, 'users', user.uid);
                const userDoc = await getDoc(userDocRef);

                if (userDoc.exists()) {
                    const userData = userDoc.data();
                    resolve({
                        uid: user.uid,
                        email: user.email,
                        role: userData.role,
                        name: userData.name
                    });
                } else {
                    resolve(null);
                }
            } catch (error) {
                console.error('Error fetching user data:', error);
                resolve(null);
            }
        });
    });
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/*
 * Example 1: Protect Dashboard Page (Admin Only)
 * 
 * File: dashboard.html
 * 
 * <script type="module">
 *   import { requireAuth } from './src/middleware/authGuard.js';
 *   
 *   requireAuth(
 *     ['admin'],
 *     (user) => {
 *       // User is admin - initialize dashboard
 *       document.getElementById('userName').textContent = user.name;
 *       loadDashboardData();
 *     },
 *     () => {
 *       // Access denied - redirect to login
 *       window.location.href = '/src/pages/login.html';
 *     }
 *   );
 * </script>
 */

/*
 * Example 2: Protect Projects Edit Page (Admin and Staff)
 * 
 * File: projects-edit.html
 * 
 * <script type="module">
 *   import { requireAuth } from './src/middleware/authGuard.js';
 *   
 *   requireAuth(
 *     ['admin', 'staff'],
 *     (user) => {
 *       // User has access
 *       console.log('Welcome', user.name);
 *       
 *       // Show/hide features based on role
 *       if (user.role === 'admin') {
 *         document.getElementById('deleteBtn').style.display = 'block';
 *       }
 *       
 *       loadProjectEditor();
 *     },
 *     () => {
 *       // Access denied
 *       alert('You do not have permission to edit projects.');
 *       window.location.href = '/dashboard.html';
 *     }
 *   );
 * </script>
 */

/*
 * Example 3: Check Current User on Any Page
 * 
 * <script type="module">
 *   import { getCurrentUser } from './src/middleware/authGuard.js';
 *   
 *   const user = await getCurrentUser();
 *   
 *   if (user) {
 *     console.log('Logged in as:', user.email, 'Role:', user.role);
 *     document.getElementById('userMenu').style.display = 'block';
 *   } else {
 *     document.getElementById('loginPrompt').style.display = 'block';
 *   }
 * </script>
 */
