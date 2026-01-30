import { db } from './init.js';
import { doc, getDoc } from 'https://www.gstatic.com/firebasejs/11.1.0/firebase-firestore.js';

const CACHE_KEY = 'siteContent';
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

/**
 * Get site content from Firestore with caching
 */
export async function getSiteContent() {
    try {
        // Check cache first
        const cached = getCachedContent();
        if (cached) {
            console.log('[SiteContent] Using cached content');
            return cached;
        }

        console.log('[SiteContent] Fetching from Firestore...');
        const docRef = doc(db, 'siteContent', 'main');
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
            const content = docSnap.data();
            console.log('[SiteContent] Loaded content from Firestore');

            // Cache the content
            cacheContent(content);

            return content;
        } else {
            console.warn('[SiteContent] No content document found, using defaults');
            return getDefaultContent();
        }
    } catch (error) {
        console.error('[SiteContent] Error fetching content:', error);
        return getDefaultContent();
    }
}

/**
 * Load and apply site content to the current page
 */
export async function loadSiteContent() {
    const content = await getSiteContent();

    // Apply content based on current page
    applyHeroContent(content.hero);
    applyAboutContent(content.about);
    applyCtaContent(content.cta);
    applyContactContent(content.contact);
    applyHowItWorksContent(content.howItWorks);
}

/**
 * Apply hero section content
 */
function applyHeroContent(hero) {
    if (!hero) return;

    const titleEl = document.getElementById('hero-title');
    const subtextEl = document.getElementById('hero-subtext');
    const ctaEl = document.getElementById('hero-cta');

    if (titleEl && hero.title) titleEl.textContent = hero.title;
    if (subtextEl && hero.subtext) subtextEl.textContent = hero.subtext;
    if (ctaEl && hero.ctaText) ctaEl.textContent = hero.ctaText;
}

/**
 * Apply about section content
 */
function applyAboutContent(about) {
    if (!about) return;

    const storyEl = document.getElementById('about-story');
    const yearsEl = document.getElementById('stat-years');
    const projectsEl = document.getElementById('stat-projects');
    const clientsEl = document.getElementById('stat-clients');
    const teamEl = document.getElementById('stat-team');

    if (storyEl && about.story) storyEl.textContent = about.story;
    if (yearsEl && about.statsYears) yearsEl.textContent = about.statsYears;
    if (projectsEl && about.statsProjects) projectsEl.textContent = about.statsProjects;
    if (clientsEl && about.statsClients) clientsEl.textContent = about.statsClients;
    if (teamEl && about.statsTeam) teamEl.textContent = about.statsTeam;
}

/**
 * Apply CTA section content
 */
function applyCtaContent(cta) {
    if (!cta) return;

    const titleEl = document.getElementById('cta-title');
    const textEl = document.getElementById('cta-text');

    if (titleEl && cta.title) titleEl.textContent = cta.title;
    if (textEl && cta.text) textEl.textContent = cta.text;
}

/**
 * Apply contact information
 */
function applyContactContent(contact) {
    if (!contact) return;

    // Handle phone numbers (supports single number or array of numbers)
    const phoneNumbers = Array.isArray(contact.phones)
        ? contact.phones
        : contact.phone
            ? [contact.phone]
            : [];

    if (phoneNumbers.length > 0) {
        const primaryPhone = phoneNumbers[0];

        // Update all tel: links with primary phone
        document.querySelectorAll('a[href^="tel:"]').forEach(link => {
            link.href = `tel:${primaryPhone}`;

            // Update text if it displays phone number
            if (link.textContent.includes('📞')) {
                link.textContent = `📞 ${primaryPhone}`;
            } else if (link.textContent.includes('+91') || link.textContent.includes('XXXXXXXXXX')) {
                link.textContent = primaryPhone;
            }
        });

        // Update specific phone display elements
        const phoneDisplays = document.querySelectorAll('[data-phone], .phone-number');
        phoneDisplays.forEach(el => {
            el.textContent = primaryPhone;
        });
    }

    // Update all email links
    document.querySelectorAll('a[href^="mailto:"]').forEach(link => {
        if (contact.email) {
            link.href = `mailto:${contact.email}`;
            // Update text if it's an email display
            if (link.textContent.includes('📧')) {
                link.textContent = `📧 ${contact.email}`;
            } else if (link.textContent.includes('@') || link.textContent.includes('info@')) {
                link.textContent = contact.email;
            }
        }
    });

    // Update all WhatsApp links
    document.querySelectorAll('a[href*="wa.me"]').forEach(link => {
        const whatsappNumber = contact.whatsapp || (phoneNumbers.length > 0 ? phoneNumbers[0].replace(/\+/g, '') : '');
        if (whatsappNumber) {
            const message = link.href.includes('text=')
                ? link.href.split('text=')[1]
                : "Hi, I'd like to discuss a construction project";
            link.href = `https://wa.me/${whatsappNumber}?text=${message}`;
        }
    });
}

/**
 * Apply How It Works steps
 */
function applyHowItWorksContent(steps) {
    if (!steps || !Array.isArray(steps)) return;

    const containerEl = document.getElementById('how-it-works-steps');
    if (!containerEl) return;

    // Clear existing content
    containerEl.innerHTML = '';

    // Create step cards
    steps.forEach(step => {
        const stepCard = document.createElement('div');
        stepCard.className = 'how-it-works-step';
        stepCard.innerHTML = `
      <div class="step-number">${step.step}</div>
      <h3>${step.title}</h3>
      <p>${step.description}</p>
    `;
        containerEl.appendChild(stepCard);
    });
}

/**
 * Cache content in sessionStorage
 */
function cacheContent(content) {
    try {
        const cacheData = {
            content,
            timestamp: Date.now(),
        };
        sessionStorage.setItem(CACHE_KEY, JSON.stringify(cacheData));
    } catch (error) {
        console.warn('[SiteContent] Failed to cache content:', error);
    }
}

/**
 * Get cached content if valid
 */
function getCachedContent() {
    try {
        const cached = sessionStorage.getItem(CACHE_KEY);
        if (!cached) return null;

        const { content, timestamp } = JSON.parse(cached);

        // Check if cache is still valid
        if (Date.now() - timestamp < CACHE_DURATION) {
            return content;
        }

        // Cache expired
        sessionStorage.removeItem(CACHE_KEY);
        return null;
    } catch (error) {
        console.warn('[SiteContent] Failed to read cache:', error);
        return null;
    }
}

/**
 * Default content fallback
 */
function getDefaultContent() {
    return {
        hero: {
            title: 'Build Your Dream Home in Kerala & Karnataka',
            subtext: 'Turnkey construction, renovations, interiors — trusted teams across Kerala & Karnataka delivering excellence in every project.',
            ctaText: 'Book Free Consultation',
        },
        about: {
            story: 'Founded with a vision to transform the construction industry in Kerala and Karnataka, JS Construction has grown from a small team of passionate builders to a trusted name in residential and commercial construction.',
            statsYears: '10+',
            statsProjects: '200+',
            statsClients: '500+',
            statsTeam: '50+',
        },
        howItWorks: [
            {
                step: '1',
                title: 'Book Consultation',
                description: 'Schedule a free consultation with our experts to discuss your project requirements and vision.',
            },
            {
                step: '2',
                title: 'Get Quote',
                description: 'Receive a detailed, transparent quote with no hidden costs.',
            },
            {
                step: '3',
                title: 'Start Building',
                description: 'Our experienced team begins construction with regular updates and quality checks.',
            },
        ],
        cta: {
            title: 'Ready to Start Your Project?',
            text: 'Book a free consultation with our construction experts today.',
        },
        contact: {
            phone: '+91XXXXXXXXXX',
            phones: ['+91XXXXXXXXXX'], // Array support for multiple numbers
            email: 'info@jsconstruction.com',
            whatsapp: '91XXXXXXXXXX',
        },
    };
}
