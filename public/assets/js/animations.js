// Scroll Reveal Animations
function initScrollReveal() {
    const reveals = document.querySelectorAll('.reveal');

    const revealOnScroll = () => {
        reveals.forEach(element => {
            const elementTop = element.getBoundingClientRect().top;
            const windowHeight = window.innerHeight;
            const revealPoint = 100;

            if (elementTop < windowHeight - revealPoint) {
                element.classList.add('active');
            }
        });
    };

    window.addEventListener('scroll', revealOnScroll);
    revealOnScroll(); // Initial check
}

// Statistics Counter Animation
function initStatsCounter() {
    const stats = document.querySelectorAll('.stat-number');
    let animated = false;

    const animateCounter = (element) => {
        const target = parseInt(element.getAttribute('data-target'));
        const duration = 2000; // 2 seconds
        const step = target / (duration / 16); // 60fps
        let current = 0;

        const updateCounter = () => {
            current += step;
            if (current < target) {
                element.textContent = Math.floor(current) + (element.getAttribute('data-suffix') || '');
                requestAnimationFrame(updateCounter);
            } else {
                element.textContent = target + (element.getAttribute('data-suffix') || '');
            }
        };

        updateCounter();
    };

    const checkStatsVisibility = () => {
        if (animated) return;

        const statsSection = document.querySelector('.stats-section');
        if (!statsSection) return;

        const sectionTop = statsSection.getBoundingClientRect().top;
        const windowHeight = window.innerHeight;

        if (sectionTop < windowHeight * 0.8) {
            animated = true;
            stats.forEach(stat => animateCounter(stat));
        }
    };

    window.addEventListener('scroll', checkStatsVisibility);
    checkStatsVisibility(); // Initial check
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    initScrollReveal();
    initStatsCounter();
});
