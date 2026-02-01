/**
 * Global Rate Limit Checker
 * Updates all "Book Free Consultation" buttons with countdown if user is rate limited
 * This runs on every page
 */

let globalRateLimitInterval = null;
let consultationButtons = [];

/**
 * Generate user fingerprint for rate limiting
 */
function getUserFingerprint() {
    const customer = window.CustomerAuth?.getCurrentCustomer();
    const email = customer?.email || '';

    const fingerprint = {
        ua: navigator.userAgent,
        lang: navigator.language,
        screen: `${screen.width}x${screen.height}`,
        tz: new Date().getTimezoneOffset()
    };

    const fingerprintStr = JSON.stringify(fingerprint);
    return email ? `user_${email}` : `anon_${btoa(fingerprintStr).substring(0, 32)}`;
}

/**
 * Check if user is currently rate limited
 */
async function checkGlobalRateLimit() {
    // Rate limiting disabled per user request
    return { limited: false, remainingSeconds: 0, cooldownMinutes: 0 };
}

/**
 * Update all consultation buttons with countdown or normal state
 */
function updateConsultationButtons(remainingSeconds) {
    // Always search for buttons (handles dynamically loaded content)
    consultationButtons = Array.from(document.querySelectorAll('a[href*="book-consultation"], a[href*="booking-form"], button[type="submit"]'))
        .filter(btn => {
            const text = btn.textContent.trim().toLowerCase();
            return text.includes('book') && (text.includes('consultation') || text.includes('available'));
        });

    if (consultationButtons.length === 0) {
        console.log('[GlobalRateLimit] No consultation buttons found yet');
        return;
    }

    consultationButtons.forEach(btn => {
        if (remainingSeconds > 0) {
            // Show countdown
            const minutes = Math.floor(remainingSeconds / 60);
            const seconds = remainingSeconds % 60;
            const timeStr = minutes > 0
                ? `${minutes}:${seconds.toString().padStart(2, '0')}`
                : `${seconds}s`;

            // Disable and update text
            if (btn.tagName === 'BUTTON') {
                btn.disabled = true;
                btn.textContent = `Available in ${timeStr}`;
            } else {
                // It's an <a> tag
                btn.style.pointerEvents = 'none';
                btn.style.opacity = '0.6';
                btn.style.cursor = 'not-allowed';
                btn.textContent = `⏱️ Available in ${timeStr}`;
            }
            // Reset to normal
            if (btn.tagName === 'BUTTON') {
                btn.disabled = false;
                btn.innerHTML = 'Book Free Consultation <i class="fas fa-arrow-right"></i>';
            } else {
                btn.style.pointerEvents = '';
                btn.style.opacity = '';
                btn.style.cursor = '';
                btn.innerHTML = 'Book Free Consultation <i class="fas fa-arrow-right"></i>';
            }
        }
    });
}

/**
 * Start global countdown for all consultation buttons
 */
function startGlobalCountdown(initialSeconds) {
    let remaining = initialSeconds;

    // Clear any existing interval
    if (globalRateLimitInterval) {
        clearInterval(globalRateLimitInterval);
    }

    // Update immediately
    updateConsultationButtons(remaining);

    // Update every second
    globalRateLimitInterval = setInterval(() => {
        remaining--;

        if (remaining <= 0) {
            clearInterval(globalRateLimitInterval);
            globalRateLimitInterval = null;
            updateConsultationButtons(0);
        } else {
            updateConsultationButtons(remaining);
        }
    }, 1000);
}

/**
 * Initialize global rate limit check on page load
 */
async function initGlobalRateLimit() {
    let attempts = 0;
    const maxAttempts = 5;

    const tryCheck = async () => {
        attempts++;
        const result = await checkGlobalRateLimit();

        if (result.limited) {
            console.log(`[GlobalRateLimit] User rate limited for ${result.remainingSeconds}s`);
            startGlobalCountdown(result.remainingSeconds);
        } else {
            console.log('[GlobalRateLimit] User not rate limited');
        }

        // Try updating buttons to see if they exist
        updateConsultationButtons(result.limited ? result.remainingSeconds : 0);

        // If no buttons found and still have attempts, retry
        if (consultationButtons.length === 0 && attempts < maxAttempts) {
            console.log(`[GlobalRateLimit] Retrying in ${500 * attempts}ms (attempt ${attempts}/${maxAttempts})`);
            setTimeout(tryCheck, 500 * attempts);
        }
    };

    // First attempt after a delay
    setTimeout(tryCheck, 1000);
}

// Run on page load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initGlobalRateLimit);
} else {
    initGlobalRateLimit();
}

// Export for use in other scripts
window.GlobalRateLimit = {
    check: checkGlobalRateLimit,
    startCountdown: startGlobalCountdown,
    updateButtons: updateConsultationButtons
};
