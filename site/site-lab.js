/**
 * Free Computation Foundation — Advanced Scientific Research Laboratory
 * SpaceX / Google DeepMind / xAI Aesthetic Engine
 * 3D Starfield Space Drift & Live Interactive Systems
 * Version: CentL26.10
 */

(function() {
  'use strict';

  // 1. High-Visibility 3D Space Drift Engine (Luminous Starfield & Cosmic Nebulas)
  function initSpaceDrift() {
    let canvas = document.getElementById('space-drift-canvas');
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'space-drift-canvas';
      canvas.style.position = 'fixed';
      canvas.style.top = '0';
      canvas.style.left = '0';
      canvas.style.width = '100vw';
      canvas.style.height = '100vh';
      canvas.style.zIndex = '0';
      canvas.style.pointerEvents = 'none';
      document.body.prepend(canvas);
    }
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    const STAR_COUNT = Math.min(Math.floor((width * height) / 2800), 500);
    const SPEED = 0.75;
    const stars = [];
    const nebulas = [];
    let mouse = { x: width / 2, y: height / 2, targetX: width / 2, targetY: height / 2 };

    // Initialize 3D Stars with High Visibility and Radiance
    for (let i = 0; i < STAR_COUNT; i++) {
      stars.push({
        x: (Math.random() - 0.5) * width * 2.4,
        y: (Math.random() - 0.5) * height * 2.4,
        z: Math.random() * 1000 + 1,
        size: Math.random() * 2.4 + 0.9,
        twinkleSpeed: Math.random() * 0.045 + 0.015,
        twinklePhase: Math.random() * Math.PI * 2,
        hue: Math.random() > 0.35 
          ? (Math.random() > 0.5 ? 195 : 215) // Electric Cyan / Deep Space Azure
          : (Math.random() > 0.5 ? 275 : 160) // Quantum Violet / Pulsar Emerald
      });
    }

    // Initialize Radiant Cosmic Nebula Clouds
    const nebulaColors = [
      { r: 14, g: 165, b: 233, a: 0.16 },  // Cyan Radiance
      { r: 99, g: 102, b: 241, a: 0.14 },  // Indigo Energy
      { r: 168, g: 85, b: 247, a: 0.12 },  // Violet Nebula
      { r: 16, g: 185, b: 129, a: 0.10 }   // Emerald Glow
    ];

    for (let i = 0; i < 6; i++) {
      const col = nebulaColors[i % nebulaColors.length];
      nebulas.push({
        x: Math.random() * width,
        y: Math.random() * height,
        radius: Math.random() * 340 + 220,
        vx: (Math.random() - 0.5) * 0.28,
        vy: (Math.random() - 0.5) * 0.28,
        col: col
      });
    }

    // Shooting Stars System
    const shootingStars = [];
    function maybeSpawnShootingStar() {
      if (shootingStars.length < 2 && Math.random() < 0.025) {
        shootingStars.push({
          x: Math.random() * width * 0.95,
          y: Math.random() * height * 0.4,
          length: Math.random() * 180 + 100,
          speed: Math.random() * 14 + 16,
          angle: Math.PI / 4 + (Math.random() - 0.5) * 0.3,
          opacity: 1.0,
          decay: Math.random() * 0.02 + 0.015
        });
      }
    }

    function render() {
      ctx.clearRect(0, 0, width, height);

      // 1. Render Floating Nebula Dust Clouds
      for (let n of nebulas) {
        n.x += n.vx;
        n.y += n.vy;
        if (n.x < -n.radius) n.x = width + n.radius;
        if (n.x > width + n.radius) n.x = -n.radius;
        if (n.y < -n.radius) n.y = height + n.radius;
        if (n.y > height + n.radius) n.y = -n.radius;

        const grad = ctx.createRadialGradient(n.x, n.y, 0, n.x, n.y, n.radius);
        grad.addColorStop(0, `rgba(${n.col.r}, ${n.col.g}, ${n.col.b}, ${n.col.a})`);
        grad.addColorStop(0.5, `rgba(${n.col.r}, ${n.col.g}, ${n.col.b}, ${n.col.a * 0.45})`);
        grad.addColorStop(1, 'transparent');
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.arc(n.x, n.y, n.radius, 0, Math.PI * 2);
        ctx.fill();
      }

      // Parallax mouse damping
      mouse.x += (mouse.targetX - mouse.x) * 0.04;
      mouse.y += (mouse.targetY - mouse.y) * 0.04;
      const offsetX = (mouse.x - width / 2) * 0.12;
      const offsetY = (mouse.y - height / 2) * 0.12;

      const cx = width / 2 + offsetX;
      const cy = height / 2 + offsetY;

      // 2. Render 3D Drifting Starfield
      for (let s of stars) {
        s.z -= SPEED;
        if (s.z <= 0) {
          s.z = 1000;
          s.x = (Math.random() - 0.5) * width * 2.4;
          s.y = (Math.random() - 0.5) * height * 2.4;
        }

        const k = 440 / s.z;
        const px = s.x * k + cx;
        const py = s.y * k + cy;

        if (px >= -30 && px <= width + 30 && py >= -30 && py <= height + 30) {
          s.twinklePhase += s.twinkleSpeed;
          const twinkle = (Math.sin(s.twinklePhase) + 1) * 0.35 + 0.4;
          const alpha = Math.min((1 - s.z / 1000) * twinkle * 1.4, 1.0);
          const radius = Math.max(s.size * k * 0.48, 0.8);

          ctx.beginPath();
          ctx.arc(px, py, radius, 0, Math.PI * 2);
          ctx.fillStyle = `hsla(${s.hue}, 95%, 85%, ${alpha})`;
          
          if (radius > 1.2) {
            ctx.shadowBlur = 12;
            ctx.shadowColor = `hsla(${s.hue}, 100%, 75%, ${alpha})`;
          }
          ctx.fill();
          ctx.shadowBlur = 0;
        }
      }

      // 3. Render Shooting Star Streaks
      maybeSpawnShootingStar();
      for (let i = shootingStars.length - 1; i >= 0; i--) {
        const star = shootingStars[i];
        const sx = star.x;
        const sy = star.y;
        const ex = sx - Math.cos(star.angle) * star.length;
        const ey = sy - Math.sin(star.angle) * star.length;

        const grad = ctx.createLinearGradient(sx, sy, ex, ey);
        grad.addColorStop(0, `rgba(255, 255, 255, ${star.opacity})`);
        grad.addColorStop(0.25, `rgba(56, 189, 248, ${star.opacity * 0.95})`);
        grad.addColorStop(0.7, `rgba(168, 85, 247, ${star.opacity * 0.6})`);
        grad.addColorStop(1, 'transparent');

        ctx.beginPath();
        ctx.moveTo(sx, sy);
        ctx.lineTo(ex, ey);
        ctx.strokeStyle = grad;
        ctx.lineWidth = 2.4;
        ctx.stroke();

        star.x += Math.cos(star.angle) * star.speed;
        star.y += Math.sin(star.angle) * star.speed;
        star.opacity -= star.decay;

        if (star.opacity <= 0 || star.x > width + 100 || star.y > height + 100) {
          shootingStars.splice(i, 1);
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

  // 2. Interactive Quantum Particle Lattice in Hero
  function initQuantumHeroCanvas() {
    const canvas = document.getElementById('quantum-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let width = (canvas.width = canvas.offsetWidth);
    let height = (canvas.height = canvas.offsetHeight);

    const particles = [];
    const count = Math.min(Math.floor((width * height) / 8000), 75);
    let mouse = { x: null, y: null, maxDist: 150 };

    class NodeParticle {
      constructor() {
        this.x = Math.random() * width;
        this.y = Math.random() * height;
        this.vx = (Math.random() - 0.5) * 0.6;
        this.vy = (Math.random() - 0.5) * 0.6;
        this.radius = Math.random() * 1.8 + 1;
        this.color = Math.random() > 0.3 ? 'rgba(56, 189, 248, 0.75)' : 'rgba(168, 85, 247, 0.65)';
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
        ctx.shadowBlur = 10;
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
          if (dist < 120) {
            const alpha = (1 - dist / 120) * 0.35;
            ctx.beginPath();
            ctx.moveTo(particles[a].x, particles[a].y);
            ctx.lineTo(particles[b].x, particles[b].y);
            ctx.strokeStyle = `rgba(56, 189, 248, ${alpha})`;
            ctx.lineWidth = 0.85;
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
            const alpha = (1 - dist / mouse.maxDist) * 0.55;
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(mouse.x, mouse.y);
            ctx.strokeStyle = `rgba(0, 240, 255, ${alpha})`;
            ctx.lineWidth = 1.2;
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

  // 3. One-Click Copy Buttons
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

  // 4. Live Search Filter
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

  // Bootstrap
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
