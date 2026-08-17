        // Sticky header shadow
        const header = document.getElementById('site-header');
        window.addEventListener('scroll', () => {
            header.classList.toggle('is-scrolled', window.scrollY > 8);
        }, { passive: true });

        // Animated counters (trigger on scroll into view)
        function runCounter(el) {
            const target = parseInt(el.dataset.target, 10);
            const duration = 1100;
            const start = performance.now();

            function tick(now) {
                const p = Math.min((now - start) / duration, 1);
                const eased = 1 - Math.pow(1 - p, 3);
                const val = Math.round(eased * target);
                el.textContent = val.toLocaleString('en');
                if (p < 1) requestAnimationFrame(tick);
            }

            requestAnimationFrame(tick);
        }

        const counters = document.querySelectorAll('.js-counter');
        const obs = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    runCounter(entry.target);
                    obs.unobserve(entry.target);
                }
            });
        }, { threshold: 0.6 });

        counters.forEach(c => obs.observe(c));
