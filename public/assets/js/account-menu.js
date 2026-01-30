/**
 * Account Menu Module
 * Handles the account dropdown in the navigation bar
 * Shows different states for logged in/out users
 */

(function () {
    'use strict';

    // Wait for CustomerAuth to be available
    function init() {
        const toggle = document.querySelector('.nav__account-toggle');
        const dropdown = document.querySelector('.account-dropdown');
        const guestSection = document.querySelector('.account-dropdown__guest');
        const userSection = document.querySelector('.account-dropdown__user');
        const signInBtn = document.getElementById('accountSignInBtn');
        const signOutBtn = document.getElementById('accountSignOutBtn');

        if (!toggle || !dropdown) {
            console.log('[AccountMenu] Elements not found on this page');
            return;
        }

        // Toggle dropdown on button click
        // Toggle dropdown on button click
        toggle.addEventListener('click', (e) => {
            e.preventDefault(); // Prevent any default button behavior
            e.stopPropagation();

            const isHidden = dropdown.hasAttribute('hidden');

            if (isHidden) {
                openDropdown();
            } else {
                closeDropdown();
            }

            console.log('[AccountMenu] Toggled dropdown, now hidden:', dropdown.hasAttribute('hidden'));
        });

        // Close dropdown when clicking outside (desktop only behavior)
        document.addEventListener('click', (e) => {
            // Don't auto-close on mobile when clicking within the nav
            const nav = document.querySelector('.nav');
            const isMobileNavOpen = nav && nav.classList.contains('nav--open');

            // If mobile nav is open, only close dropdown if clicking a non-account link
            if (isMobileNavOpen) {
                const clickedLink = e.target.closest('.nav__link');
                if (clickedLink && !clickedLink.classList.contains('nav__account-toggle')) {
                    closeDropdown();
                }
            } else {
                // Desktop: close when clicking outside toggle or dropdown
                if (!dropdown.contains(e.target) && !toggle.contains(e.target)) {
                    closeDropdown();
                }
            }
        });

        // Sign In button click
        if (signInBtn) {
            signInBtn.addEventListener('click', async (e) => {
                e.preventDefault();
                console.log('[AccountMenu] Sign In clicked');

                if (window.CustomerAuth) {
                    try {
                        await window.CustomerAuth.requireAuth();
                        console.log('[AccountMenu] Sign in successful');
                        closeDropdown();
                        updateUI();
                    } catch (error) {
                        console.error('[AccountMenu] Sign in failed:', error);
                    }
                } else {
                    console.error('[AccountMenu] CustomerAuth not available');
                    alert('Authentication system not loaded. Please refresh the page.');
                }
            });
        }

        // Sign Out button click
        if (signOutBtn) {
            signOutBtn.addEventListener('click', async (e) => {
                e.preventDefault();
                console.log('[AccountMenu] Sign Out clicked');

                if (window.CustomerAuth) {
                    try {
                        await window.CustomerAuth.signOutCustomer();
                        console.log('[AccountMenu] Sign out successful');
                        closeDropdown();
                        updateUI();
                    } catch (error) {
                        console.error('[AccountMenu] Sign out failed:', error);
                    }
                } else {
                    console.error('[AccountMenu] CustomerAuth not available');
                }
            });
        }

        // Update UI based on auth state
        updateUI();

        // Listen for auth state changes
        window.addEventListener('customerAuthStateChanged', () => {
            console.log('[AccountMenu] Auth state changed');
            updateUI();
        });
    }

    function openDropdown() {
        const dropdown = document.querySelector('.account-dropdown');
        const toggle = document.querySelector('.nav__account-toggle');

        if (dropdown && toggle) {
            dropdown.removeAttribute('hidden');
            toggle.setAttribute('aria-expanded', 'true');
        }
    }

    function closeDropdown() {
        const dropdown = document.querySelector('.account-dropdown');
        const toggle = document.querySelector('.nav__account-toggle');

        if (dropdown && toggle) {
            dropdown.setAttribute('hidden', '');
            toggle.setAttribute('aria-expanded', 'false');
        }
    }

    async function updateUI() {
        const guestSection = document.querySelector('.account-dropdown__guest');
        const userSection = document.querySelector('.account-dropdown__user');
        const toggle = document.querySelector('.nav__account-toggle');

        if (!guestSection || !userSection) return;

        // Check if user is logged in
        if (window.CustomerAuth && window.CustomerAuth.isLoggedIn()) {
            const customer = window.CustomerAuth.getCurrentCustomer();

            if (customer) {
                // Show user section, hide guest section
                guestSection.setAttribute('hidden', '');
                userSection.removeAttribute('hidden');

                // Update user info
                const avatar = userSection.querySelector('.account-dropdown__avatar');
                const name = userSection.querySelector('.account-dropdown__name');
                const email = userSection.querySelector('.account-dropdown__email');

                // Check for My Bookings link and inject if missing
                let bookingLink = userSection.querySelector('a[href="my-bookings.html"]');
                if (!bookingLink) {
                    const link = document.createElement('a');
                    link.href = 'my-bookings.html';
                    link.className = 'account-dropdown__link';
                    // Use a flex container for the badge alignment
                    link.style.display = 'flex';
                    link.style.justifyContent = 'space-between';
                    link.style.alignItems = 'center';

                    link.innerHTML = '<span>📅 My Bookings</span> <span class="badge-count" style="background: #e74c3c; color: white; border-radius: 50%; padding: 2px 6px; font-size: 0.75em;" hidden>0</span>';

                    // Insert before Sign Out button
                    const signOut = userSection.querySelector('#accountSignOutBtn');
                    if (signOut) {
                        userSection.insertBefore(link, signOut);
                    } else {
                        userSection.appendChild(link);
                    }
                    bookingLink = link;
                }

                if (avatar) {
                    if (customer.photoURL) {
                        avatar.src = customer.photoURL;
                    } else {
                        // Fallback avatar
                        const displayName = customer.displayName || customer.email || 'U';
                        avatar.src = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(displayName) + '&background=E67E22&color=fff';
                    }
                    avatar.alt = customer.displayName || 'User Avatar';
                }

                if (name) {
                    name.textContent = customer.displayName || 'User';
                }

                if (email && customer.email) {
                    email.textContent = customer.email;
                    email.style.display = 'block';
                }

                // LISTEN FOR NOTIFICATIONS
                checkNotifications(customer.uid, toggle, bookingLink);

                console.log('[AccountMenu] Showing user section for:', customer.email);
            }
        } else {
            // Show guest section, hide user section
            guestSection.removeAttribute('hidden');
            userSection.setAttribute('hidden', '');

            // Clear badges if any
            if (toggle) toggle.textContent = 'Account';

            console.log('[AccountMenu] Showing guest section');
        }
    }

    async function checkNotifications(uid, toggleBtn, bookingLink) {
        console.log('[Notifications] Starting check for uid:', uid);
        try {
            // Lazy load Firestore
            const { initializeApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
            const { getFirestore, collection, query, where, onSnapshot } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

            // Config (Same as booking.js - ideally shared)
            const firebaseConfig = {
                apiKey: "AIzaSyBmE3dzzcbMXaustT4SBjhELZ4GWR9JKlU",
                authDomain: "js-construction-811e4.firebaseapp.com",
                projectId: "js-construction-811e4",
                storageBucket: "js-construction-811e4.firebasestorage.app",
                messagingSenderId: "465344186766",
                appId: "1:465344186766:web:382584d5d07ae059e03cdf",
                measurementId: "G-K1K5B5WHV8"
            };

            let app;
            try { app = initializeApp(firebaseConfig); } catch (e) {
                const { getApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
                app = getApp();
            }
            const db = getFirestore(app);

            const q = query(collection(db, 'notifications'), where('userId', '==', uid), where('read', '==', false));
            console.log('[Notifications] Query created, listening...');

            onSnapshot(q, (snapshot) => {
                const count = snapshot.size;
                console.log('[Notifications] ✓ Received', count, 'unread notifications');

                // Update Badge in Dropdown
                const badge = bookingLink ? bookingLink.querySelector('.badge-count') : null;
                if (badge) {
                    badge.textContent = count;
                    badge.hidden = count === 0;
                    console.log('[Notifications] Badge updated in dropdown:', count);
                }

                // Update Navbar Toggle Text
                if (toggleBtn) {
                    if (count > 0) {
                        toggleBtn.innerHTML = `Account <span style="background: #e74c3c; color: white; border-radius: 50%; padding: 2px 6px; font-size: 11px; vertical-align: middle;">${count}</span>`;
                        console.log('[Notifications] Badge added to Account button:', count);
                    } else {
                        toggleBtn.textContent = 'Account';
                        console.log('[Notifications] No badge (count is 0)');
                    }
                }
            });

        } catch (error) {
            console.error('[Notifications] ❌ Error:', error);
        }
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
