/**
 * JS Brixen - Booking Form Handler
 * 
 * DEVELOPER NOTE:
 * This file handles client-side validation and UX for the booking form.
 * Firestore integration hooks are marked with TODO comments.
 * Replace placeholder phone numbers and email addresses before deployment.
 * 
 * ANTI-SPAM & RATE-LIMITING BEST PRACTICES:
 * 1. Honeypot field: hidden input that bots fill but humans don't
 * 2. Client-side throttle: localStorage-based 30s cooldown
 * 
 * FOR PRODUCTION:
 * - Implement server-side rate-limiting (e.g., 5 submissions per IP per hour)
 * - Add reCAPTCHA v3 or Cloudflare Turnstile
 * - Use Cloud Functions to validate before writing to Firestore
 * - Set Firestore security rules to prevent direct client writes
 */

/**
 * JS Brixen - Booking Form Handler
 * 
 * DEVELOPER NOTE:
 * This file handles client-side validation and UX for the booking form.
 * Firestore integration hooks are marked with TODO comments.
 * Replace placeholder phone numbers and email addresses before deployment.
 * 
 * ANTI-SPAM & RATE-LIMITING BEST PRACTICES:
 * 1. Honeypot field: hidden input that bots fill but humans don't
 * 2. Client-side throttle: localStorage-based 30s cooldown
 * 
 * FOR PRODUCTION:
 * - Implement server-side rate-limiting (e.g., 5 submissions per IP per hour)
 * - Add reCAPTCHA v3 or Cloudflare Turnstile
 * - Use Cloud Functions to validate before writing to Firestore
 * - Set Firestore security rules to prevent direct client writes
 */

import { getCurrentLocation } from './location-utils.js';

// Form elements
let form, successDiv, formWrapper;

// Validation rules
const validators = {
    fullName: {
        required: true,
        minLength: 2,
        maxLength: 100,
        message: 'Please enter your full name (at least 2 characters)'
    },
    phone: {
        required: true,
        pattern: /^(\+91[\-\s]?|0)?[6-9]\d{9}$/,
        message: 'Please enter a valid Indian phone number (e.g., 9876543210)'
    },
    district: {
        required: true,
        message: 'Please select your district'
    },
    typeOfWork: {
        required: true,
        message: 'Please select the type of work'
    },
    email: {
        required: false,
        pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
        message: 'Please enter a valid email address'
    },
    consent: {
        required: true,
        message: 'You must agree to be contacted'
    }
};

// Rate limiting state
let rateLimitCheckInterval = null;
let submitButton = null;

/**
 * Generate a user fingerprint for rate limiting
 * Combines email (if logged in) with browser fingerprint
 * @returns {string}
 */
function getUserFingerprint() {
    const customer = window.CustomerAuth?.getCurrentCustomer();
    const email = customer?.email || '';

    // Create a simple browser fingerprint
    const fingerprint = {
        ua: navigator.userAgent,
        lang: navigator.language,
        screen: `${screen.width}x${screen.height}`,
        tz: new Date().getTimezoneOffset()
    };

    const fingerprintStr = JSON.stringify(fingerprint);

    // Combine email and fingerprint for unique ID
    return email ? `user_${email}` : `anon_${btoa(fingerprintStr).substring(0, 32)}`;
}

/**
 * Check if user is rate limited
 * @returns {Promise<{ limited: boolean, remainingSeconds: number, cooldownMinutes: number }>}
 */
async function checkRateLimit() {
    try {
        const { initializeApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
        const { getFirestore, doc, getDoc } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

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

        // Get cooldown setting from appSettings
        const settingsRef = doc(db, 'appSettings', 'general');
        if (!window.bookingCooldownSeconds) {
            const settingsSnap = await getDoc(settingsRef);

            let cooldownSeconds = 300; // Default 5 min
            if (settingsSnap.exists()) {
                const data = settingsSnap.data();
                if (data.bookingCooldownSeconds !== undefined) {
                    cooldownSeconds = data.bookingCooldownSeconds;
                } else if (data.bookingCooldownMinutes !== undefined) {
                    cooldownSeconds = data.bookingCooldownMinutes * 60;
                }
            }
            window.bookingCooldownSeconds = cooldownSeconds;
            console.log('[RateLimit] Loaded cooldown setting:', cooldownSeconds, 'seconds');
        }

        // Check user's last submission time
        const userFingerprint = getUserFingerprint();
        const rateLimitRef = doc(db, 'bookingRateLimits', userFingerprint);
        const rateLimitSnap = await getDoc(rateLimitRef);

        if (rateLimitSnap.exists()) {
            const data = rateLimitSnap.data();
            const lastBookingTime = data.lastBookingTime?.toMillis();

            if (lastBookingTime) {
                const now = Date.now();
                const elapsedMs = now - lastBookingTime;
                const cooldownMs = window.bookingCooldownSeconds * 1000;

                if (elapsedMs < cooldownMs) {
                    const remainingMs = cooldownMs - elapsedMs;
                    const remainingSeconds = Math.ceil(remainingMs / 1000);
                    console.log('[RateLimit] User is rate limited for', remainingSeconds, 'seconds');
                    return {
                        limited: true,
                        remainingSeconds,
                        cooldownMinutes: Math.ceil(window.bookingCooldownSeconds / 60)
                    };
                }
            }
        }

        // Not limited
        console.log('[RateLimit] User is not rate limited');
        return {
            limited: false,
            remainingSeconds: 0,
            cooldownMinutes: Math.ceil(window.bookingCooldownSeconds / 60)
        };

    } catch (error) {
        console.error('[RateLimit] Error fetching rate limit:', error);
        window.bookingCooldownSeconds = window.bookingCooldownSeconds || 300;
        return { limited: false, remainingSeconds: 0, cooldownMinutes: 5 };
    }
}

/**
 * Record successful booking submission for rate limiting
 */
async function recordBookingSubmission() {
    try {
        const { initializeApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
        const { getFirestore, doc, setDoc, serverTimestamp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

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
        const userFingerprint = getUserFingerprint();
        const customer = window.CustomerAuth?.getCurrentCustomer();

        await setDoc(doc(db, 'bookingRateLimits', userFingerprint), {
            lastBookingTime: serverTimestamp(),
            userEmail: customer?.email || null,
            createdAt: serverTimestamp()
        });

        console.log('[RateLimit] Booking submission recorded');
    } catch (error) {
        console.error('[RateLimit] Error recording submission:', error);
    }
}

/**
 * Update submit button with countdown timer
 * @param {number} remainingSeconds
 */
function updateSubmitButtonCountdown(remainingSeconds) {
    if (!submitButton) submitButton = $('button[type="submit"]');
    if (!submitButton) return;

    const minutes = Math.floor(remainingSeconds / 60);
    const seconds = remainingSeconds % 60;
    const timeStr = minutes > 0
        ? `${minutes}:${seconds.toString().padStart(2, '0')}`
        : `${seconds}s`;

    submitButton.disabled = true;
    submitButton.textContent = `Available in ${timeStr}`;
    submitButton.style.cursor = 'not-allowed';
    submitButton.style.opacity = '0.6';
}

/**
 * Reset submit button to normal state
 */
function resetSubmitButton() {
    if (!submitButton) submitButton = $('button[type="submit"]');
    if (!submitButton) return;

    submitButton.disabled = false;
    submitButton.textContent = 'Book Free Consultation';
    submitButton.style.cursor = 'pointer';
    submitButton.style.opacity = '1';

    // Restart urgency timer
    // startUrgencyTimer(); // Disabled per user request
}

/**
 * Start countdown timer for rate limit
 * @param {number} initialSeconds
 */
function startRateLimitCountdown(initialSeconds) {
    let remaining = initialSeconds;

    // Clear urgency timer if running
    if (urgencyInterval) {
        clearInterval(urgencyInterval);
        urgencyInterval = null;
    }

    // Clear any existing limit interval
    if (rateLimitCheckInterval) {
        clearInterval(rateLimitCheckInterval);
    }

    // Update immediately
    updateSubmitButtonCountdown(remaining);

    // Update every second
    rateLimitCheckInterval = setInterval(() => {
        remaining--;

        if (remaining <= 0) {
            clearInterval(rateLimitCheckInterval);
            rateLimitCheckInterval = null;
            resetSubmitButton();
        } else {
            updateSubmitButtonCountdown(remaining);
        }
    }, 1000);
}

// Urgency Timer State
let urgencyInterval = null;
let urgencyDuration = 15 * 60; // Default 15 mins

/**
 * Fetch app settings from Firestore
 */
async function fetchAppSettings() {
    try {
        const { initializeApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
        const { getFirestore, doc, getDoc } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

        // Reuse config
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
        const settingsRef = doc(db, 'appSettings', 'general');
        const settingsSnap = await getDoc(settingsRef);

        if (settingsSnap.exists()) {
            const data = settingsSnap.data();
            if (data.urgencyTimerDuration) {
                urgencyDuration = data.urgencyTimerDuration;
                console.log('[UrgencyTimer] Updated duration to', urgencyDuration, 'seconds');
            }
        }
    } catch (e) {
        console.warn('[UrgencyTimer] Failed to fetch settings, using default:', e);
    }
}

/**
 * Start the "Urgency" countdown (visual only, loops)
 */
function startUrgencyTimer() {
    if (!submitButton) submitButton = $('button[type="submit"]');
    if (!submitButton) return;

    // Don't start if rate limited (button disabled)
    if (submitButton.disabled) return;

    // Clear existing
    if (urgencyInterval) clearInterval(urgencyInterval);

    // logical start time: client-side simplistic approach
    // We just count down from 15:00 for this session
    let timeLeft = urgencyDuration;

    function updateVisual() {
        if (submitButton.disabled) return; // Stop if disabled

        // Hours support
        const hours = Math.floor(timeLeft / 3600);
        const mins = Math.floor((timeLeft % 3600) / 60);
        const secs = timeLeft % 60;

        let timeStr = '';
        if (hours > 0) {
            timeStr = `${hours}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        } else {
            timeStr = `${mins}:${secs.toString().padStart(2, '0')}`;
        }

        // Preserve original text if needed, but usually we replace or append
        submitButton.innerHTML = `Book Free Consultation <span style="font-feature-settings: 'tnum'; font-variant-numeric: tabular-nums;">(${timeStr})</span>`;

        timeLeft--;
        if (timeLeft < 0) {
            timeLeft = urgencyDuration; // Loop
        }
    }

    updateVisual(); // Immediate
    urgencyInterval = setInterval(updateVisual, 1000);
}


/**
 * Initialize booking form
 */
function init() {
    form = $('#consultationForm');
    successDiv = $('#formSuccess');
    formWrapper = $('.form-wrapper');

    if (!form) return;

    setupValidation();
    prefillFromQuery();
    setupFAQ();

    // Setup Location Detection
    const detectBtn = $('#detectLocationBtn');
    if (detectBtn) {
        detectBtn.addEventListener('click', () => handleLocationDetection(false));
    }

    // Auto-fill from Auth
    window.addEventListener('customerAuthStateChanged', (e) => {
        if (e.detail) {
            prefillFromAuth(e.detail);
        }
    });

    // Check initial auth state
    if (window.CustomerAuth) {
        if (window.CustomerAuth.getCurrentCustomer()) {
            prefillFromAuth(window.CustomerAuth.getCurrentCustomer());
        } else {
            // Hint for non-logged in users
            setTimeout(() => {
                if (!window.CustomerAuth.getCurrentCustomer()) {
                    showToast('💡 Tip: Sign in to auto-fill your details', 'info');
                }
            }, 1000);
        }
    }

    // Auto-Location on load (silent)
    handleLocationDetection(true);

    // Initial Notes Template (Force it to show even if empty)
    updateNotesTemplate();

    // AI Notes Generation Listeners
    const aiFields = ['fullName', 'siteLocation', 'district', 'typeOfWork'];
    aiFields.forEach(id => {
        const el = $(`#${id}`);
        if (el) {
            el.addEventListener('input', updateNotesTemplate);
            el.addEventListener('change', updateNotesTemplate);
        }
    });

    form.addEventListener('submit', handleSubmit);

    // "Book another" button
    const bookAnotherBtn = $('#bookAnother');
    if (bookAnotherBtn) {
        bookAnotherBtn.addEventListener('click', resetForm);
    }

    // "Auto-fill" button
    const autoFillBtn = $('#autoFillBtn');
    if (autoFillBtn) {
        autoFillBtn.addEventListener('click', async () => {
            // 1. Try Location Detection
            handleLocationDetection(false); // false = show alerts if fails

            // 2. Try Auth
            if (window.CustomerAuth) {
                if (window.CustomerAuth.getCurrentCustomer()) {
                    prefillFromAuth(window.CustomerAuth.getCurrentCustomer());
                    announce('Filling details from your profile...', 'polite');
                } else {
                    // Prompt user to sign in to get their details
                    window.CustomerAuth.requireAuth(
                        (customer) => {
                            // On successful sign-in
                            prefillFromAuth(customer);
                            announce('Signed in! Details auto-filled.', 'polite');
                            showToast('Signed in successfully', 'success');
                        },
                        () => {
                            // On cancel
                            showToast('Sign in cancelled', 'info');
                        }
                    );
                    return; // Stop here, wait for auth callback
                }
            }

            // 3. Force notes update
            updateNotesTemplate();
        });
    }

    // Load dynamic services
    fetchAndPopulateServices();

    // Fetch urgency settings then check rate limit
    fetchAppSettings().then(() => {
        // Check rate limit on page load
        checkRateLimit().then(result => {
            if (result.limited) {
                console.log(`[RateLimit] User is rate limited for ${result.remainingSeconds}s`);
                startRateLimitCountdown(result.remainingSeconds);
            }
        });
    });
}

/**
 * Fetch services from Firestore and populate dropdown
 */
async function fetchAndPopulateServices() {
    const dropdown = $('#typeOfWork');
    console.log('[Services] Dropdown element:', dropdown);
    if (!dropdown) {
        console.error('[Services] Dropdown not found!');
        return;
    }

    try {
        console.log('[Services] Starting fetch...');
        // Reuse imports or import if needed
        const { initializeApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
        const { getFirestore, collection, getDocs } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

        // Config (Same as submitBooking)
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
        try {
            app = initializeApp(firebaseConfig);
        } catch (e) {
            const { getApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
            app = getApp();
        }

        const db = getFirestore(app);
        console.log('[Services] Firestore initialized');

        const snapshot = await getDocs(collection(db, 'services'));
        console.log('[Services] Snapshot received, size:', snapshot.size);

        const services = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            console.log('[Services] Doc data:', data);
            if (data.title) services.push(data.title);
        });

        console.log('[Services] Total services found:', services.length, services);

        // Add to dropdown (keep 'Other' at end)
        const otherOption = dropdown.querySelector('option[value="Other"]');
        console.log('[Services] Other option:', otherOption);

        services.forEach(serviceName => {
            const opt = document.createElement('option');
            opt.value = serviceName;
            opt.textContent = serviceName;

            if (otherOption) {
                dropdown.insertBefore(opt, otherOption);
            } else {
                dropdown.appendChild(opt);
            }
        });

        console.log('[Services] ✓ Dropdown populated with', services.length, 'services');

        // Re-check query param prefill after loading
        prefillFromQuery();

    } catch (error) {
        console.error('[Services] ❌ Error fetching services:', error);
        console.error('[Services] Error details:', error.message, error.stack);
        // Fallback: The dropdown already has "Other", maybe add default options back if fetch fails?
        // For now, "Other" allows manual entry.
    }
}

/**
 * Pre-fill form with authenticated customer data
 * @param {Object} customer 
 */
function prefillFromAuth(customer) {
    if (!customer) return;

    const nameField = $('#fullName');
    const phoneField = $('#phone');
    const emailField = $('#email'); // If we have an email field

    if (nameField && !nameField.value) {
        nameField.value = customer.displayName || '';
        // Trigger validation clearing
        nameField.dispatchEvent(new Event('input'));
    }

    if (phoneField && !phoneField.value && customer.phone) {
        phoneField.value = customer.phone;
        phoneField.dispatchEvent(new Event('input'));
    }

    if (emailField && !emailField.value && customer.email) {
        emailField.value = customer.email;
        emailField.dispatchEvent(new Event('input'));
    }
    // Updates Notes immediately
    updateNotesTemplate();
}

/**
 * Standard templates for different project types
 */
const NOTES_TEMPLATES = {
    'New House Construction': "I am planning to build a new dream home. I have a plot ready and would like to discuss the design and construction process.",
    'Renovation & Remodeling': "I am looking to renovate my existing property. I would like to modernize the space and need professional advice on the best approach.",
    'Interior Design': "I am interested in interior design services for my home. I want to create a space that is both functional and aesthetically pleasing.",
    'Electrical & Plumbing': "I need assistance with electrical and plumbing work for my project. I require a reliable team to ensure high-quality installation.",
    'Waterproofing': "I am facing leakage issues and need waterproofing solutions. I am looking for a permanent fix to protect my property.",
    'Turnkey Project': "I am looking for a complete turnkey solution for my project. I want a hassle-free experience from design to handover.",
    'default': "I need an appointment to discuss my project requirements and build my dream space here."
};

/**
 * Auto-generate "AI" notes based on user inputs
 * Now with professional, context-aware templates
 */
function updateNotesTemplate() {
    const notesField = $('#notes');
    if (!notesField) return;

    // Only update if empty or if it looks like our template (starts with "My name is")
    // OR if it matches one of our standard templates
    const currentNotes = notesField.value.trim();

    // Check if current notes match any known template starter to decide if we can overwrite
    const isTemplate = currentNotes === '' ||
        currentNotes.startsWith('My name is') ||
        Object.values(NOTES_TEMPLATES).some(t => currentNotes.includes(t.substring(0, 20)));

    if (!isTemplate) {
        return; // User has written custom text, don't overwrite
    }

    const name = $('#fullName')?.value.trim() || '___';

    // Get location components
    let locationStr = '___';
    const districtVal = $('#district')?.value;
    const siteLocVal = $('#siteLocation')?.value;

    // Clean up location string (remove Google Maps link for the sentence)
    if (siteLocVal) {
        // Remove [Google Maps: ...] part
        locationStr = siteLocVal.split('[Google Maps')[0].trim();
        // Remove trailing comma if exists
        if (locationStr.endsWith(',')) locationStr = locationStr.slice(0, -1);
    } else if (districtVal && districtVal !== '') {
        locationStr = districtVal;
    }

    const typeOfWork = $('#typeOfWork')?.value;
    const projectIntent = NOTES_TEMPLATES[typeOfWork] || NOTES_TEMPLATES['default'];

    // Construct the professional sentence
    const aiSentence = `My name is ${name} and I am from ${locationStr}. ${projectIntent}`;

    notesField.value = aiSentence;

    // Auto-resize
    notesField.style.height = 'auto';
    notesField.style.height = notesField.scrollHeight + 'px';
}

/**
 * Handle location detection
 * @param {boolean} isAuto - If true, run silently (no alerts)
 */
async function handleLocationDetection(isAuto = false) {
    const detectBtn = $('#detectLocationBtn');
    const locationField = $('#siteLocation');
    const districtField = $('#district');

    if (!locationField) return;

    // Check for Secure Context (HTTPS or localhost)
    if (!window.isSecureContext && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
        const port = window.location.port || '8080';
        const msg = `Location detection requires HTTPS or localhost. Please open: http://localhost:${port}/book-consultation.html`;
        console.warn(msg);

        // Update UI to warn user
        const detectBtn = $('#detectLocationBtn');
        const locationField = $('#siteLocation');

        if (detectBtn) {
            detectBtn.textContent = '⚠️ Use Localhost';
            detectBtn.title = msg;
            detectBtn.style.backgroundColor = '#ff9800'; // Orange warning
            detectBtn.style.color = '#000';
            detectBtn.disabled = false; // Let them click to see the alert
        }

        if (!isAuto) alert(msg);
        return;
    }

    const originalText = detectBtn ? detectBtn.textContent : '📍';
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

        locationField.value = addressText;

        // Try to auto-select district
        if (districtField) {
            const options = Array.from(districtField.options);
            let match = null;

            // 1. Try exact district match from API
            if (location.district) {
                match = options.find(opt =>
                    opt.value.toLowerCase() === location.district.toLowerCase() ||
                    opt.value.toLowerCase().includes(location.district.toLowerCase())
                );
            }

            // 2. If no match, try searching the FULL address string
            if (!match && location.address) {
                // Check if any dropdown option (e.g., "Kasaragod") appears in the address string
                // We skip "Other" and empty values
                match = options.find(opt =>
                    opt.value &&
                    opt.value !== 'Other' &&
                    location.address.toLowerCase().includes(opt.value.toLowerCase())
                );
            }

            if (match) {
                districtField.value = match.value;
                districtField.dispatchEvent(new Event('change'));
                districtField.dispatchEvent(new Event('input'));
            }
        }

        if (!isAuto) {
            announce('Location detected and filled successfully', 'polite');
        }

        // Updates Notes immediately
        updateNotesTemplate();

    } catch (error) {
        console.error('Location error:', error);
        if (!isAuto) {
            alert('Could not detect location: ' + error.message);
        }
    } finally {
        if (detectBtn) {
            detectBtn.textContent = originalText;
            detectBtn.disabled = false;
        }
    }
}

/**
 * Setup inline validation for form fields
 */
function setupValidation() {
    const fields = ['fullName', 'phone', 'district', 'typeOfWork', 'email'];

    fields.forEach(fieldName => {
        const field = $(`#${fieldName}`);
        if (!field) return;

        // Validate on blur
        field.addEventListener('blur', () => validateField(fieldName));

        // Clear error on input
        field.addEventListener('input', () => clearFieldError(fieldName));
    });

    // Consent checkbox
    const consentCheckbox = $('#consent');
    if (consentCheckbox) {
        consentCheckbox.addEventListener('change', () => {
            if (consentCheckbox.checked) {
                clearFieldError('consent');
            }
        });
    }
}

/**
 * Validate a single field
 * @param {string} fieldName
 * @returns {boolean}
 */
function validateField(fieldName) {
    const field = $(`#${fieldName}`);
    const rules = validators[fieldName];

    if (!field || !rules) return true;

    const value = field.value.trim();
    const formGroup = field.closest('.form-group') || field.closest('.consent-group');

    // Check required
    if (rules.required && !value) {
        showFieldError(fieldName, rules.message);
        return false;
    }

    // Skip other validations if field is optional and empty
    if (!rules.required && !value) {
        clearFieldError(fieldName);
        return true;
    }

    // Check minLength
    if (rules.minLength && value.length < rules.minLength) {
        showFieldError(fieldName, rules.message);
        return false;
    }

    // Check maxLength
    if (rules.maxLength && value.length > rules.maxLength) {
        showFieldError(fieldName, `Maximum ${rules.maxLength} characters allowed`);
        return false;
    }

    // Check pattern
    if (rules.pattern && !rules.pattern.test(value)) {
        showFieldError(fieldName, rules.message);
        return false;
    }

    clearFieldError(fieldName);
    return true;
}

/**
 * Show field error
 * @param {string} fieldName
 * @param {string} message
 */
function showFieldError(fieldName, message) {
    const field = $(`#${fieldName}`);
    if (!field) return;

    const formGroup = field.closest('.form-group') || field.closest('.consent-group');
    if (!formGroup) return;

    formGroup.classList.add('has-error');
    field.setAttribute('aria-invalid', 'true');

    // Remove existing error message
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
 * Clear field error
 * @param {string} fieldName
 */
function clearFieldError(fieldName) {
    const field = $(`#${fieldName}`);
    if (!field) return;

    const formGroup = field.closest('.form-group') || field.closest('.consent-group');
    if (!formGroup) return;

    formGroup.classList.remove('has-error');
    field.setAttribute('aria-invalid', 'false');

    const errorMsg = formGroup.querySelector('.error-message');
    if (errorMsg) errorMsg.remove();
}

/**
 * Check if honeypot field is filled (spam detection)
 * @returns {boolean}
 */
function isSpamSubmission() {
    const honeypot = $('input[name="website"]');
    return honeypot && honeypot.value.trim() !== '';
}

/**
 * Collect form data
 * @returns {Object}
 */
function collectFormData() {
    return {
        fullName: $('#fullName').value.trim(),
        phone: $('#phone').value.trim(),
        district: $('#district').value,
        typeOfWork: $('#typeOfWork').value,
        plotSize: $('#plotSize')?.value.trim() || '',
        budgetRange: $('#budgetRange')?.value || '',
        siteLocation: $('#siteLocation')?.value.trim() || '', // Added siteLocation
        preferredDate: $('#preferredDate')?.value || '',
        preferredTime: $('#preferredTime')?.value || '',
        notes: $('#notes')?.value.trim() || '',
        refId: generateRefId(),
        timestamp: new Date().toISOString()
    };
}


/**
 * Handle form submission
 * @param {Event} e
 */
async function handleSubmit(e) {
    e.preventDefault();

    // Validate all required fields
    const fieldsToValidate = ['fullName', 'phone', 'district', 'typeOfWork'];
    let isValid = true;

    fieldsToValidate.forEach(fieldName => {
        if (!validateField(fieldName)) {
            isValid = false;
        }
    });

    // Validate consent
    const consentCheckbox = $('#consent');
    if (!consentCheckbox.checked) {
        showFieldError('consent', 'You must agree to be contacted');
        isValid = false;
    }

    if (!isValid) {
        announce('Please fix the errors in the form', 'assertive');
        // Scroll to first error
        const firstError = $('.has-error');
        if (firstError) {
            smoothScrollTo(firstError);
        }
        return;
    }

    // CHECK RATE LIMIT - Pr event spam submissions
    const rateLimit = await checkRateLimit();
    if (rateLimit.limited) {
        const minutes = Math.floor(rateLimit.remainingSeconds / 60);
        const seconds = rateLimit.remainingSeconds % 60;
        const timeStr = minutes > 0
            ? `${minutes} minute${minutes > 1 ? 's' : ''} and ${seconds} second${seconds !== 1 ? 's' : ''}`
            : `${seconds} second${seconds !== 1 ? 's' : ''}`;

        showToast(`⏱️ Please wait ${timeStr} before booking again`, 'warning');
        startRateLimitCountdown(rateLimit.remainingSeconds);
        return;
    }

    // CHECK AUTHENTICATION - New customers must sign in first
    if (window.CustomerAuth && !window.CustomerAuth.isLoggedIn()) {
        console.log('User not authenticated, showing auth modal...');

        // Wait for authentication
        window.CustomerAuth.requireAuth(
            async (customer) => {
                console.log('Customer authenticated:', customer);
                // Customer authenticated, proceed with submission
                await proceedWithSubmission();
            },
            () => {
                console.log('User cancelled authentication');
                showToast('Please sign in to book your consultation', 'error');
            }
        );
        return;
    }

    // Already authenticated, proceed
    await proceedWithSubmission();
}

/**
 * Proceed with form submission after authentication
 */
async function proceedWithSubmission() {
    // Rate limit check (30s cooldown) - DISABLED
    // if (!canSubmit('booking', 30000)) { ... }

    // Honeypot check
    if (isSpamSubmission()) {
        // Silently reject spam - show fake success
        console.warn('Spam submission detected (honeypot filled)');
        showFakeSuccess();
        return;
    }

    // Collect data
    const data = collectFormData();

    // Disable button, show spinner
    setSubmitting(true);

    try {
        await submitBooking(data);
        markSubmitted('booking');

        showSuccess(data.refId);
        // resetForm(); // DON'T reset here - it hides success screen! Reset only on "Book Another" button

        // Analytics hook
        console.log('booking_submitted', {
            service: data.typeOfWork,
            district: data.district,
            refId: data.refId
        });

        announce('Booking submitted successfully! Our team will contact you soon.', 'polite');

        // FORCE START TIMER
        const cooldownSeconds = window.bookingCooldownSeconds || 300;
        console.log(`[RateLimit] Force starting timer for ${cooldownSeconds}s`);
        startRateLimitCountdown(cooldownSeconds);

        // DO NOT call setSubmitting(false) here because it re-enables the button!
        // The startRateLimitCountdown will handle the button state (updateSubmitButtonCountdown disables it).
        // Only setSubmitting(false) is needed to remove generating/loading spinner styles if any, 
        // but we need to be careful not to enable the button.

        // Remove loading state but keep disabled
        const submitBtn = form.querySelector('button[type="submit"]');
        if (submitBtn) {
            submitBtn.classList.remove('loading');
            submitBtn.setAttribute('aria-busy', 'false');
            // Ensure it remains disabled
            submitBtn.disabled = true;
        }

        // IMMEDIATE RATE LIMIT CHECK - DISABLED
        /*
        checkRateLimit().then(rateLimit => {
             if (rateLimit.limited && rateLimit.remainingSeconds > cooldownSeconds) {
                 startRateLimitCountdown(rateLimit.remainingSeconds);
             }
        });
        */

    } catch (err) {
        console.error('Booking error:', err);
        showToast('Something went wrong. Please try again or call us directly.', 'error', 5000);
        announce('Submission failed. Please try again.', 'assertive');
        setSubmitting(false);
    }
    // removed finally block to handle setSubmitting logic manually for timer preservation
}


/**
 * Submit booking data
 * Includes customer authentication data
 * 
 * @param {Object} data - Booking data
 * @returns {Promise}
 */
async function submitBooking(data) {
    try {
        // Import Firebase modules from CDN
        const { initializeApp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');
        const { getFirestore, collection, addDoc, serverTimestamp, Timestamp } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');

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

        // Prepare booking data for Firestore
        const bookingData = {
            name: data.fullName,
            phone: data.phone, // Phone from booking form
            district: data.district,
            typeOfWork: data.typeOfWork,
            plotSize: data.plotSize || null,
            budgetRange: data.budgetRange || null,
            siteLocation: data.siteLocation || null, // Added siteLocation
            preferredDate: data.preferredDate ? Timestamp.fromDate(new Date(data.preferredDate)) : null,
            preferredTime: data.preferredTime || null,
            notes: data.notes || null,
            status: 'new',
            source: 'website',
            relatedServiceId: getQueryParam('service') || null,
            relatedProjectId: getQueryParam('project') || null,
            priority: 'normal',
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
            // Customer authentication data (new fields)
            customerUid: customer?.uid || null,
            customerEmail: customer?.email || null,
            customerPhone: customer?.phone || null, // Phone from customer profile
        };

        console.log('DEBUG: Customer Object:', customer);
        console.log('DEBUG: Booking Auth Data:', {
            uid: bookingData.customerUid,
            email: bookingData.customerEmail,
            phone: bookingData.customerPhone
        });

        // Write to Firestore
        const docRef = await addDoc(collection(db, 'bookings'), bookingData);

        console.log('✅ Booking created with ID:', docRef.id);
        console.log('Booking data:', bookingData);

        // Record submission for rate limiting
        await recordBookingSubmission();

        // Start global countdown timer on all buttons
        if (window.GlobalRateLimit) {
            const cooldownMs = 5 * 60 * 1000; // 5 minutes default, will be updated by checkGlobalRateLimit
            const result = await window.GlobalRateLimit.check();
            if (result.limited) {
                window.GlobalRateLimit.startCountdown(result.remainingSeconds);
            }
        }

        return docRef;
    } catch (error) {
        console.error('❌ Firestore write error:', error);
        throw new Error(`Failed to submit booking: ${error.message}`);
    }
}


/**
 * Set submitting state
 * @param {boolean} isSubmitting
 */
function setSubmitting(isSubmitting) {
    const submitBtn = form.querySelector('button[type="submit"]');
    if (!submitBtn) return;

    if (isSubmitting) {
        submitBtn.disabled = true;
        submitBtn.classList.add('loading');
        submitBtn.setAttribute('aria-busy', 'true');
    } else {
        submitBtn.disabled = false;
        submitBtn.classList.remove('loading');
        submitBtn.setAttribute('aria-busy', 'false');
    }
}

/**
 * Show success state
 * @param {string} refId - Reference ID
 */
function showSuccess(refId) {
    // Hide form
    if (formWrapper) {
        hideElement(formWrapper);
    }

    // Show success message
    if (successDiv) {
        $('#refId').textContent = refId;
        showElement(successDiv);
        smoothScrollTo(successDiv);
    }
}

/**
 * Show fake success (for spam submissions)
 */
function showFakeSuccess() {
    showSuccess('SPAM-DETECTED');
    // Don't actually submit to backend
}

/**
 * Reset form to initial state
 */
function resetForm() {
    // form.reset(); // Disabled to keep data filled per user request

    // Clear all errors
    $$('.has-error').forEach(group => {
        group.classList.remove('has-error');
    });

    $$('.error-message').forEach(msg => msg.remove());

    // Show form, hide success
    if (formWrapper) showElement(formWrapper);
    if (successDiv) hideElement(successDiv);

    // Scroll to form
    smoothScrollTo(form);

    // Focus first field
    $('#fullName')?.focus();
}

/**
 * Prefill form from query parameters
 * Example: ?service=turnkey-project&district=Ernakulam
 */
function prefillFromQuery() {
    // Service mapping
    const serviceMapping = {
        'new-construction': 'New House Construction',
        'renovation': 'Renovation & Remodeling',
        'interior-design': 'Interior Design',
        'electrical-plumbing': 'Electrical & Plumbing',
        'waterproofing': 'Waterproofing',
        'turnkey-project': 'Turnkey Project',
        'garden': 'Garden with Fruits',
        'outhouse': 'Outhouse with Muds',
        'fishtank': 'Open Fishtank',
        'pet-house': 'Pet House',
        'kerala-traditional': 'Kerala Traditional House'
    };

    const service = getQueryParam('service');
    if (service && serviceMapping[service]) {
        const typeOfWorkField = $('#typeOfWork');
        if (typeOfWorkField) {
            typeOfWorkField.value = serviceMapping[service];
        }
    }

    const district = getQueryParam('district');
    if (district) {
        const districtField = $('#district');
        if (districtField) {
            // Try to match district (case-insensitive)
            const options = Array.from(districtField.options);
            const matchingOption = options.find(opt =>
                opt.value.toLowerCase() === district.toLowerCase()
            );
            if (matchingOption) {
                districtField.value = matchingOption.value;
            }
        }
    }
}

/**
 * Setup FAQ accordion
 */
function setupFAQ() {
    const faqButtons = $$('.faq-question');

    faqButtons.forEach(button => {
        button.addEventListener('click', function () {
            const isExpanded = this.getAttribute('aria-expanded') === 'true';
            const answer = this.nextElementSibling;

            // Close all other FAQs
            faqButtons.forEach(btn => {
                if (btn !== this) {
                    btn.setAttribute('aria-expanded', 'false');
                    const otherAnswer = btn.nextElementSibling;
                    if (otherAnswer) otherAnswer.classList.remove('active');
                }
            });

            // Toggle current FAQ
            this.setAttribute('aria-expanded', !isExpanded);
            if (answer) {
                answer.classList.toggle('active');
            }
        });
    });
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}

