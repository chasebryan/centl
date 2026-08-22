/**
 * Free Computation Foundation — High-Visibility Deep Space Engine
 * 3D Starfield, Cosmic Dust Nebulae & Meteor Streaks
 * Retina / 4K HiDPI Scaled
 */

(function() {
  'use strict';

  function initSpaceDrift() {
    let canvas = document.getElementById('space-drift-canvas');
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'space-drift-canvas';
      document.body.prepend(canvas);
    }
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let width = 0;
    let height = 0;
    let dpr = window.devicePixelRatio || 1;

    function resize() {
      width = window.innerWidth;
      height = window.innerHeight;
      dpr = window.devicePixelRatio || 1;
      canvas.width = width * dpr;
      canvas.height = height * dpr;
      canvas.style.width = width + 'px';
      canvas.style.height = height + 'px';
      ctx.scale(dpr, dpr);
    }
    resize();

    // 600 High-Visibility 3D Stars
    const STAR_COUNT = 650;
    const SPEED = 0.85;
    const stars = [];

    for (let i = 0; i < STAR_COUNT; i++) {
      stars.push({
        x: (Math.random() - 0.5) * width * 3.0,
        y: (Math.random() - 0.5) * height * 3.0,
        z: Math.random() * 1000 + 1,
        baseSize: Math.random() * 2.2 + 1.2,
        twinkleSpeed: Math.random() * 0.05 + 0.02,
        twinklePhase: Math.random() * Math.PI * 2,
        color: Math.random() > 0.4 ? '#ffffff' : (Math.random() > 0.5 ? '#38bdf8' : '#c084fc')
      });
    }

    // 6 Radiant Cosmic Nebula Clouds
    const nebulas = [
      { x: width * 0.2, y: height * 0.3, radius: 450, color: 'rgba(14, 165, 233, 0.18)', vx: 0.1, vy: 0.05 },
      { x: width * 0.8, y: height * 0.6, radius: 500, color: 'rgba(168, 85, 247, 0.15)', vx: -0.08, vy: -0.06 },
      { x: width * 0.5, y: height * 0.8, radius: 400, color: 'rgba(0, 240, 255, 0.14)', vx: 0.05, vy: -0.08 },
      { x: width * 0.1, y: height * 0.9, radius: 350, color: 'rgba(16, 185, 129, 0.10)', vx: -0.05, vy: 0.04 }
    ];

    // Shooting Stars
    const shootingStars = [];
    function maybeSpawnShootingStar() {
      if (shootingStars.length < 2 && Math.random() < 0.03) {
        shootingStars.push({
          x: Math.random() * width * 0.9,
          y: Math.random() * height * 0.4,
          length: Math.random() * 200 + 120,
          speed: Math.random() * 16 + 18,
          angle: Math.PI / 4 + (Math.random() - 0.5) * 0.3,
          opacity: 1.0,
          decay: 0.022
        });
      }
    }

    let mouse = { x: width / 2, y: height / 2, targetX: width / 2, targetY: height / 2 };

    function render() {
      ctx.clearRect(0, 0, width, height);

      // 1. Draw Nebulae
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

      // Parallax
      mouse.x += (mouse.targetX - mouse.x) * 0.05;
      mouse.y += (mouse.targetY - mouse.y) * 0.05;
      const cx = width / 2 + (mouse.x - width / 2) * 0.1;
      const cy = height / 2 + (mouse.y - height / 2) * 0.1;

      // 2. Draw 3D Stars
      for (let s of stars) {
        s.z -= SPEED;
        if (s.z <= 0) {
          s.z = 1000;
          s.x = (Math.random() - 0.5) * width * 3.0;
          s.y = (Math.random() - 0.5) * height * 3.0;
        }

        const k = 500 / s.z;
        const px = s.x * k + cx;
        const py = s.y * k + cy;

        if (px >= -20 && px <= width + 20 && py >= -20 && py <= height + 20) {
          s.twinklePhase += s.twinkleSpeed;
          const twinkle = (Math.sin(s.twinklePhase) + 1) * 0.35 + 0.45;
          const alpha = Math.min((1 - s.z / 1000) * twinkle * 1.5, 1.0);
          const radius = Math.max(s.baseSize * k * 0.55, 1.0);

          ctx.beginPath();
          ctx.arc(px, py, radius, 0, Math.PI * 2);
          ctx.fillStyle = s.color;
          ctx.globalAlpha = alpha;

          if (radius > 1.8) {
            ctx.shadowBlur = 10;
            ctx.shadowColor = s.color;
          }
          ctx.fill();
          ctx.shadowBlur = 0;
          ctx.globalAlpha = 1.0;
        }
      }

      // 3. Draw Shooting Stars
      maybeSpawnShootingStar();
      for (let i = shootingStars.length - 1; i >= 0; i--) {
        const star = shootingStars[i];
        const sx = star.x;
        const sy = star.y;
        const ex = sx - Math.cos(star.angle) * star.length;
        const ey = sy - Math.sin(star.angle) * star.length;

        const grad = ctx.createLinearGradient(sx, sy, ex, ey);
        grad.addColorStop(0, `rgba(255, 255, 255, ${star.opacity})`);
        grad.addColorStop(0.3, `rgba(0, 240, 255, ${star.opacity * 0.9})`);
        grad.addColorStop(1, 'transparent');

        ctx.beginPath();
        ctx.moveTo(sx, sy);
        ctx.lineTo(ex, ey);
        ctx.strokeStyle = grad;
        ctx.lineWidth = 3.0;
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

    window.addEventListener('resize', resize);
    window.addEventListener('mousemove', (e) => {
      mouse.targetX = e.clientX;
      mouse.targetY = e.clientY;
    });

    render();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSpaceDrift);
  } else {
    initSpaceDrift();
  }
})();
