/**
 * Free Computation Foundation — Advanced Scientific Research Laboratory
 * 3D Cosmic Space Drift Engine & Interactive Telemetry
 * Version: CentL26.10
 */

(function() {
  'use strict';

  // 1. Multi-Layered 3D Space Drift Starfield & Nebula Animation
  function initSpaceDrift() {
    let canvas = document.getElementById('space-drift-canvas');
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'space-drift-canvas';
      document.body.prepend(canvas);
    }
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    const STAR_COUNT = Math.min(Math.floor((width * height) / 4000), 380);
    const SPEED = 0.45;
    const stars = [];
    const nebulas = [];
    let mouse = { x: width / 2, y: height / 2, targetX: width / 2, targetY: height / 2 };

    // Initialize 3D Stars
    for (let i = 0; i < STAR_COUNT; i++) {
      stars.push({
        x: (Math.random() - 0.5) * width * 2,
        y: (Math.random() - 0.5) * height * 2,
        z: Math.random() * 1000 + 1,
        origZ: 1000,
        size: Math.random() * 1.5 + 0.5,
        twinkleSpeed: Math.random() * 0.03 + 0.01,
        twinklePhase: Math.random() * Math.PI * 2,
        hue: Math.random() > 0.4 ? (Math.random() > 0.5 ? 195 : 220) : (Math.random() > 0.5 ? 160 : 270) // Cyan, Azure, Emerald, Violet
      });
    }

    // Initialize Cosmic Nebula Clouds
    for (let i = 0; i < 4; i++) {
      nebulas.push({
        x: Math.random() * width,
        y: Math.random() * height,
        radius: Math.random() * 260 + 180,
        vx: (Math.random() - 0.5) * 0.15,
        vy: (Math.random() - 0.5) * 0.15,
        color: i % 2 === 0 ? 'rgba(14, 165, 233, 0.035)' : 'rgba(99, 102, 241, 0.03)'
      });
    }

    // Shooting Star Manager
    let shootingStar = null;
    function spawnShootingStar() {
      if (shootingStar || Math.random() > 0.015) return;
      shootingStar = {
        x: Math.random() * width * 0.8,
        y: Math.random() * height * 0.4,
        length: Math.random() * 120 + 80,
        speed: Math.random() * 10 + 12,
        angle: Math.PI / 4 + (Math.random() - 0.5) * 0.2,
        opacity: 1,
        decay: Math.random() * 0.025 + 0.018
      };
    }

    function render() {
      ctx.clearRect(0, 0, width, height);

      // 1. Draw Nebula Clouds
      for (let n of nebulas) {
        n.x += n.vx;
        n.y += n.vy;
        if (n.x < -n.radius) n.x = width + n.radius;
        if (n.x > width + n.radius) n.x = -n.radius;
        if (n.y < -n.radius) n.y = height + n.radius;
        if (n.y > height + n.radius) n.y = -n.radius;

        const grad = ctx.createRadialGradient(n.x, n.y, 0, n.x, n.y, n.radius);
        grad.addColorStop(0, n.color);
        grad.addColorStop(1, 'transparent');
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.arc(n.x, n.y, n.radius, 0, Math.PI * 2);
        ctx.fill();
      }

      // Smooth mouse parallax interpolation
      mouse.x += (mouse.targetX - mouse.x) * 0.05;
      mouse.y += (mouse.targetY - mouse.y) * 0.05;
      const offsetX = (mouse.x - width / 2) * 0.08;
      const offsetY = (mouse.y - height / 2) * 0.08;

      const cx = width / 2 + offsetX;
      const cy = height / 2 + offsetY;

      // 2. Draw 3D Drifting Starfield
      for (let s of stars) {
        s.z -= SPEED;
        if (s.z <= 0) {
          s.z = 1000;
          s.x = (Math.random() - 0.5) * width * 2;
          s.y = (Math.random() - 0.5) * height * 2;
        }

        const k = 400 / s.z;
        const px = s.x * k + cx;
        const py = s.y * k + cy;

        if (px >= -20 && px <= width + 20 && py >= -20 && py <= height + 20) {
          s.twinklePhase += s.twinkleSpeed;
          const twinkle = (Math.sin(s.twinklePhase) + 1) * 0.25 + 0.5;
          const alpha = (1 - s.z / 1000) * twinkle;
          const radius = Math.max(s.size * k * 0.4, 0.6);

          ctx.beginPath();
          ctx.arc(px, py, radius, 0, Math.PI * 2);
          ctx.fillStyle = `hsla(${s.hue}, 85%, 75%, ${alpha})`;
          if (radius > 1.2) {
            ctx.shadowBlur = 6;
            ctx.shadowColor = `hsla(${s.hue}, 100%, 70%, ${alpha})`;
          }
          ctx.fill();
          ctx.shadowBlur = 0;
        }
      }

      // 3. Draw Shooting Star
      spawnShootingStar();
      if (shootingStar) {
        const sx = shootingStar.x;
        const sy = shootingStar.y;
        const ex = sx - Math.cos(shootingStar.angle) * shootingStar.length;
        const ey = sy - Math.sin(shootingStar.angle) * shootingStar.length;

        const grad = ctx.createLinearGradient(sx, sy, ex, ey);
        grad.addColorStop(0, `rgba(255, 255, 255, ${shootingStar.opacity})`);
        grad.addColorStop(0.3, `rgba(56, 189, 248, ${shootingStar.opacity * 0.8})`);
        grad.addColorStop(1, 'transparent');

        ctx.beginPath();
        ctx.moveTo(sx, sy);
        ctx.lineTo(ex, ey);
        ctx.strokeStyle = grad;
        ctx.lineWidth = 1.8;
        ctx.stroke();

        shootingStar.x += Math.cos(shootingStar.angle) * shootingStar.speed;
        shootingStar.y += Math.sin(shootingStar.angle) * shootingStar.speed;
        shootingStar.opacity -= shootingStar.decay;

        if (shootingStar.opacity <= 0 || shootingStar.x > width + 100 || shootingStar.y > height + 100) {
          shootingStar = null;
        }
      }

      requestAnimationFrame(render);
    }

    window.addEventListener('resize', () => {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    });

    window.addEventListener('mousemove', (e) => {
      mouse.targetX = e.clientX;
      mouse.targetY = e.clientY;
    });

    render();
  }

  // 2. Quantum Particle Lattice in Hero Container
  function initQuantumHeroCanvas() {
    const canvas = document.getElementById('quantum-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let width = (canvas.width = canvas.offsetWidth);
    let height = (canvas.height = canvas.offsetHeight);

    const particles = [];
    const count = Math.min(Math.floor((width * height) / 9000), 70);
    let mouse = { x: null, y: null, maxDist: 140 };

    class NodeParticle {
      constructor() {
        this.x = Math.random() * width;
        this.y = Math.random() * height;
        this.vx = (Math.random() - 0.5) * 0.55;
        this.vy = (Math.random() - 0.5) * 0.55;
        this.radius = Math.random() * 1.5 + 1;
        this.color = Math.random() > 0.3 ? 'rgba(56, 189, 248, 0.7)' : 'rgba(16, 185, 129, 0.6)';
      }
      update() {
        this.x += this.vx;
        this.y += this.vy;
        if (this.x < 0 || this.x > width) this.vx *= -1;
        if (this.y < 0 || this.y > height) this.vy *= -1;
      }
      draw() {
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
        ctx.fillStyle = this.color;
        ctx.shadowBlur = 8;
        ctx.shadowColor = '#00f0ff';
        ctx.fill();
        ctx.shadowBlur = 0;
      }
    }

    for (let i = 0; i < count; i++) {
      particles.push(new NodeParticle());
    }

    function animate() {
      ctx.clearRect(0, 0, width, height);

      // Connecting filaments
      for (let a = 0; a < particles.length; a++) {
        for (let b = a + 1; b < particles.length; b++) {
          const dx = particles[a].x - particles[b].x;
          const dy = particles[a].y - particles[b].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < 110) {
            const alpha = (1 - dist / 110) * 0.28;
            ctx.beginPath();
            ctx.moveTo(particles[a].x, particles[a].y);
            ctx.lineTo(particles[b].x, particles[b].y);
            ctx.strokeStyle = `rgba(56, 189, 248, ${alpha})`;
            ctx.lineWidth = 0.75;
            ctx.stroke();
          }
        }
      }

      // Mouse interactive filaments
      if (mouse.x !== null && mouse.y !== null) {
        for (let i = 0; i < particles.length; i++) {
          const dx = mouse.x - particles[i].x;
          const dy = mouse.y - particles[i].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < mouse.maxDist) {
            const alpha = (1 - dist / mouse.maxDist) * 0.45;
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(mouse.x, mouse.y);
            ctx.strokeStyle = `rgba(0, 240, 255, ${alpha})`;
            ctx.lineWidth = 1;
            ctx.stroke();
          }
        }
      }

      for (let p of particles) {
        p.update();
        p.draw();
      }

      requestAnimationFrame(animate);
    }

    window.addEventListener('resize', () => {
      width = canvas.width = canvas.offsetWidth;
      height = canvas.height = canvas.offsetHeight;
    });

    canvas.addEventListener('mousemove', (e) => {
      const rect = canvas.getBoundingClientRect();
      mouse.x = e.clientX - rect.left;
      mouse.y = e.clientY - rect.top;
    });

    canvas.addEventListener('mouseleave', () => {
      mouse.x = null;
      mouse.y = null;
    });

    animate();
  }

  // 3. One-Click Copy Buttons with Smooth Tooltip Feedback
  function initCopyButtons() {
    document.querySelectorAll('[data-copy-text]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const text = btn.getAttribute('data-copy-text');
        if (!text) return;
        navigator.clipboard.writeText(text).then(() => {
          const original = btn.textContent;
          btn.textContent = 'COPIED';
          btn.classList.add('is-copied');
          setTimeout(() => {
            btn.textContent = original;
            btn.classList.remove('is-copied');
          }, 1800);
        });
      });
    });
  }

  // 4. Live Search Filter for Documents & Preprints
  function initDocSearchFilter() {
    const searchInput = document.getElementById('live-doc-filter');
    if (!searchInput) return;
    const cards = document.querySelectorAll('.topic-card, .manual-group, .compact-card');

    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase().trim();
      cards.forEach((card) => {
        const text = card.textContent.toLowerCase();
        if (!query || text.includes(query)) {
          card.style.display = '';
        } else {
          card.style.display = 'none';
        }
      });
    });
  }

  // Initialize all subsystems
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      initSpaceDrift();
      initQuantumHeroCanvas();
      initCopyButtons();
      initDocSearchFilter();
    });
  } else {
    initSpaceDrift();
    initQuantumHeroCanvas();
    initCopyButtons();
    initDocSearchFilter();
  }
})();
