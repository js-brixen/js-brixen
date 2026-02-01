/**
 * JS Brixen - Utility Functions
 * Shared helpers for DOM manipulation, validation, and UX
 */

(function (window) {
    'use strict';

    // DOM Helpers
    window.$ = function (selector) {
        return document.querySelector(selector);
    };

    window.$$ = function (selector) {
        return document.querySelectorAll(selector);
    };

    /**
     * Debounce function - limits how often a function can be called
     * @param {Function} fn - Function to debounce
     * @param {number} delay - Delay in milliseconds
     * @returns {Function}
     */
    window.debounce = function (fn, delay) {
        let timeoutId;
        return function (...args) {
            clearTimeout(timeoutId);
            timeoutId = setTimeout(() => fn.apply(this, args), delay);
        };
    };

    /**
     * Get query parameter from URL
     * @param {string} name - Parameter name
     * @returns {string|null}
     */
    window.getQueryParam = function (name) {
        const urlParams = new URLSearchParams(window.location.search);
        return urlParams.get(name);
    };

    /**
     * Generate reference ID for bookings
     * Format: JC-YYYYMMDD-XXXX (e.g., JC-20260125-1234)
     * @returns {string}
     */
    window.generateRefId = function () {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const random = String(Math.floor(Math.random() * 10000)).padStart(4, '0');
        return `JC-${year}${month}${day}-${random}`;
    };

    /**
     * Check if user can submit (rate limiting via localStorage)
     * @param {string} key - Storage key
     * @param {number} cooldownMs - Cooldown period in milliseconds
     * @returns {boolean}
     */
    window.canSubmit = function (key, cooldownMs) {
        try {
            const lastSubmit = localStorage.getItem(`lastSubmit_${key}`);
            if (!lastSubmit) return true;

            const timeSince = Date.now() - parseInt(lastSubmit, 10);
            return timeSince >= cooldownMs;
        } catch (e) {
            // If localStorage is not available, allow submission
            return true;
        }
    };

    /**
     * Mark submission timestamp in localStorage
     * @param {string} key - Storage key
     */
    window.markSubmitted = function (key) {
        try {
            localStorage.setItem(`lastSubmit_${key}`, Date.now().toString());
        } catch (e) {
            // Silently fail if localStorage is not available
        }
    };

    /**
     * Announce message to screen readers via ARIA live region
     * @param {string} message - Message to announce
     * @param {string} priority - 'polite' or 'assertive'
     */
    window.announce = function (message, priority = 'polite') {
        let liveRegion = $('#aria-live-region');

        if (!liveRegion) {
            liveRegion = document.createElement('div');
            liveRegion.id = 'aria-live-region';
            liveRegion.className = 'sr-only';
            liveRegion.setAttribute('aria-live', priority);
            liveRegion.setAttribute('aria-atomic', 'true');
            document.body.appendChild(liveRegion);
        }

        // Clear and set new message
        liveRegion.textContent = '';
        setTimeout(() => {
            liveRegion.textContent = message;
        }, 100);
    };

    /**
     * Create a simple focus trap for modals
     * @param {HTMLElement} element - Container element
     * @returns {Object} - Object with activate/deactivate methods
     */
    window.createFocusTrap = function (element) {
        const focusableElements = element.querySelectorAll(
            'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'
        );

        const firstFocusable = focusableElements[0];
        const lastFocusable = focusableElements[focusableElements.length - 1];

        function handleKeyDown(e) {
            if (e.key !== 'Tab') return;

            if (e.shiftKey) {
                if (document.activeElement === firstFocusable) {
                    e.preventDefault();
                    lastFocusable.focus();
                }
            } else {
                if (document.activeElement === lastFocusable) {
                    e.preventDefault();
                    firstFocusable.focus();
                }
            }
        }

        return {
            activate: function () {
                element.addEventListener('keydown', handleKeyDown);
                if (firstFocusable) firstFocusable.focus();
            },
            deactivate: function () {
                element.removeEventListener('keydown', handleKeyDown);
            }
        };
    };

    /**
     * Validate email format
     * @param {string} email
     * @returns {boolean}
     */
    window.isValidEmail = function (email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    };

    /**
     * Validate Indian phone number
     * Accepts: 9876543210, +91 9876543210, +91-9876543210, 09876543210
     * @param {string} phone
     * @returns {boolean}
     */
    window.isValidIndianPhone = function (phone) {
        const re = /^(\+91[\-\s]?|0)?[6-9]\d{9}$/;
        return re.test(phone.replace(/\s/g, ''));
    };

    /**
     * Smooth scroll to element
     * @param {string|HTMLElement} target - Selector or element
     * @param {number} offset - Offset from top (default: 80px for header)
     */
    window.smoothScrollTo = function (target, offset = 80) {
        const element = typeof target === 'string' ? $(target) : target;
        if (!element) return;

        const elementPosition = element.getBoundingClientRect().top + window.pageYOffset;
        const offsetPosition = elementPosition - offset;

        window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
        });
    };

    /**
     * Show element with animation
     * @param {HTMLElement} element
     */
    window.showElement = function (element) {
        element.hidden = false;
        element.style.display = 'block';
    };

    /**
     * Hide element
     * @param {HTMLElement} element
     */
    window.hideElement = function (element) {
        element.hidden = true;
        element.style.display = 'none';
    };

    /**
     * Toggle element visibility
     * @param {HTMLElement} element
     */
    window.toggleElement = function (element) {
        if (element.hidden) {
            showElement(element);
        } else {
            hideElement(element);
        }
    };

    /**
     * Format date to YYYY-MM-DD
     * @param {Date} date
     * @returns {string}
     */
    window.formatDate = function (date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    };

    /**
     * Get today's date in YYYY-MM-DD format
     * @returns {string}
     */
    window.getTodayDate = function () {
        return formatDate(new Date());
    };

    /**
     * Sanitize HTML to prevent XSS
     * @param {string} str
     * @returns {string}
     */
    window.sanitizeHTML = function (str) {
        const temp = document.createElement('div');
        temp.textContent = str;
        return temp.innerHTML;
    };

    /**
     * Show toast notification (simple)
     * @param {string} message
     * @param {string} type - 'success', 'error', 'info'
     * @param {number} duration - Duration in ms (default: 3000)
     */
    window.showToast = function (message, type = 'info', duration = 3000) {
        const toast = document.createElement('div');
        toast.className = `toast toast--${type}`;
        toast.textContent = message;
        toast.style.cssText = `
      position: fixed;
      bottom: 20px;
      right: 20px;
      padding: 1rem 1.5rem;
      background-color: ${type === 'success' ? '#28a745' : type === 'error' ? '#e74c3c' : '#3498db'};
      color: white;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      z-index: 10000;
      animation: slideInRight 0.3s ease;
    `;

        document.body.appendChild(toast);

        setTimeout(() => {
            toast.style.animation = 'slideOutRight 0.3s ease';
            setTimeout(() => toast.remove(), 300);
        }, duration);
    };

    /**
     * Show toast with countdown timer
     * @param {string} datePrefix - Text before timer
     * @param {number} seconds - Seconds to count down
     * @param {string} type - 'success', 'error', 'info'
     */
    window.showCountdownToast = function (textPrefix, seconds, type = 'error') {
        const toast = document.createElement('div');
        toast.className = `toast toast--${type}`;
        toast.style.cssText = `
      position: fixed;
      bottom: 20px;
      right: 20px;
      padding: 1rem 1.5rem;
      background-color: ${type === 'success' ? '#28a745' : type === 'error' ? '#e74c3c' : '#3498db'};
      color: white;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      z-index: 10000;
      animation: slideInRight 0.3s ease;
      font-weight: 500;
      display: flex;
      align-items: center;
      gap: 10px;
    `;

        let remaining = Math.ceil(seconds);

        const updateText = () => {
            toast.textContent = `${textPrefix} ${remaining}s ...`;
        };
        updateText();

        document.body.appendChild(toast);

        const interval = setInterval(() => {
            remaining--;
            if (remaining <= 0) {
                clearInterval(interval);
                toast.style.animation = 'slideOutRight 0.3s ease';
                setTimeout(() => toast.remove(), 300);
            } else {
                updateText();
            }
        }, 1000);
    };

    // Add CSS for toast animations
    if (!$('#toast-styles')) {
        const style = document.createElement('style');
        style.id = 'toast-styles';
        style.textContent = `
      @keyframes slideInRight {
        from { transform: translateX(400px); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
      }
      @keyframes slideOutRight {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(400px); opacity: 0; }
      }
    `;
        document.head.appendChild(style);
    }

})(window);

