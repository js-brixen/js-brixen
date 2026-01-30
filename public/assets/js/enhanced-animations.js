// Enhanced Animations - Modern & Performant
// All functions optimized for 60fps performance

// ========================================
// Utility Functions
// ========================================

// Throttle function for performance
function throttle(func, delay) {
    let timeoutId;
    let lastRan;
    return function (...args) {
        if (!lastRan) {
            func.apply(this, args);
            lastRan = Date.now();
        } else {
            clearTimeout(timeoutId);
            timeoutId = setTimeout(() => {
                if ((Date.now() - lastRan) >= delay) {
                    func.apply(this, args);
                    lastRan = Date.now();
                }
            }, delay - (Date.now() - lastRan));
        }
    };
}

// ========================================
// 1. Enhanced Scroll Reveal with Stagger
// ========================================

function initEnhancedScrollReveal() {
    const revealElements = document.querySelectorAll('[data-reveal]');

    const observerOptions = {
        threshold: 0.15,
        rootMargin: '0px 0px -50px 0px'
    };

    const revealObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const element = entry.target;
                const revealType = element.getAttribute('data-reveal');
                const stagger = element.getAttribute('data-stagger');

                // Add appropriate reveal class
                element.classList.add(`reveal-${revealType}`);

                // Add stagger class if specified
                if (stagger) {
                    element.classList.add(`stagger-${stagger}`);
                }

                // Trigger reveal
                setTimeout(() => {
                    element.classList.add('active');
                }, 10);

                // Stop observing once revealed
                revealObserver.unobserve(element);
            }
        });
    }, observerOptions);

    revealElements.forEach(element => {
        revealObserver.observe(element);
    });
}

// ========================================
// 2. Text Animation - Split Words
// ========================================

function initTextAnimation() {
    const textElements = document.querySelectorAll('[data-text-animation]');

    textElements.forEach(element => {
        const text = element.textContent;
        const words = text.split(' ');

        // Clear original text
        element.innerHTML = '';

        // Wrap each word
        words.forEach((word, index) => {
            const span = document.createElement('span');
            span.className = 'text-split-word';
            span.textContent = word;
            span.style.animationDelay = `${index * 0.1}s`;
            element.appendChild(span);

            // Add space after each word except last
            if (index < words.length - 1) {
                element.appendChild(document.createTextNode(' '));
            }
        });
    });

    // Trigger animation when element is visible
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const words = entry.target.querySelectorAll('.text-split-word');
                words.forEach(word => word.classList.add('active'));
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });

    textElements.forEach(el => observer.observe(el));
}

// ========================================
// 3. Parallax Scroll Effect
// ========================================

function initParallax() {
    const parallaxElements = document.querySelectorAll('[data-parallax]');

    if (parallaxElements.length === 0) return;

    const handleParallax = throttle(() => {
        const scrolled = window.pageYOffset;

        parallaxElements.forEach(element => {
            const speed = parseFloat(element.getAttribute('data-parallax')) || 0.5;
            const elementTop = element.offsetTop;
            const elementHeight = element.offsetHeight;

            // Only apply parallax if element is in viewport
            if (scrolled + window.innerHeight > elementTop && scrolled < elementTop + elementHeight) {
                const yPos = -(scrolled - elementTop) * speed;
                element.style.transform = `translateY(${yPos}px)`;
            }
        });
    }, 16); // 60fps = ~16ms

    window.addEventListener('scroll', handleParallax, { passive: true });
    handleParallax(); // Initial call
}

// ========================================
// 4. Magnetic Hover Effect
// ========================================

function initMagneticEffect() {
    const magneticElements = document.querySelectorAll('[data-magnetic]');

    magneticElements.forEach(element => {
        element.addEventListener('mousemove', (e) => {
            const rect = element.getBoundingClientRect();
            const x = e.clientX - rect.left - rect.width / 2;
            const y = e.clientY - rect.top - rect.height / 2;

            const strength = parseFloat(element.getAttribute('data-magnetic')) || 0.3;
            const moveX = x * strength;
            const moveY = y * strength;

            element.style.transform = `translate(${moveX}px, ${moveY}px)`;
        });

        element.addEventListener('mouseleave', () => {
            element.style.transform = 'translate(0, 0)';
        });
    });
}

// ========================================
// 5. Card 3D Tilt Effect
// ========================================

function initCardTilt() {
    const tiltCards = document.querySelectorAll('[data-tilt]');

    tiltCards.forEach(card => {
        card.addEventListener('mousemove', (e) => {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            const centerX = rect.width / 2;
            const centerY = rect.height / 2;

            const rotateX = ((y - centerY) / centerY) * -10; // Max 10 degrees
            const rotateY = ((x - centerX) / centerX) * 10;

            card.style.setProperty('--tilt-x', `${rotateX}deg`);
            card.style.setProperty('--tilt-y', `${rotateY}deg`);
        });

        card.addEventListener('mouseleave', () => {
            card.style.setProperty('--tilt-x', '0deg');
            card.style.setProperty('--tilt-y', '0deg');
        });
    });
}

// ========================================
// 6. Image Reveal Animation
// ========================================

function initImageReveal() {
    const imageContainers = document.querySelectorAll('.image-reveal-container');

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('revealed');
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.2 });

    imageContainers.forEach(container => {
        observer.observe(container);
    });
}

// ========================================
// 7. Enhanced Statistics Counter
// ========================================

function initEnhancedStatsCounter() {
    const stats = document.querySelectorAll('.stat-number');
    let animated = false;

    const animateCounter = (element) => {
        const target = parseInt(element.getAttribute('data-target'));
        const suffix = element.getAttribute('data-suffix') || '';
        const duration = 2000;
        const step = target / (duration / 16);
        let current = 0;

        // Add bounce animation class
        element.classList.add('counting');

        const updateCounter = () => {
            current += step;
            if (current < target) {
                element.textContent = Math.floor(current) + suffix;
                requestAnimationFrame(updateCounter);
            } else {
                element.textContent = target + suffix;
            }
        };

        updateCounter();
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting && !animated) {
                animated = true;
                stats.forEach((stat, index) => {
                    setTimeout(() => {
                        animateCounter(stat);
                    }, index * 100); // Stagger each counter
                });
                observer.disconnect();
            }
        });
    }, { threshold: 0.5 });

    const statsSection = document.querySelector('.stats-section');
    if (statsSection) {
        observer.observe(statsSection);
    }
}

// ========================================
// 8. Scroll Progress Bar
// ========================================

function initScrollProgress() {
    // Create progress bar element
    const progressBar = document.createElement('div');
    progressBar.className = 'scroll-progress';
    document.body.appendChild(progressBar);

    const updateProgress = throttle(() => {
        const windowHeight = document.documentElement.scrollHeight - window.innerHeight;
        const scrolled = window.pageYOffset;
        const progress = (scrolled / windowHeight) * 100;

        progressBar.style.width = `${progress}%`;
    }, 16);

    window.addEventListener('scroll', updateProgress, { passive: true });
    updateProgress(); // Initial call
}

// ========================================
// 9. Back to Top Button
// ========================================

function initBackToTop() {
    // Create button
    const button = document.createElement('button');
    button.className = 'back-to-top';
    button.setAttribute('aria-label', 'Back to top');
    button.innerHTML = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
      <path d="M7.41 15.41L12 10.83l4.59 4.58L18 14l-6-6-6 6z"/>
    </svg>
  `;
    document.body.appendChild(button);

    // Show/hide on scroll
    const toggleButton = throttle(() => {
        if (window.pageYOffset > 300) {
            button.classList.add('visible');
        } else {
            button.classList.remove('visible');
        }
    }, 100);

    window.addEventListener('scroll', toggleButton, { passive: true });

    // Smooth scroll to top
    button.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}

// ========================================
// 10. Floating Decorative Elements
// ========================================

function createFloatingElements() {
    // Only add floating elements on desktop to avoid performance issues
    if (window.innerWidth < 1024) {
        return;
    }

    const sections = document.querySelectorAll('section');
    const shapes = ['circle', 'line'];
    const animations = ['float-animation', 'rotate-slow'];

    sections.forEach((section, index) => {
        // Only add to every other section, max 1 element
        if (index % 2 !== 0) return;

        const element = document.createElement('div');
        element.className = 'floating-element gpu-accelerate';

        // Random shape
        const shape = shapes[Math.floor(Math.random() * shapes.length)];
        element.classList.add(`shape-${shape}`);

        // Random animation
        const animation = animations[Math.floor(Math.random() * animations.length)];
        element.classList.add(animation);

        // Random position (centered area to avoid edges)
        element.style.top = `${Math.random() * 60 + 20}%`;
        element.style.left = `${Math.random() * 60 + 20}%`;

        // Random delay
        element.style.animationDelay = `${Math.random() * 3}s`;

        // Ensure section has relative positioning
        const computedPosition = window.getComputedStyle(section).position;
        if (computedPosition === 'static') {
            section.style.position = 'relative';
        }

        section.appendChild(element);
    });
}

// ========================================
// 11. Button Ripple Effect
// ========================================

function initButtonRipple() {
    const buttons = document.querySelectorAll('.btn-primary, .btn-secondary, .cta-button');

    buttons.forEach(button => {
        button.classList.add('btn-ripple');
    });
}

// ========================================
// 12. Smooth Scroll for Anchor Links
// ========================================

function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const href = this.getAttribute('href');
            if (href === '#' || !href) return;

            const target = document.querySelector(href);
            if (target) {
                e.preventDefault();
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// ========================================
// 13. Lazy Load Images Enhancement
// ========================================

function initLazyImages() {
    const images = document.querySelectorAll('img[loading="lazy"]');

    if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.classList.add('loaded');
                    imageObserver.unobserve(img);
                }
            });
        });

        images.forEach(img => imageObserver.observe(img));
    }
}

// ========================================
// Performance Monitoring
// ========================================

function checkPerformance() {
    if (window.performance && window.performance.now) {
        let lastTime = performance.now();
        let frames = 0;

        function measureFPS() {
            const currentTime = performance.now();
            frames++;

            if (currentTime >= lastTime + 1000) {
                const fps = Math.round((frames * 1000) / (currentTime - lastTime));

                // Warn if FPS drops below 50
                if (fps < 50) {
                    console.warn(`Low FPS detected: ${fps}fps. Consider reducing animations.`);
                }

                frames = 0;
                lastTime = currentTime;
            }

            requestAnimationFrame(measureFPS);
        }

        // Only in development
        if (window.location.hostname === 'localhost') {
            measureFPS();
        }
    }
}

// ========================================
// Initialize All Animations
// ========================================

function initAllAnimations() {
    // Core animations
    initEnhancedScrollReveal();
    initTextAnimation();
    initEnhancedStatsCounter();

    // Interactive effects
    initMagneticEffect();
    initCardTilt();
    initParallax();

    // UI enhancements
    // initScrollProgress(); // Removed based on user request
    initBackToTop();
    initButtonRipple();
    initSmoothScroll();

    // Visual effects
    initImageReveal();
    createFloatingElements();
    initLazyImages();

    // Performance monitoring (dev only)
    checkPerformance();
}

// ========================================
// Initialize on DOM Ready
// ========================================

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAllAnimations);
} else {
    initAllAnimations();
}

// Export for potential module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        initEnhancedScrollReveal,
        initTextAnimation,
        initMagneticEffect,
        initCardTilt,
        initParallax,
        initScrollProgress,
        initBackToTop
    };
}
