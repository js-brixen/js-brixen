/**
 * JS Brixen - Main JavaScript
 * Handles mobile navigation, sticky header, and smooth scrolling
 */

(function () {
    'use strict';

    // Wait for DOM to be ready
    document.addEventListener('DOMContentLoaded', init);

    function init() {
        setupMobileNavigation();
        setupStickyHeader();
        setupSmoothScroll();
    }

    /**
     * Mobile Navigation Toggle
     */
    function setupMobileNavigation() {
        const navToggle = document.querySelector('.nav-toggle');
        const nav = document.querySelector('.nav');

        if (!navToggle || !nav) return;

        // Toggle navigation on button click
        navToggle.addEventListener('click', function () {
            const isOpen = nav.classList.contains('nav--open');

            if (isOpen) {
                closeNav();
            } else {
                openNav();
            }
        });

        // Close nav when clicking on a link (except account toggle)
        const navLinks = nav.querySelectorAll('.nav__link:not(.nav__account-toggle)');
        navLinks.forEach(link => {
            link.addEventListener('click', closeNav);
        });

        // Close nav when clicking outside
        document.addEventListener('click', function (e) {
            if (!nav.contains(e.target) && !navToggle.contains(e.target)) {
                closeNav();
            }
        });

        function openNav() {
            nav.classList.add('nav--open');
            navToggle.setAttribute('aria-expanded', 'true');
            navToggle.setAttribute('aria-label', 'Close navigation');
        }

        function closeNav() {
            nav.classList.remove('nav--open');
            navToggle.setAttribute('aria-expanded', 'false');
            navToggle.setAttribute('aria-label', 'Open navigation');
        }
    }

    /**
     * Sticky Header with Shadow on Scroll
     */
    function setupStickyHeader() {
        const header = document.querySelector('.header');

        if (!header) return;

        let lastScrollY = window.scrollY;
        let ticking = false;

        window.addEventListener('scroll', function () {
            lastScrollY = window.scrollY;

            if (!ticking) {
                window.requestAnimationFrame(function () {
                    updateHeader(lastScrollY);
                    ticking = false;
                });

                ticking = true;
            }
        });

        function updateHeader(scrollY) {
            if (scrollY > 100) {
                header.classList.add('header--sticky');
            } else {
                header.classList.remove('header--sticky');
            }
        }
    }

    /**
     * Smooth Scroll for Anchor Links
     */
    function setupSmoothScroll() {
        // Handle all anchor links
        document.querySelectorAll('a[href*="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                const href = this.getAttribute('href');

                // Check if it's a same-page anchor
                if (href.includes('#')) {
                    const parts = href.split('#');
                    const targetId = parts[1];

                    // If no page part or same page
                    if (!parts[0] || parts[0] === window.location.pathname || parts[0] === '') {
                        const targetElement = document.getElementById(targetId);

                        if (targetElement) {
                            e.preventDefault();

                            targetElement.scrollIntoView({
                                behavior: 'smooth',
                                block: 'start'
                            });

                            // Update URL without jumping
                            if (history.pushState) {
                                history.pushState(null, null, '#' + targetId);
                            }
                        }
                    }
                    // For cross-page anchors, let the browser handle navigation
                }
            });
        });

        // Scroll to anchor on page load if present in URL
        if (window.location.hash) {
            setTimeout(function () {
                const targetElement = document.getElementById(window.location.hash.substring(1));
                if (targetElement) {
                    targetElement.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            }, 100);
        }
    }

})();

