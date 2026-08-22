/**
 * Free Computation Foundation
 * High-Visibility Crisp White Starfield Canvas Engine
 */

(function() {
  'use strict';

  function initStarfield() {
    const canvas = document.getElementById('space-drift-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let width = 0;
    let height = 0;
    let stars = [];
    const STAR_COUNT = 350;

    function resize() {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
      stars = [];
      for (let i = 0; i < STAR_COUNT; i++) {
        stars.push({
          x: Math.random() * width,
          y: Math.random() * height,
          size: Math.random() * 2.0 + 0.8,
          speed: Math.random() * 0.4 + 0.1,
          opacity: Math.random() * 0.8 + 0.2,
          pulse: Math.random() * 0.02 + 0.01
        });
      }
    }

    function animate() {
      ctx.clearRect(0, 0, width, height);

      for (let s of stars) {
        s.y -= s.speed;
        if (s.y < 0) {
          s.y = height;
          s.x = Math.random() * width;
        }

        s.opacity += s.pulse;
        if (s.opacity > 1 || s.opacity < 0.2) {
          s.pulse = -s.pulse;
        }

        ctx.fillStyle = '#ffffff';
        ctx.globalAlpha = Math.max(0.1, Math.min(1.0, s.opacity));
        ctx.beginPath();
        ctx.arc(s.x, s.y, s.size, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.globalAlpha = 1.0;

      requestAnimationFrame(animate);
    }

    window.addEventListener('resize', resize);
    resize();
    animate();
  }

  // Copy Buttons
  function initCopyButtons() {
    document.querySelectorAll('[data-copy-text]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const text = btn.getAttribute('data-copy-text');
        if (!text) return;
        navigator.clipboard.writeText(text).then(() => {
          const original = btn.textContent;
          btn.textContent = 'COPIED';
          setTimeout(() => {
            btn.textContent = original;
          }, 1500);
        });
      });
    });
  }

  // Live Doc Search
  function initDocFilter() {
    const searchInput = document.getElementById('live-doc-filter');
    if (!searchInput) return;
    const items = document.querySelectorAll('.card, .manual-group');

    searchInput.addEventListener('input', (e) => {
      const q = e.target.value.toLowerCase().trim();
      items.forEach((item) => {
        const text = item.textContent.toLowerCase();
        item.style.display = (!q || text.includes(q)) ? '' : 'none';
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      initStarfield();
      initCopyButtons();
      initDocFilter();
    });
  } else {
    initStarfield();
    initCopyButtons();
    initDocFilter();
  }
})();
