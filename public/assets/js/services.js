/**
 * JS Brixen - Services Module
 * Handles: data rendering, search/filter, keyboard nav, lightbox, analytics
 */

(function () {
    'use strict';

    // ========== DATA: SERVICES FROM FIRESTORE ==========
    // Services are loaded from Firestore via services-firestore.js
    let SERVICES = [];

    // Make SERVICES available globally for service-template.html
    window.SERVICES = SERVICES;

    // ========== INITIALIZATION ==========
    document.addEventListener('DOMContentLoaded', init);

    // Listen for services loaded from Firestore
    window.addEventListener('servicesLoaded', (event) => {
        SERVICES = event.detail || [];
        window.SERVICES = SERVICES;
        console.log('[Services] Loaded', SERVICES.length, 'services from Firestore');

        // Re-render if on services listing page
        if (document.getElementById('services-grid')) {
            renderCards(SERVICES);
        }
    });

    function init() {
        if (document.getElementById('services-grid')) {
            initServicesListing();
        }

        // Service Detail Page Initialization
        if (document.querySelector('.service-hero')) {
            // If services are already loaded, init immediately
            if (SERVICES.length > 0) {
                initServiceDetail();
            } else {
                // Otherwise wait for the event
                console.log('[Services] Waiting for data to initialize detail page...');
                window.addEventListener('servicesLoaded', () => {
                    initServiceDetail();
                }, { once: true });
            }
        }

        initLightbox();
        initAccordion();
    }

    // ========== SERVICES LISTING ==========
    function initServicesListing() {
        renderCards(SERVICES);
        setupSearch();
        setupTagFilters();
        setupKeyboardNav();
        // setupCTAAnalytics(); // TODO: Implement this function if needed
    }

    // ========== RENDERING ==========
    function renderCards(services) {
        const grid = document.getElementById('services-grid');
        if (!grid) return;

        grid.innerHTML = services.map(service => createCardHTML(service)).join('');
        updateResultsCount(services.length);

        // Render dots for mobile
        renderDots(services.length);
        setupScrollListener();
    }

    // ========== MOBILE DOTS ==========
    function renderDots(count) {
        const dotsContainer = document.getElementById('services-dots');
        if (!dotsContainer) return;

        // Hide if empty or only 1 item
        if (count <= 1) {
            dotsContainer.innerHTML = '';
            return;
        }

        dotsContainer.innerHTML = Array(count).fill(0).map((_, i) =>
            `<div class="dot ${i === 0 ? 'dot--active' : ''}" data-index="${i}"></div>`
        ).join('');
    }

    function setupScrollListener() {
        const grid = document.getElementById('services-grid');
        const dotsContainer = document.getElementById('services-dots');
        if (!grid || !dotsContainer) return;

        grid.addEventListener('scroll', () => {
            const cardWidth = grid.querySelector('.service-card')?.offsetWidth || 1;
            const scrollLeft = grid.scrollLeft;
            const activeIndex = Math.round(scrollLeft / cardWidth);

            const dots = dotsContainer.querySelectorAll('.dot');
            dots.forEach((dot, index) => {
                if (index === activeIndex) {
                    dot.classList.add('dot--active');
                } else {
                    dot.classList.remove('dot--active');
                }
            });
        }, { passive: true });
    }

    function createCardHTML(service) {
        // Simplified Card Style (Matching Featured Projects)
        // Entire card is clickable -> goes to Details page
        const detailURL = `service-template.html?service=${service.slug}`;

        // Get the primary category/tag for the label
        // If 'tags' is an array, take the first one, otherwise 'Service'
        const categoryLabel = (service.tags && service.tags.length > 0) ? service.tags[0] : 'Service';

        return `
      <div class="service-card" 
           onclick="window.location.href='${detailURL}';" 
           title="View details for ${service.title}"
           data-slug="${service.slug}"
           data-tags="${(service.tags || []).join(',').toLowerCase()}"
           data-searchtext="${(service.title || '').toLowerCase()} ${(service.shortDescription || '').toLowerCase()}">
           
        <img src="${service.images[0]}" 
             alt="${service.title}" 
             class="service-card__image"
             loading="lazy">
             
        <div class="service-card__overlay">
          <span class="service-card__tag">${categoryLabel}</span>
          <h3 class="service-card__title">${service.title}</h3>
        </div>
      </div>
    `;
    }

    // ========== SEARCH & FILTER ==========
    function setupSearch() {
        const searchInput = document.getElementById('service-search');
        if (!searchInput) return;

        const debouncedFilter = debounce(() => {
            applyFilters();
        }, 300);

        searchInput.addEventListener('input', debouncedFilter);
    }

    function setupTagFilters() {
        const tagButtons = document.querySelectorAll('.filter-tag');
        tagButtons.forEach(button => {
            button.addEventListener('click', function () {
                // Remove active from all
                tagButtons.forEach(btn => btn.classList.remove('filter-tag--active'));
                // Add active to clicked
                this.classList.add('filter-tag--active');
                applyFilters();
            });
        });
    }

    function applyFilters() {
        const searchInput = document.getElementById('service-search');
        const searchTerm = searchInput ? searchInput.value.trim().toLowerCase() : '';
        const activeTag = document.querySelector('.filter-tag--active')?.dataset.tag || 'all';

        const cards = document.querySelectorAll('.service-card');
        let visibleCount = 0;

        cards.forEach(card => {
            const searchText = card.dataset.searchtext || '';
            const cardTags = card.dataset.tags || '';

            const matchesSearch = !searchTerm || searchText.includes(searchTerm);
            const matchesTag = activeTag === 'all' || cardTags.includes(activeTag.toLowerCase());

            if (matchesSearch && matchesTag) {
                card.style.display = '';
                card.removeAttribute('hidden');
                visibleCount++;
            } else {
                card.style.display = 'none';
                card.setAttribute('hidden', '');
            }
        });

        updateResultsCount(visibleCount);
    }

    function updateResultsCount(count) {
        const resultsEl = document.getElementById('results-count');
        if (resultsEl) {
            resultsEl.textContent = `Showing ${count} service${count !== 1 ? 's' : ''} `;
        }
    }

    // ========== KEYBOARD NAVIGATION ==========
    function setupKeyboardNav() {
        const grid = document.getElementById('services-grid');
        if (!grid) return;

        grid.addEventListener('keydown', (e) => {
            const cards = [...grid.querySelectorAll('.service-card:not([hidden])')];
            const currentIndex = cards.indexOf(document.activeElement);

            if (currentIndex === -1) return;

            let nextIndex = currentIndex;
            const cols = getGridColumns();

            switch (e.key) {
                case 'ArrowRight':
                    nextIndex = Math.min(currentIndex + 1, cards.length - 1);
                    break;
                case 'ArrowLeft':
                    nextIndex = Math.max(currentIndex - 1, 0);
                    break;
                case 'ArrowDown':
                    nextIndex = Math.min(currentIndex + cols, cards.length - 1);
                    break;
                case 'ArrowUp':
                    nextIndex = Math.max(currentIndex - cols, 0);
                    break;
                case 'Enter':
                    const slug = document.activeElement.dataset.slug;
                    window.location.href = `/ service - template.html ? service = ${slug} `;
                    return;
                default:
                    return;
            }

            e.preventDefault();
            cards[nextIndex].focus();
        });
    }

    function getGridColumns() {
        const width = window.innerWidth;
        if (width >= 1440) return 4;
        if (width >= 1024) return 3;
        if (width >= 768) return 2;
        return 1;
    }

    // ========== LIGHTBOX ==========
    function initLightbox() {
        const lightbox = document.querySelector('.lightbox');
        if (!lightbox) return;

        let currentImages = [];
        let currentIndex = 0;
        let previousFocus = null;

        // Gallery item clicks
        document.addEventListener('click', (e) => {
            const galleryItem = e.target.closest('.gallery-item');
            if (galleryItem) {
                e.preventDefault();
                const gallery = galleryItem.closest('.gallery-grid');
                const items = [...gallery.querySelectorAll('.gallery-item img')];
                currentImages = items.map(img => ({
                    src: img.src,
                    alt: img.alt
                }));
                currentIndex = items.indexOf(galleryItem.querySelector('img'));
                openLightbox();
            }
        });

        // Close button
        const closeBtn = lightbox.querySelector('.lightbox__close');
        if (closeBtn) {
            closeBtn.addEventListener('click', closeLightbox);
        }

        // Navigation buttons
        const prevBtn = lightbox.querySelector('.lightbox__prev');
        const nextBtn = lightbox.querySelector('.lightbox__next');

        if (prevBtn) {
            prevBtn.addEventListener('click', () => navigateLightbox(-1));
        }
        if (nextBtn) {
            nextBtn.addEventListener('click', () => navigateLightbox(1));
        }

        // Backdrop click
        const backdrop = lightbox.querySelector('.lightbox__backdrop');
        if (backdrop) {
            backdrop.addEventListener('click', closeLightbox);
        }

        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (lightbox.hasAttribute('hidden')) return;

            switch (e.key) {
                case 'Escape':
                    closeLightbox();
                    break;
                case 'ArrowLeft':
                    navigateLightbox(-1);
                    break;
                case 'ArrowRight':
                    navigateLightbox(1);
                    break;
            }
        });

        function openLightbox() {
            previousFocus = document.activeElement;
            lightbox.removeAttribute('hidden');
            updateLightboxImage();
            trapFocus(lightbox);
            document.body.style.overflow = 'hidden';
        }

        function closeLightbox() {
            lightbox.setAttribute('hidden', '');
            document.body.style.overflow = '';
            if (previousFocus) {
                previousFocus.focus();
            }
        }

        function navigateLightbox(direction) {
            currentIndex = (currentIndex + direction + currentImages.length) % currentImages.length;
            updateLightboxImage();
        }

        function updateLightboxImage() {
            const img = lightbox.querySelector('.lightbox__image');
            const counter = lightbox.querySelector('.lightbox__counter');

            if (img && currentImages[currentIndex]) {
                img.src = currentImages[currentIndex].src;
                img.alt = currentImages[currentIndex].alt;
            }

            if (counter) {
                counter.textContent = `${currentIndex + 1} / ${currentImages.length}`;
            }
        }
    }

    function trapFocus(element) {
        const focusableSelectors = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';
        const focusables = element.querySelectorAll(focusableSelectors);
        const firstFocusable = focusables[0];
        const lastFocusable = focusables[focusables.length - 1];

        const handleTabKey = (e) => {
            if (e.key !== 'Tab') return;

            if (e.shiftKey && document.activeElement === firstFocusable) {
                e.preventDefault();
                lastFocusable.focus();
            } else if (!e.shiftKey && document.activeElement === lastFocusable) {
                e.preventDefault();
                firstFocusable.focus();
            }
        };

        element.addEventListener('keydown', handleTabKey);
        firstFocusable.focus();
    }

    // ========== ACCORDION ==========
    function initAccordion() {
        const triggers = document.querySelectorAll('.accordion-trigger');

        triggers.forEach(trigger => {
            trigger.addEventListener('click', function () {
                const panel = this.parentElement.nextElementSibling;
                const isExpanded = this.getAttribute('aria-expanded') === 'true';

                // Close all other panels (optional - remove for multi-open)
                triggers.forEach(t => {
                    if (t !== this) {
                        t.setAttribute('aria-expanded', 'false');
                        t.parentElement.nextElementSibling.setAttribute('hidden', '');
                    }
                });

                // Toggle current panel
                this.setAttribute('aria-expanded', !isExpanded);
                if (isExpanded) {
                    panel.setAttribute('hidden', '');
                } else {
                    panel.removeAttribute('hidden');
                }
            });
        });
    }

    // ========== ANALYTICS HOOK ==========
    function trackCTAClick(serviceSlug, action) {
        console.log('[Analytics]', {
            event: 'cta_click',
            service: serviceSlug,
            action: action,
            timestamp: new Date().toISOString()
        });

        // ===== ANALYTICS INTEGRATION POINT =====
        // Replace with real analytics:
        // gtag('event', 'cta_click', { service: serviceSlug, action: action });
        // or
        // analytics.track('CTA Click', { service: serviceSlug, action: action });
    }

    window.trackCTAClick = trackCTAClick;

    // ========== SERVICE DETAIL PAGE ==========
    function initServiceDetail() {
        const params = new URLSearchParams(window.location.search);
        const serviceSlug = params.get('service');

        if (!serviceSlug) {
            window.location.href = '/services.html';
            return;
        }

        const serviceData = SERVICES.find(s => s.slug === serviceSlug);

        if (!serviceData) {
            window.location.href = '/services.html';
            return;
        }

        populateServicePage(serviceData);
    }

    function populateServicePage(service) {
        // Update page title and meta
        document.title = service.seo.metaTitle;

        const metaDesc = document.querySelector('meta[name="description"]');
        if (metaDesc) {
            metaDesc.setAttribute('content', service.seo.metaDescription);
        }

        // Update Open Graph
        const ogTitle = document.querySelector('meta[property="og:title"]');
        if (ogTitle) ogTitle.setAttribute('content', service.title + ' | JS Brixen');

        const ogDesc = document.querySelector('meta[property="og:description"]');
        if (ogDesc) ogDesc.setAttribute('content', service.shortDescription);

        const ogImage = document.querySelector('meta[property="og:image"]');
        if (ogImage) ogImage.setAttribute('content', service.images[0]);

        // Update breadcrumb
        const breadcrumbCurrent = document.querySelector('.breadcrumb span[aria-current]');
        if (breadcrumbCurrent) {
            breadcrumbCurrent.textContent = service.title;
        }

        // Update hero section
        const heroImage = document.querySelector('.service-hero__background img');
        if (heroImage) {
            heroImage.src = service.images[0];
            heroImage.alt = service.title;
        }

        const heroTitle = document.querySelector('.service-hero__title');
        if (heroTitle) heroTitle.textContent = service.title;

        // Use Short Description for Hero Summary
        const heroSummary = document.querySelector('.service-hero__summary');
        if (heroSummary) heroSummary.textContent = service.shortDescription;

        // Update Full Description (Service Overview)
        const fullDescContainer = document.querySelector('.service-description');
        if (fullDescContainer) {
            // Check if it has HTML or just text. If simple text, wrap in <p>
            if (service.fullDescription.includes('<')) {
                fullDescContainer.innerHTML = service.fullDescription;
            } else {
                fullDescContainer.innerHTML = `<p>${service.fullDescription}</p>`;
            }
        }

        // Update Areas Served
        const areasContainer = document.querySelector('.service-areas-list');
        if (areasContainer && service.areaServed) {
            areasContainer.innerHTML = service.areaServed.map(area =>
                `<span class="tag tag--outdoor" style="font-size: 0.9rem; padding: 0.5rem 1rem;">${area}</span>`
            ).join('');
        }

        // Update CTA links
        const ctaLinks = document.querySelectorAll('.service-hero__cta a, .service-cta a');
        ctaLinks.forEach(link => {
            const href = link.getAttribute('href');
            if (href && href.includes('book-consultation.html')) {
                link.setAttribute('href', `/book-consultation.html?service=${service.slug}&serviceTitle=${encodeURIComponent(service.title)}`);
            }
        });

        // Populate features
        const featuresList = document.querySelector('.features-list');
        if (featuresList && service.features) {
            featuresList.innerHTML = service.features.map(feature => `
        <li class="feature-item">
          <span class="feature-icon">✓</span>
          <span class="feature-text">${feature}</span>
        </li>
      `).join('');
        }

        // Populate gallery
        const galleryGrid = document.querySelector('.gallery-grid');
        if (galleryGrid && service.images) {
            galleryGrid.innerHTML = service.images.map((img, index) => `
        <button class="gallery-item" data-index="${index}" aria-label="View image ${index + 1} of ${service.images.length}">
          <img src="${img}" alt="${service.title} - Image ${index + 1}" loading="lazy">
        </button>
      `).join('');
        }

        // Update JSON-LD
        const ldScript = document.getElementById('service-ld-json');
        if (ldScript) {
            ldScript.textContent = JSON.stringify({
                "@context": "https://schema.org",
                "@type": "Service",
                "name": service.title,
                "description": service.fullDescription,
                "provider": {
                    "@type": "Organization",
                    "name": "JS Brixen",
                    "url": "https://jsconstruction.com"
                },
                "areaServed": service.areaServed.map(area => ({
                    "@type": "State",
                    "name": area
                })),
                "image": service.images[0]
            });
        }

        // SHOW CONTENT / HIDE LOADER
        const loader = document.getElementById('service-loader');
        const content = document.getElementById('service-dynamic-content');
        if (loader) loader.style.display = 'none';
        if (content) content.removeAttribute('hidden');
    }

    // ========== UTILITIES ==========
    function debounce(fn, delay) {
        let timeoutId;
        return function (...args) {
            clearTimeout(timeoutId);
            timeoutId = setTimeout(() => fn.apply(this, args), delay);
        };
    }

})();

