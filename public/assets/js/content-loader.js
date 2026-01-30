/**
 * Content Loader Module
 * Fetches dynamic content (Hero, About, Stats, CTA) from Firestore 'siteContent/main'
 * and updates the DOM elements.
 */

// Import Firebase SDKs from CDN
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.1.0/firebase-app.js";
import { getFirestore, doc, getDoc } from "https://www.gstatic.com/firebasejs/11.1.0/firebase-firestore.js";

// Firebase Configuration
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
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

/**
 * Fetches site content and updates the DOM
 */
export async function fetchAndRenderContent() {
    try {
        console.log('[ContentLoader] Fetching site content...');
        const docRef = doc(db, "siteContent", "main");
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
            const data = docSnap.data();
            console.log('[ContentLoader] Content fetched:', data);
            updateDOM(data);
        } else {
            console.log('[ContentLoader] No content found in Firestore!');
        }
    } catch (error) {
        console.error('[ContentLoader] Error fetching content:', error);
    }
}

function updateDOM(data) {
    if (!data) return;

    // 1. Hero Section
    if (data.hero) {
        setText('hero-title', data.hero.title);
        setText('hero-subtext', data.hero.subtext);
        setText('hero-cta', data.hero.ctaText);
    }

    // 2. About Section (Note: we need to add these IDs to index.html)
    if (data.about) {
        setText('about-story', data.about.story);
        updateStat('stat-projects', data.about.statsProjects);
        updateStat('stat-years', data.about.statsYears);
        updateStat('stat-team', data.about.statsTeam);
        updateStat('stat-clients', data.about.statsClients);
    }

    // 3. CTA Section
    if (data.cta) {
        setText('cta-title', data.cta.title);
        setText('cta-text', data.cta.text);
    }

    // 4. Contact Information (Global & Page Specific)
    if (data.contact) {
        updateContactInfo(data.contact);
    }
}

function updateContactInfo(contact) {
    // Helper to update links (href and text)
    const updateLink = (id, prefix, value) => {
        const el = document.getElementById(id);
        if (el && value) {
            el.href = `${prefix}${value}`;
            // If it's a global footer link, we might want to keep the icon
            if (el.dataset.keepIcon) {
                // Preserves icon if text starts with emoji/icon
                const text = el.textContent;
                const icon = text.match(/^[\p{Emoji}\u2600-\u26FF\uD83C-\uDBFF\uDC00-\uDFFF\s]+/u);
                el.textContent = (icon ? icon[0] : '') + ' ' + value;
            } else {
                el.textContent = value;
            }
        }
    };

    // Helper for simple text update
    const updateText = (id, value) => {
        const el = document.getElementById(id);
        if (el && value) el.textContent = value;
    };

    // --- Data Preparation ---
    // Handle legacy 'phone' vs new 'phoneNumbers'
    let phones = [];
    if (contact.phoneNumbers && Array.isArray(contact.phoneNumbers) && contact.phoneNumbers.length > 0) {
        phones = contact.phoneNumbers;
    } else if (contact.phone) {
        phones = [contact.phone];
    }
    const primaryPhone = phones.length > 0 ? phones[0] : '';

    // Handle legacy 'whatsapp' vs new 'whatsappNumbers'
    let whatsapps = [];
    if (contact.whatsappNumbers && Array.isArray(contact.whatsappNumbers) && contact.whatsappNumbers.length > 0) {
        whatsapps = contact.whatsappNumbers;
    } else if (contact.whatsapp) {
        whatsapps = [contact.whatsapp];
    }
    const primaryWa = whatsapps.length > 0 ? whatsapps[0] : '';


    // --- Global Updates (Footer & Home Hero/CTA) ---

    // Helper to handle multiple footer links (cloning LIs)
    const updateFooterList = (baseId, values, prefix, isWhatsApp = false) => {
        const baseEl = document.getElementById(baseId);
        if (!baseEl || !values || values.length === 0) return;

        // Update the first/base element
        const firstVal = values[0];
        baseEl.href = `${prefix}${firstVal}`;
        if (isWhatsApp) baseEl.target = "_blank";

        // Update text
        if (baseEl.dataset.keepIcon) {
            const text = baseEl.textContent;
            const icon = text.match(/^[\p{Emoji}\u2600-\u26FF\uD83C-\uDBFF\uDC00-\uDFFF\s]+/u);
            baseEl.textContent = (icon ? icon[0] : '') + ' ' + firstVal;
        } else {
            baseEl.textContent = firstVal;
        }

        // Handle additional numbers
        if (values.length > 1) {
            const parentLi = baseEl.closest('li');
            if (parentLi && parentLi.parentNode) {
                // Remove previously added dynamic siblings (if re-running)
                // This is tricky without a class. For now, we assume simple append flow.
                // To avoid duplicates on re-render, we could mark them.

                // We'll insert AFTER the current LI
                let lastLi = parentLi;

                for (let i = 1; i < values.length; i++) {
                    const clonedLi = parentLi.cloneNode(true);
                    const link = clonedLi.querySelector('a');
                    link.id = ''; // Remove ID to correspond to unique elements
                    link.removeAttribute('data-keep-icon'); // Clean up attributes if needed

                    const val = values[i];
                    link.href = `${prefix}${val}`;
                    if (isWhatsApp) link.target = "_blank";

                    // Fix text for cloned item
                    // Re-grab icon from original text content assumption or use default
                    const iconStr = isWhatsApp ? '💬' : '📞';
                    link.textContent = `${iconStr} ${val}`;

                    // Mark as dynamic to potentially remove later (optional, currently strictly additive)
                    clonedLi.classList.add('dynamic-contact-item');

                    // Check if already exists (prevent duplicate visual on re-runs if strict)
                    // For this simple implementation, we just insert.
                    parentLi.parentNode.insertBefore(clonedLi, lastLi.nextSibling);
                    lastLi = clonedLi;
                }
            }
        }
    };

    // Update Footer Links with Multi-Support
    updateFooterList('footer-phone-link', phones, 'tel:');
    updateFooterList('footer-whatsapp-link', whatsapps, 'https://wa.me/', true);

    // Update Email (Single)
    updateLink('footer-email-link', 'mailto:', contact.email);


    if (primaryWa) {
        // Home Hero
        const heroWa = document.getElementById('hero-btn-whatsapp');
        if (heroWa) {
            heroWa.href = `https://wa.me/${primaryWa}`;
            heroWa.target = "_blank";
        }

        // Home CTA
        const ctaWa = document.getElementById('cta-btn-whatsapp');
        if (ctaWa) {
            ctaWa.href = `https://wa.me/${primaryWa}`;
            ctaWa.target = "_blank";
        }
    }

    // Home Hero & CTA Call Buttons (Primary Only)
    updateLink('hero-btn-call', 'tel:', primaryPhone);
    updateLink('cta-btn-call', 'tel:', primaryPhone);
    updateLink('about-cta-call', 'tel:', primaryPhone);

    if (primaryWa) {
        // ... existing WA updates ...

        // About CTA
        const aboutWa = document.getElementById('about-cta-whatsapp');
        if (aboutWa) {
            aboutWa.href = `https://wa.me/${primaryWa}`;
            aboutWa.target = "_blank";
        }
    }


    // --- Contact Page Specific ---
    updateLink('contact-email-link', 'mailto:', contact.email);
    updateText('contact-email-display', contact.email);
    updateText('contact-address-display', contact.address || '');

    // Log Contact Form Email for verification
    if (contact.contactFormEmail) {
        console.log('Contact Form Email Configured:', contact.contactFormEmail);
        // Expose to window for other scripts (like contact.js)
        window.siteContactEmail = contact.contactFormEmail;
    }

    // Dynamic Phone List
    const phoneListEl = document.getElementById('contact-phone-list');
    if (phoneListEl && phones.length > 0) {
        phoneListEl.innerHTML = phones.map(num =>
            `<a href="tel:${num}" style="display:block; margin-bottom: 0.5rem; color: var(--color-primary); font-weight: 500;">${num}</a>`
        ).join('');
    }

    // Dynamic WhatsApp List
    const waListEl = document.getElementById('contact-whatsapp-list');
    if (waListEl && whatsapps.length > 0) {
        waListEl.innerHTML = whatsapps.map(num =>
            `<a href="https://wa.me/${num}" class="btn-whatsapp btn-sm" style="display:inline-flex; margin-right:0.5rem; margin-bottom:0.5rem; align-items:center gap:0.5rem;">
                <span>💬</span> ${num}
            </a>`
        ).join('');
    }
}

// Helper to safely set text content
function setText(id, text) {
    if (!text) return;
    const el = document.getElementById(id);
    if (el) {
        el.textContent = text;
    }
}

// Helper for Stats
function updateStat(id, value) {
    if (!value) return;
    const el = document.getElementById(id);
    if (el) {
        el.textContent = value;
        // Strip non-numeric for animation data attribute
        const numeric = value.replace(/\D/g, '');
        if (numeric) {
            el.setAttribute('data-target', numeric);
        }
        // Extract suffix if present (e.g. "200+")
        const suffixMatch = value.match(/\D+$/);
        const suffix = suffixMatch ? suffixMatch[0] : '';
        if (suffix) {
            el.setAttribute('data-suffix', suffix);
        }
    }
}
