import { collection, query, where, getDocs, orderBy, limit, doc, onSnapshot } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

/**
 * JS Brixen - My Bookings Module
 * Fetches and displays bookings and messages for the logged-in user.
 */

// DOM Elements
const container = document.getElementById('bookings-container');

// State
let db;
let unsubscribeCallbacks = [];

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
    // Wait for CustomerAuth
    if (window.CustomerAuth) {
        window.CustomerAuth.onAuthStateChange(user => {
            if (user) {
                initBookings(user);
            } else {
                showAuthRequired();
            }
        });
    } else {
        // Retry if loaded too fast (unlikely due to script order)
        setTimeout(() => {
            if (window.CustomerAuth && window.CustomerAuth.isLoggedIn()) {
                initBookings(window.CustomerAuth.getCurrentCustomer());
            } else {
                showAuthRequired();
            }
        }, 500);
    }
});

async function initBookings(user) {
    container.innerHTML = `
        <div class="loading-state">
            <div class="spinner"></div>
            <p>Loading your bookings...</p>
        </div>
    `;

    try {
        const firebase = await window.CustomerAuth.initFirebase();
        db = firebase.db;

        // Fetch bookings
        fetchBookings(user.uid);
    } catch (error) {
        console.error('Error initializing:', error);
        container.innerHTML = `<div class="error-state">Failed to load bookings. Please try again later.</div>`;
    }
}

async function fetchBookings(uid) {
    try {
        const bookingsRef = collection(db, 'bookings');
        // REMOVED orderBy to avoid missing index errors. 
        // Sorting is now done client-side below.
        const q = query(
            bookingsRef,
            where('customerUid', '==', uid)
        );

        const snapshot = await getDocs(q);

        if (snapshot.empty) {
            container.innerHTML = `
                <div class="empty-state">
                    <h3>No Bookings Found</h3>
                    <p>You haven't made any bookings yet.</p>
                    <a href="book-consultation.html" class="btn-primary" style="margin-top: 1rem; display: inline-block;">Book a Consultation</a>
                </div>
            `;
            return;
        }

        // Client-side sort (Newest first)
        const sortedDocs = snapshot.docs.sort((a, b) => {
            const dateA = a.data().createdAt?.toMillis() || 0;
            const dateB = b.data().createdAt?.toMillis() || 0;
            return dateB - dateA;
        });

        // Render list with UID context
        renderBookingsList(sortedDocs, uid);

    } catch (error) {
        console.error('Error fetching bookings:', error);
        // Fallback for missing index error
        if (error.message.includes('index')) {
            container.innerHTML = `<div class="error-state">System update in progress (Index Building). Please check back in a few minutes.</div>`;
        } else {
            container.innerHTML = `<div class="error-state">Could not load bookings. ${error.message}</div>`;
        }
    }
}

function renderBookingsList(docs, currentUid) {
    container.innerHTML = '<div class="bookings-grid"></div>';
    const grid = container.querySelector('.bookings-grid');

    docs.forEach(docSnap => {
        const data = docSnap.data();
        const id = docSnap.id;

        const card = document.createElement('div');
        card.className = 'booking-card';
        card.innerHTML = `
            <div class="booking-header">
                <div>
                    <div class="booking-title">${escapeHtml(data.typeOfWork || 'Service Request')}</div>
                    <div class="booking-date">${formatDate(data.createdAt)}</div>
                </div>
                <span class="booking-status status-${(data.status || 'new').toLowerCase()}">${data.status || 'New'}</span>
            </div>
            
            <div class="booking-content">
                <div class="booking-detail-row">
                    <span class="booking-detail-label">Location:</span>
                    <span>${escapeHtml(data.district || 'N/A')}</span>
                </div>
                <div class="booking-detail-row">
                    <span class="booking-detail-label">Phone:</span>
                    <span>${escapeHtml(data.phone || 'N/A')}</span>
                </div>
                ${data.siteLocation ? `
                <div class="booking-detail-row">
                    <span class="booking-detail-label">Site:</span>
                    <span>${escapeHtml(data.siteLocation.split('[')[0])}</span>
                </div>` : ''}
            </div>

            <!-- Messages Section -->
            <div class="booking-messages">
                <div class="messages-header">
                    <span>💬 Updates & Messages</span>
                </div>
                <div class="messages-list" id="messages-${id}">
                    <div class="no-messages">Checking for updates...</div>
                </div>
            </div>
        `;

        grid.appendChild(card);

        // Listen for messages (Internal Notes)
        listenForMessages(id, currentUid);
    });
}

function listenForMessages(bookingId, currentUid) {
    const notesRef = collection(db, `bookings/${bookingId}/internalNotes`);
    const q = query(notesRef, orderBy('createdAt', 'asc')); // Oldest first to show conversation flow

    const unsubscribe = onSnapshot(q, (snapshot) => {
        const listContainer = document.getElementById(`messages-${bookingId}`);
        if (!listContainer) return;

        if (snapshot.empty) {
            listContainer.innerHTML = '<div class="no-messages">No updates yet.</div>';
            return;
        }

        listContainer.innerHTML = ''; // Clear loading/empty text

        snapshot.docs.forEach(doc => {
            const note = doc.data();

            // Determine display name
            // If author is NOT me, it's JS Brixen
            let authorDisplay = 'JS Brixen';
            if (note.authorUid === currentUid) {
                authorDisplay = 'You';
            } else if (note.authorName && !note.authorName.includes('@')) {
                // Fallback if UID logic fails but name is clean
                authorDisplay = note.authorName;
            }

            const bubble = document.createElement('div');
            bubble.className = 'message-bubble';
            // Add class for styling my vs their messages if needed
            if (note.authorUid === currentUid) bubble.classList.add('message-mine');

            bubble.innerHTML = `
                <div class="message-meta">
                    <span class="message-author">${escapeHtml(authorDisplay)}</span>
                    <span>${formatTime(note.createdAt)}</span>
                </div>
                <div>${escapeHtml(note.text)}</div>
            `;
            listContainer.appendChild(bubble);
        });

        // Scroll to bottom
        listContainer.scrollTop = listContainer.scrollHeight;
    }, (error) => {
        console.error('Error listening to messages:', error);
        const listContainer = document.getElementById(`messages-${bookingId}`);
        if (listContainer) listContainer.innerHTML = '<div class="no-messages">Unable to load messages.</div>';
    });

    unsubscribeCallbacks.push(unsubscribe);
}

// Helpers
function showAuthRequired() {
    container.innerHTML = `
        <div class="auth-required-state">
            <h3>Please Sign In</h3>
            <p>You need to be signed in to view your bookings.</p>
            <button class="btn-primary" onclick="document.querySelector('.nav__account-toggle').click()">Sign In</button>
        </div>
    `;
}

function formatDate(timestamp) {
    if (!timestamp) return '';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

function formatTime(timestamp) {
    if (!timestamp) return '';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

