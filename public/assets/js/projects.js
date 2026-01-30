/**
 * JS Brixen - Projects Module
 * Handles: data rendering, search/filter, sorting, pagination, carousel, lightbox, keyboard nav, analytics
 */

(function () {
    'use strict';

    // ========== DATA: PROJECTS FROM FIRESTORE ==========
    // Projects are loaded from Firestore via projects-firestore.js module
    let PROJECTS = [];

    // Listen for projects loaded from Firestore
    window.addEventListener('projectsLoaded', (event) => {
        PROJECTS = event.detail || [];
        console.log(`📦 Loaded ${PROJECTS.length} projects from Firestore`);

        // Initialize state with loaded projects
        state.allProjects = [...PROJECTS];
        state.filteredProjects = [...PROJECTS];

        // Trigger initial render
        applyFilters();
        renderProjectGrid();
    });

    // ========== STATE MANAGEMENT ==========
    let state = {
        allProjects: [...PROJECTS],
        filteredProjects: [...PROJECTS],
        visibleProjects: [],
        currentFilters: {
            types: [],
            search: '',
            sort: 'newest'
        },
        pagination: {
            initialCount: 9,
            loadMoreCount: 6,
            currentCount: 9
        },
        lightbox: {
            isOpen: false,
            images: [],
            currentIndex: 0
        },
        carousel: {
            images: [],
            currentIndex: 0,
            interval: null
        }
    };

    // ========== ANALYTICS HOOKS ==========
    // TODO: Replace with actual analytics (GTM, Firebase Analytics)
    function trackEvent(eventName, params) {
        console.log('[Analytics]', eventName, params);
    }

    // ========== UTILITY FUNCTIONS ==========
    function buildConsultationURL(slug, title) {
        const params = new URLSearchParams({
            relatedProjectId: slug,
            relatedProjectTitle: title
        });
        return `/book-consultation.html?${params.toString()}`;
    }

    function getTypeLabel(type) {
        const labels = {
            'new': 'New Construction',
            'renovation': 'Renovation',
            'interior': 'Interior'
        };
        return labels[type] || type;
    }

    function formatDate(date) {
        return new Intl.DateTimeFormat('en-IN', { year: 'numeric', month: 'long' }).format(date);
    }

    // ========== FILTERING & SORTING ==========
    function applyFilters() {
        let filtered = [...state.allProjects];

        // Filter by type
        if (state.currentFilters.types.length > 0) {
            filtered = filtered.filter(p => state.currentFilters.types.includes(p.type));
        }

        // Filter by search
        if (state.currentFilters.search) {
            const query = state.currentFilters.search.toLowerCase();
            filtered = filtered.filter(p =>
                p.title.toLowerCase().includes(query) ||
                p.district.toLowerCase().includes(query) ||
                p.summary.toLowerCase().includes(query) ||
                p.tags.some(tag => tag.toLowerCase().includes(query))
            );
        }

        // Sort
        switch (state.currentFilters.sort) {
            case 'featured':
                filtered.sort((a, b) => {
                    if (a.isFeatured && !b.isFeatured) return -1;
                    if (!a.isFeatured && b.isFeatured) return 1;
                    return a.createdAt - b.createdAt; // Oldest first
                });
                break;
            case 'newest':
                filtered.sort((a, b) => b.createdAt - a.createdAt);
                break;
            case 'oldest':
                filtered.sort((a, b) => a.createdAt - b.createdAt);
                break;
            case 'views':
                filtered.sort((a, b) => b.views - a.views);
                break;
        }

        state.filteredProjects = filtered;
        state.pagination.currentCount = state.pagination.initialCount;
        updateVisibleProjects();
    }

    function updateVisibleProjects() {
        state.visibleProjects = state.filteredProjects.slice(0, state.pagination.currentCount);
    }

    // ========== RENDERING FUNCTIONS ==========
    function renderProjectCard(project, index) {
        const consultationURL = buildConsultationURL(project.slug, project.title);
        const detailURL = `project-template.html?project=${project.slug}`;

        return `
            <article class="project-card" tabindex="0" data-slug="${project.slug}" data-index="${index}">
                <div class="project-card__image-wrapper">
                    <img 
                        src="${project.images[0].url}" 
                        alt="${project.images[0].alt}"
                        class="project-card__image"
                        loading="lazy"
                    >
                    <span class="project-card__badge project-card__badge--${project.type}">
                        ${getTypeLabel(project.type)}
                    </span>
                    <span class="project-card__photo-count">
                        📷 ${project.images.length}
                    </span>
                </div>
                <div class="project-card__content">
                    <h3 class="project-card__title">${project.title}</h3>
                    <div class="project-card__district">📍 ${project.district}</div>
                    <p class="project-card__summary">${project.summary}</p>
                    <div class="project-card__actions">
                        <a href="${consultationURL}" class="btn-primary btn-sm">Book Consultation</a>
                        <a href="${detailURL}" class="btn-secondary-outline btn-sm">View Project</a>
                    </div>
                </div>
            </article>
        `;
    }

    function renderProjectGrid() {
        const grid = document.getElementById('projects-grid');
        if (!grid) return;

        if (state.visibleProjects.length === 0) {
            grid.innerHTML = `
                <div style="grid-column: 1 / -1; text-align: center; padding: 3rem;">
                    <h3>No projects found</h3>
                    <p>Try adjusting your filters or search query.</p>
                </div>
            `;
            return;
        }

        grid.innerHTML = state.visibleProjects.map((project, index) => renderProjectCard(project, index)).join('');

        // Update results count
        const resultsCount = document.getElementById('results-count');
        if (resultsCount) {
            resultsCount.textContent = `Showing ${state.visibleProjects.length} of ${state.filteredProjects.length} projects`;
        }

        // Update load more button
        const loadMoreBtn = document.getElementById('load-more-btn');
        if (loadMoreBtn) {
            if (state.visibleProjects.length >= state.filteredProjects.length) {
                loadMoreBtn.hidden = true;
            } else {
                loadMoreBtn.hidden = false;
            }
        }

        // Add click handlers
        attachCardHandlers();

        // Track analytics
        trackEvent('project_list_view', { count: state.visibleProjects.length });

        // Mobile Carousel: Render Dots & Setup Scroll
        renderDots(state.visibleProjects.length);
        setupScrollListener();
    }

    // ========== MOBILE CAROUSEL (DOTS) ==========
    function renderDots(count) {
        const dotsContainer = document.getElementById('projects-dots');
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
        const grid = document.getElementById('projects-grid');
        const dotsContainer = document.getElementById('projects-dots');
        if (!grid || !dotsContainer) return;

        // Remove existing listener to avoid duplicates if re-rendered? 
        // Actually, re-rendering grid replaces innerHTML, but the listener is on the grid element itself.
        // It's better to ensure we don't stack listeners if possible, but for now simple add is okay 
        // as long as we don't re-call this excessively. 
        // However, renderProjectGrid IS called on filter change.
        // Let's rely on a flag or named function reference removal if needed, 
        // but for now, since filter/render replaces content, 
        // the dots will reset. The scroll listener on the GRID element (which is static in HTML) 
        // might stack. 
        // To prevent stacking, we can assign the handler to a variable or check a property.
        // Simple fix: Remove previous listener if we can, or just ignore for now as it's not heavy.
        // A better approach: The grid element is static. We only need to add the listener ONCE.
        // But the cards change width/count. 

        // Let's use a flag on the element
        if (grid.dataset.scrollListenerAttached) return;

        grid.addEventListener('scroll', () => {
            const card = grid.querySelector('.project-card');
            if (!card) return;

            const cardWidth = card.offsetWidth || 1;
            // Add gap to width if needed, but offsetWidth usually works for approx
            // Better: use scrollLeft / (cardWidth + gap)
            // But styled gap is handled by scroll-snap mostly.

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

        grid.dataset.scrollListenerAttached = 'true';
    }

    function attachCardHandlers() {
        const cards = document.querySelectorAll('.project-card');
        cards.forEach((card, index) => {
            card.addEventListener('click', (e) => {
                // Don't navigate if clicking a button/link
                if (e.target.tagName === 'A' || e.target.closest('a')) return;

                const slug = card.dataset.slug;
                const project = state.visibleProjects[index];
                trackEvent('project_card_click', { slug, title: project.title, position: index });
                window.location.href = `project-template.html?project=${slug}`;
            });

            card.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                    const slug = card.dataset.slug;
                    window.location.href = `project-template.html?project=${slug}`;
                }
            });
        });
    }

    // ========== FILTER HANDLERS ==========
    function setupFilters() {
        // Search input
        const searchInput = document.getElementById('project-search');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                state.currentFilters.search = e.target.value;
                applyFilters();
                renderProjectGrid();
            });
        }

        // Category chips
        const categoryChips = document.querySelectorAll('.filter-chip');
        categoryChips.forEach(chip => {
            chip.addEventListener('click', () => {
                const type = chip.dataset.type;

                if (type === 'all') {
                    state.currentFilters.types = [];
                    categoryChips.forEach(c => c.classList.remove('filter-chip--active'));
                    chip.classList.add('filter-chip--active');
                } else {
                    // Remove 'all' active state
                    document.querySelector('[data-type="all"]')?.classList.remove('filter-chip--active');

                    // Toggle this type
                    const index = state.currentFilters.types.indexOf(type);
                    if (index > -1) {
                        state.currentFilters.types.splice(index, 1);
                        chip.classList.remove('filter-chip--active');
                    } else {
                        state.currentFilters.types.push(type);
                        chip.classList.add('filter-chip--active');
                    }

                    // If no types selected, activate 'all'
                    if (state.currentFilters.types.length === 0) {
                        document.querySelector('[data-type="all"]')?.classList.add('filter-chip--active');
                    }
                }

                applyFilters();
                renderProjectGrid();
            });
        });

        // Sort dropdown
        const sortSelect = document.getElementById('project-sort');
        if (sortSelect) {
            sortSelect.addEventListener('change', (e) => {
                state.currentFilters.sort = e.target.value;
                applyFilters();
                renderProjectGrid();
            });
        }

        // Load more button
        const loadMoreBtn = document.getElementById('load-more-btn');
        if (loadMoreBtn) {
            loadMoreBtn.addEventListener('click', () => {
                state.pagination.currentCount += state.pagination.loadMoreCount;
                updateVisibleProjects();
                renderProjectGrid();
                trackEvent('load_more_click', { newCount: state.visibleProjects.length });
            });
        }
    }

    // ========== KEYBOARD NAVIGATION ==========
    function setupKeyboardNav() {
        document.addEventListener('keydown', (e) => {
            const cards = Array.from(document.querySelectorAll('.project-card'));
            const focusedCard = document.activeElement;
            const currentIndex = cards.indexOf(focusedCard);

            if (currentIndex === -1) return;

            let nextIndex = currentIndex;

            switch (e.key) {
                case 'ArrowRight':
                    e.preventDefault();
                    nextIndex = Math.min(currentIndex + 1, cards.length - 1);
                    break;
                case 'ArrowLeft':
                    e.preventDefault();
                    nextIndex = Math.max(currentIndex - 1, 0);
                    break;
                case 'ArrowDown':
                    e.preventDefault();
                    nextIndex = Math.min(currentIndex + 3, cards.length - 1);
                    break;
                case 'ArrowUp':
                    e.preventDefault();
                    nextIndex = Math.max(currentIndex - 3, 0);
                    break;
            }

            if (nextIndex !== currentIndex) {
                cards[nextIndex].focus();
            }
        });
    }

    // ========== LIGHTBOX ==========
    function openLightbox(images, startIndex = 0) {
        state.lightbox.images = images;
        state.lightbox.currentIndex = startIndex;
        state.lightbox.isOpen = true;

        const lightbox = document.querySelector('.lightbox');
        if (!lightbox) return;

        lightbox.hidden = false;
        updateLightboxImage();

        // Trap focus
        const focusableElements = lightbox.querySelectorAll('button');
        if (focusableElements.length > 0) {
            focusableElements[0].focus();
        }

        trackEvent('gallery_open', { imageIndex: startIndex, totalImages: images.length });
    }

    function closeLightbox() {
        const lightbox = document.querySelector('.lightbox');
        if (!lightbox) return;

        lightbox.hidden = true;
        state.lightbox.isOpen = false;

        // Return focus to trigger element
        const lastFocusedGalleryItem = document.querySelector('.gallery-item:focus');
        if (lastFocusedGalleryItem) {
            lastFocusedGalleryItem.focus();
        }
    }

    function navigateLightbox(direction) {
        const newIndex = state.lightbox.currentIndex + direction;
        if (newIndex >= 0 && newIndex < state.lightbox.images.length) {
            state.lightbox.currentIndex = newIndex;
            updateLightboxImage();
        }
    }

    function updateLightboxImage() {
        const lightbox = document.querySelector('.lightbox');
        if (!lightbox) return;

        const img = lightbox.querySelector('.lightbox__image');
        const counter = lightbox.querySelector('.lightbox__counter');
        const caption = lightbox.querySelector('.lightbox__caption');

        const currentImage = state.lightbox.images[state.lightbox.currentIndex];

        if (img) {
            img.src = currentImage.url;
            img.alt = currentImage.alt;
        }

        if (counter) {
            counter.textContent = `${state.lightbox.currentIndex + 1} / ${state.lightbox.images.length}`;
        }

        if (caption && currentImage.alt) {
            caption.textContent = currentImage.alt;
        }
    }

    function setupLightbox() {
        const lightbox = document.querySelector('.lightbox');
        if (!lightbox) return;

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
            if (!state.lightbox.isOpen) return;

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

        // Touch swipe support
        let touchStartX = 0;
        let touchEndX = 0;

        lightbox.addEventListener('touchstart', (e) => {
            touchStartX = e.changedTouches[0].screenX;
        });

        lightbox.addEventListener('touchend', (e) => {
            touchEndX = e.changedTouches[0].screenX;
            handleSwipe();
        });

        function handleSwipe() {
            const swipeThreshold = 50;
            const diff = touchStartX - touchEndX;

            if (Math.abs(diff) > swipeThreshold) {
                if (diff > 0) {
                    navigateLightbox(1); // Swipe left
                } else {
                    navigateLightbox(-1); // Swipe right
                }
            }
        }
    }

    // ========== HERO CAROUSEL ==========
    function initCarousel(images) {
        state.carousel.images = images;
        state.carousel.currentIndex = 0;

        const carousel = document.querySelector('.project-hero__carousel');
        if (!carousel) return;

        // Render slides
        carousel.innerHTML = images.map((img, index) => `
            <div class="project-hero__slide ${index === 0 ? 'project-hero__slide--active' : ''}" data-index="${index}">
                <img src="${img.url}" alt="${img.alt}" loading="${index === 0 ? 'eager' : 'lazy'}">
            </div>
        `).join('');

        // Render dots
        const dotsContainer = document.querySelector('.carousel-dots');
        if (dotsContainer) {
            dotsContainer.innerHTML = images.map((_, index) => `
                <button class="carousel-dot ${index === 0 ? 'carousel-dot--active' : ''}" data-index="${index}" aria-label="Go to slide ${index + 1}"></button>
            `).join('');

            // Dot click handlers
            dotsContainer.querySelectorAll('.carousel-dot').forEach(dot => {
                dot.addEventListener('click', () => {
                    goToSlide(parseInt(dot.dataset.index));
                });
            });
        }

        // Navigation buttons
        const prevBtn = document.querySelector('.carousel-prev');
        const nextBtn = document.querySelector('.carousel-next');

        if (prevBtn) {
            prevBtn.addEventListener('click', () => navigateCarousel(-1));
        }

        if (nextBtn) {
            nextBtn.addEventListener('click', () => navigateCarousel(1));
        }

        // Touch swipe support
        let touchStartX = 0;
        let touchEndX = 0;

        carousel.addEventListener('touchstart', (e) => {
            touchStartX = e.changedTouches[0].screenX;
        });

        carousel.addEventListener('touchend', (e) => {
            touchEndX = e.changedTouches[0].screenX;
            const diff = touchStartX - touchEndX;
            const swipeThreshold = 50;

            if (Math.abs(diff) > swipeThreshold) {
                if (diff > 0) {
                    navigateCarousel(1);
                } else {
                    navigateCarousel(-1);
                }
            }
        });

        // Auto-play (optional)
        // startAutoPlay();
    }

    function navigateCarousel(direction) {
        let newIndex = state.carousel.currentIndex + direction;

        if (newIndex < 0) {
            newIndex = state.carousel.images.length - 1;
        } else if (newIndex >= state.carousel.images.length) {
            newIndex = 0;
        }

        goToSlide(newIndex);
    }

    function goToSlide(index) {
        state.carousel.currentIndex = index;

        // Update slides
        const slides = document.querySelectorAll('.project-hero__slide');
        slides.forEach((slide, i) => {
            slide.classList.toggle('project-hero__slide--active', i === index);
        });

        // Update dots
        const dots = document.querySelectorAll('.carousel-dot');
        dots.forEach((dot, i) => {
            dot.classList.toggle('carousel-dot--active', i === index);
        });
    }

    function startAutoPlay() {
        state.carousel.interval = setInterval(() => {
            navigateCarousel(1);
        }, 5000);
    }

    function stopAutoPlay() {
        if (state.carousel.interval) {
            clearInterval(state.carousel.interval);
            state.carousel.interval = null;
        }
    }

    // ========== PROJECT DETAIL PAGE ==========
    function initProjectDetail() {
        const params = new URLSearchParams(window.location.search);
        const slug = params.get('project');

        if (!slug) {
            // Redirect to projects listing if no slug
            window.location.href = 'projects.html';
            return;
        }

        const project = PROJECTS.find(p => p.slug === slug);

        if (!project) {
            // Project not found
            window.location.href = 'projects.html';
            return;
        }

        populateProjectDetail(project);
        trackEvent('project_detail_view', { slug, title: project.title });
    }

    function populateProjectDetail(project) {
        // Update page title and meta
        document.title = `${project.title} | JS Brixen`;

        const metaDescription = document.querySelector('meta[name="description"]');
        if (metaDescription) {
            metaDescription.content = project.summary;
        }

        const ogTitle = document.querySelector('meta[property="og:title"]');
        if (ogTitle) {
            ogTitle.content = `${project.title} | JS Brixen`;
        }

        const ogDescription = document.querySelector('meta[property="og:description"]');
        if (ogDescription) {
            ogDescription.content = project.summary;
        }

        const ogImage = document.querySelector('meta[property="og:image"]');
        if (ogImage) {
            ogImage.content = project.images[0].url;
        }

        // Update JSON-LD
        const ldJson = document.getElementById('project-ld-json');
        if (ldJson) {
            const structuredData = {
                "@context": "https://schema.org",
                "@type": "CreativeWork",
                "name": project.title,
                "description": project.description,
                "image": project.images.map(img => img.url),
                "locationCreated": {
                    "@type": "Place",
                    "name": project.district
                },
                "datePublished": project.createdAt.toISOString(),
                "creator": {
                    "@type": "Organization",
                    "name": "JS Brixen"
                }
            };
            ldJson.textContent = JSON.stringify(structuredData, null, 2);
        }

        // Breadcrumb
        const breadcrumbSpan = document.getElementById('project-title-breadcrumb');
        if (breadcrumbSpan) {
            breadcrumbSpan.textContent = project.title;
        }

        // Title
        const titleElement = document.getElementById('project-title');
        if (titleElement) {
            titleElement.textContent = project.title;
        }

        // Type badge
        const typeBadge = document.getElementById('project-type');
        if (typeBadge) {
            typeBadge.textContent = getTypeLabel(project.type);
            typeBadge.className = `project-type-badge project-type-badge--${project.type}`;
        }

        // Metadata
        const districtElement = document.getElementById('project-district');
        if (districtElement) {
            districtElement.textContent = project.district;
        }

        const areaElement = document.getElementById('project-area');
        if (areaElement) {
            areaElement.textContent = project.meta.area || 'N/A';
        }

        const durationElement = document.getElementById('project-duration');
        if (durationElement) {
            durationElement.textContent = project.meta.duration || 'N/A';
        }

        const yearElement = document.getElementById('project-year');
        if (yearElement) {
            yearElement.textContent = project.meta.year || 'N/A';
        }

        // Description
        const descriptionElement = document.getElementById('project-description');
        if (descriptionElement) {
            descriptionElement.innerHTML = project.description.split('\n\n').map(p => `<p>${p}</p>`).join('');
        }

        // Gallery
        const galleryGrid = document.getElementById('gallery-grid');
        if (galleryGrid) {
            galleryGrid.innerHTML = project.images.map((img, index) => `
                <button class="gallery-item" data-index="${index}" aria-label="View image ${index + 1}">
                    <img src="${img.url}" alt="${img.alt}" loading="lazy">
                </button>
            `).join('');

            // Attach gallery click handlers
            galleryGrid.querySelectorAll('.gallery-item').forEach((item, index) => {
                item.addEventListener('click', () => {
                    openLightbox(project.images, index);
                });
            });
        }

        // Services
        const servicesList = document.getElementById('project-services-list');
        if (servicesList && project.meta.services) {
            servicesList.innerHTML = project.meta.services.map(service => `<li>${service}</li>`).join('');
        }

        // CTA buttons
        const consultationURL = buildConsultationURL(project.slug, project.title);

        const ctaBtn = document.getElementById('cta-consultation');
        if (ctaBtn) {
            ctaBtn.href = consultationURL;
            ctaBtn.addEventListener('click', () => {
                trackEvent('project_cta_click', { slug: project.slug, ctaType: 'consultation', location: 'sidebar' });
            });
        }

        const mobileCta = document.getElementById('mobile-cta-consultation');
        if (mobileCta) {
            mobileCta.href = consultationURL;
            mobileCta.addEventListener('click', () => {
                trackEvent('project_cta_click', { slug: project.slug, ctaType: 'consultation', location: 'mobile' });
            });
        }

        // Social share
        setupSocialShare(project);

        // Initialize carousel
        initCarousel(project.images);
    }

    function setupSocialShare(project) {
        const shareButtons = document.querySelectorAll('.share-btn');
        const currentURL = window.location.href;

        shareButtons.forEach(btn => {
            const action = btn.dataset.action;

            if (action === 'copy') {
                btn.addEventListener('click', async () => {
                    try {
                        await navigator.clipboard.writeText(currentURL);
                        btn.textContent = '✓ Link Copied!';
                        setTimeout(() => {
                            btn.textContent = '🔗 Copy Link';
                        }, 2000);
                        trackEvent('share_click', { slug: project.slug, method: 'copy' });
                    } catch (err) {
                        console.error('Failed to copy:', err);
                    }
                });
            } else if (action === 'whatsapp') {
                const text = `Check out this project: ${project.title}`;
                btn.href = `https://wa.me/?text=${encodeURIComponent(text + ' ' + currentURL)}`;
                btn.addEventListener('click', () => {
                    trackEvent('share_click', { slug: project.slug, method: 'whatsapp' });
                });
            } else if (action === 'twitter') {
                const text = `Check out this project: ${project.title}`;
                btn.href = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(currentURL)}`;
                btn.addEventListener('click', () => {
                    trackEvent('share_click', { slug: project.slug, method: 'twitter' });
                });
            } else if (action === 'facebook') {
                btn.href = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(currentURL)}`;
                btn.addEventListener('click', () => {
                    trackEvent('share_click', { slug: project.slug, method: 'facebook' });
                });
            }
        });
    }

    // ========== LAZY LOADING ==========
    function setupLazyLoading() {
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const img = entry.target;
                        if (img.dataset.src) {
                            img.src = img.dataset.src;
                            img.removeAttribute('data-src');
                        }
                        imageObserver.unobserve(img);
                    }
                });
            });

            // Observe images with data-src attribute
            document.querySelectorAll('img[data-src]').forEach(img => {
                imageObserver.observe(img);
            });
        }
    }

    // ========== INITIALIZATION ==========
    function initProjectsListing() {
        applyFilters();
        renderProjectGrid();
        setupFilters();
        setupKeyboardNav();
        setupLightbox();
        setupLazyLoading();
    }

    // ========== AUTO-INIT ==========
    document.addEventListener('DOMContentLoaded', () => {
        // Determine which page we're on
        const isListingPage = document.getElementById('projects-grid') !== null;
        const isDetailPage = document.getElementById('project-title') !== null;

        if (isListingPage) {
            initProjectsListing();
        } else if (isDetailPage) {
            initProjectDetail();
            setupLightbox();
            setupLazyLoading();
        }
    });

})();

