/**
 * JS Brixen - Contact Form Handler
 * 
 * DEVELOPER NOTE:
 * This file handles the simple contact form validation and submission.
 * Firestore integration hooks are marked with TODO comments.
 */

import { getCurrentLocation } from './location-utils.js';

let form, successDiv;

/**
 * Initialize contact form
 */
function init() {
    form = $('#contactForm');
    successDiv = $('#contactSuccess');

    if (!form) return;

    form.addEventListener('submit', handleSubmit);

    // Setup Location Detection
    const detectBtn = $('#detectLocationBtn');
    if (detectBtn) {
        detectBtn.addEventListener('click', () => handleLocationDetection(false));
    }

    // Auto-Location on load
    handleLocationDetection(true);


    // Setup inline validation
    setupValidation();

    // Auto-fill from Auth
    window.addEventListener('customerAuthStateChanged', (e) => {
        if (e.detail) {
            prefillFromAuth(e.detail);
        }
    });

    // Check initial auth state
    if (window.CustomerAuth && window.CustomerAuth.getCurrentCustomer()) {
        prefillFromAuth(window.CustomerAuth.getCurrentCustomer());
    }
}

/**
 * Pre-fill form with authenticated customer data
 * @param {Object} customer 
 */
function prefillFromAuth(customer) {
    if (!customer) return;

    const nameField = $('#name');
    const emailField = $('#email');
    const phoneField = $('#phone'); // Optional field

    if (nameField && !nameField.value) {
        nameField.value = customer.displayName || '';
        nameField.dispatchEvent(new Event('input'));
    }

    if (emailField && !emailField.value) {
        emailField.value = customer.email || '';
        emailField.dispatchEvent(new Event('input'));
    }

    if (phoneField && !phoneField.value && customer.phone) {
        phoneField.value = customer.phone;
        phoneField.dispatchEvent(new Event('input'));
    }

    announce('Contact details auto-filled from your profile', 'polite');
}

/**
 * Handle location detection
 * @param {boolean} isAuto - If true, run silently (no alerts)
 */
async function handleLocationDetection(isAuto = false) {
    const detectBtn = $('#detectLocationBtn');
    const addressField = $('#address');

    if (!addressField) return;

    // Check for Secure Context (HTTPS or localhost)
    if (!window.isSecureContext && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
        const msg = "Location detection requires HTTPS or localhost";
        console.warn(msg);

        if (detectBtn) {
            detectBtn.textContent = '⚠️ Use Localhost';
            detectBtn.title = msg;
            detectBtn.style.backgroundColor = '#ff9800';
            detectBtn.style.color = '#000';
            detectBtn.disabled = false;
        }

        if (!isAuto) alert(msg + "\nPlease use http://localhost:8000");
        return;
    }

    const originalText = detectBtn ? detectBtn.textContent : '📍 Detect Location';
    if (detectBtn) {
        detectBtn.textContent = '⏳';
        detectBtn.disabled = true;
    }

    try {
        const location = await getCurrentLocation();

        let addressText = location.address;
        if (location.mapsLink) {
            addressText += `\n\n[Google Maps: ${location.mapsLink}]`;
        }

        addressField.value = addressText;
        addressField.dispatchEvent(new Event('input'));

        if (!isAuto) {
            announce('Location detected and filled successfully', 'polite');
        }

    } catch (error) {
        console.error('Location error:', error);
        if (!isAuto) {
            alert('Could not detect location: ' + error.message);
        }
    } finally {
        if (detectBtn) {
            detectBtn.textContent = originalText; // Restore original text
            detectBtn.disabled = false;
        }
    }
}

/**
 * Setup inline validation
 */
function setupValidation() {
    const nameField = $('#name');
    const emailField = $('#email');
    const messageField = $('#message');

    if (nameField) {
        nameField.addEventListener('blur', () => validateName());
        nameField.addEventListener('input', () => clearError(nameField));
    }

    if (emailField) {
        emailField.addEventListener('blur', () => validateEmail());
        emailField.addEventListener('input', () => clearError(emailField));
    }

    if (messageField) {
        messageField.addEventListener('blur', () => validateMessage());
        messageField.addEventListener('input', () => clearError(messageField));
    }

    const subjectField = $('#subject');
    if (subjectField) {
        subjectField.addEventListener('blur', () => validateSubject());
        subjectField.addEventListener('input', () => clearError(subjectField));
    }
}

/**
 * Validate subject field
 * @returns {boolean}
 */
function validateSubject() {
    const field = $('#subject');
    const value = field.value.trim();

    if (!value) {
        showError(field, 'Please enter a subject');
        return false;
    }
    clearError(field);
    return true;
}

/**
 * Validate name field
 * @returns {boolean}
 */
function validateName() {
    const field = $('#name');
    const value = field.value.trim();

    if (!value) {
        showError(field, 'Please enter your name');
        return false;
    }

    if (value.length < 2) {
        showError(field, 'Name must be at least 2 characters');
        return false;
    }

    clearError(field);
    return true;
}

/**
 * Validate email field
 * @returns {boolean}
 */
function validateEmail() {
    const field = $('#email');
    const value = field.value.trim();

    if (!value) {
        showError(field, 'Please enter your email address');
        return false;
    }

    if (!isValidEmail(value)) {
        showError(field, 'Please enter a valid email address');
        return false;
    }

    clearError(field);
    return true;
}

/**
 * Validate message field
 * @returns {boolean}
 */
function validateMessage() {
    const field = $('#message');
    const value = field.value.trim();

    if (!value) {
        showError(field, 'Please enter your message');
        return false;
    }

    if (value.length < 10) {
        showError(field, 'Message must be at least 10 characters');
        return false;
    }

    clearError(field);
    return true;
}

/**
 * Show error for a field
 * @param {HTMLElement} field
 * @param {string} message
 */
function showError(field, message) {
    const formGroup = field.closest('.form-group');
    if (!formGroup) return;

    formGroup.classList.add('has-error');
    field.setAttribute('aria-invalid', 'true');

    // Remove existing error
    const existingError = formGroup.querySelector('.error-message');
    if (existingError) existingError.remove();

    // Add error message
    const errorMsg = document.createElement('span');
    errorMsg.className = 'error-message';
    errorMsg.textContent = message;
    errorMsg.setAttribute('role', 'alert');
    formGroup.appendChild(errorMsg);
}

/**
 * Clear error for a field
 * @param {HTMLElement} field
 */
function clearError(field) {
    const formGroup = field.closest('.form-group');
    if (!formGroup) return;

    formGroup.classList.remove('has-error');
    field.setAttribute('aria-invalid', 'false');

    const errorMsg = formGroup.querySelector('.error-message');
    if (errorMsg) errorMsg.remove();
}

/**
 * Handle form submission
 * @param {Event} e
 */
async function handleSubmit(e) {
    e.preventDefault();

    // Validate all fields
    const isNameValid = validateName();
    const isEmailValid = validateEmail();
    const isSubjectValid = validateSubject();
    const isMessageValid = validateMessage();

    if (!isNameValid || !isEmailValid || !isSubjectValid || !isMessageValid) {
        announce('Please fix the errors in the form', 'assertive');
        return;
    }

    // Proceed directly with submission (Authentication optional for Contact Form)
    await proceedWithSubmission();
}

/**
 * Proceed with form submission
 */
async function proceedWithSubmission() {
    // Collect data
    const data = {
        name: $('#name').value.trim(),
        email: $('#email').value.trim(),
        phone: $('#phone')?.value.trim() || '',
        address: $('#address')?.value.trim() || '',
        subject: $('#subject').value.trim(),
        message: $('#message').value.trim(),
        timestamp: new Date().toISOString()
    };

    // 1. Open Email Client (Gmail/Default)
    const recipientEmail = window.siteContactEmail || 'nidhinmanoj424@gmail.com'; // Fallback to provided email
    const mailSubject = encodeURIComponent(`${data.subject} - Inquiry from ${data.name}`);
    const mailBody = encodeURIComponent(
        `Name: ${data.name}\n` +
        `Email: ${data.email}\n` +
        `Phone: ${data.phone}\n` +
        `Address: ${data.address}\n\n` +
        `Message:\n${data.message}`
    );

    // Construct Gmail Link
    const gmailLink = `https://mail.google.com/mail/?view=cm&fs=1&to=${recipientEmail}&su=${mailSubject}&body=${mailBody}`;

    // Open in new tab
    window.open(gmailLink, '_blank');

    // Disable submit button
    const submitBtn = form.querySelector('button[type="submit"]');
    if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.classList.add('loading');
    }

    try {
        // 2. Background: Submit to Firestore (Lead Backup)
        await submitContact(data);

        showSuccess(); // Show toast on page
        form.reset();

        announce('Opening your email client...', 'polite');

    } catch (err) {
        console.error('Contact form error (Firestore):', err);
        // Even if Firestore fails, the mailto likely opened, so we can still consider it a partial success 
        // from the user's perspective of "sending a message".
        showSuccess();
        form.reset();
    } finally {
        if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.classList.remove('loading');
        }
    }
}

/**
 * Submit contact data to Firestore
 * 
 * @param {Object} data - Contact data
 * @returns {Promise}
 */
async function submitContact(data) {
    try {
        // Import Firebase modules from CDN
        const { initializeApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
        const { getFirestore, collection, addDoc, serverTimestamp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

        // Firebase configuration
        const firebaseConfig = {
            apiKey: "AIzaSyBmE3dzzcbMXaustT4SBjhELZ4GWR9JKlU",
            authDomain: "js-construction-811e4.firebaseapp.com",
            projectId: "js-construction-811e4",
            storageBucket: "js-construction-811e4.firebasestorage.app",
            messagingSenderId: "465344186766",
            appId: "1:465344186766:web:382584d5d07ae059e03cdf",
            measurementId: "G-K1K5B5WHV8"
        };

        // Initialize Firebase (only once)
        let app;
        try {
            app = initializeApp(firebaseConfig);
        } catch (error) {
            // App already initialized, get existing instance
            const { getApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
            app = getApp();
        }

        // Get Firestore instance
        const db = getFirestore(app);

        // Get customer data (if authenticated)
        const customer = window.CustomerAuth ? window.CustomerAuth.getCurrentCustomer() : null;

        // Prepare contact request data for Firestore
        const contactData = {
            name: data.name,
            email: data.email, // Email from form
            phone: data.phone,
            address: data.address, // New field
            subject: data.subject, // New field
            message: data.message,
            status: 'new',
            createdAt: serverTimestamp(),
            // Customer authentication data
            customerUid: customer?.uid || null,
            customerEmail: customer?.email || null, // Customer's login email
        };

        // Write to Firestore
        const docRef = await addDoc(collection(db, 'contactRequests'), contactData);

        console.log('✅ Contact request created with ID:', docRef.id);
        console.log('Contact data:', contactData);

        return docRef;
    } catch (error) {
        console.error('❌ Firestore write error:', error);
        throw new Error(`Failed to submit contact request: ${error.message}`);
    }
}


/**
 * Show success message
 */
function showSuccess() {
    if (successDiv) {
        showElement(successDiv);
        smoothScrollTo(successDiv);

        // Hide after 5 seconds
        setTimeout(() => {
            hideElement(successDiv);
        }, 5000);
    } else {
        showToast('Message sent successfully! We will get back to you within 24 hours.', 'success', 5000);
    }
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}

