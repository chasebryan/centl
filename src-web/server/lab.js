(() => {
  "use strict";

  const storageKey = "centl26:26.0:layout:v1";
  const draftKey = "centl26:26.0:draft:v1";
  const areaKey = "centl26:26.0:area:v1";
  const modeKey = "centl26:26.0:mode:v1";
  const themeKey = "centl26:26.0:theme:v1";
  const inspectorTabKey = "centl26:26.0:inspector-tab:v1";
  const paneClasses = {
    explorer: "hide-explorer",
    inspector: "hide-inspector",
    console: "hide-console"
  };

  let paletteReturnFocus = null;
  let paletteActiveIndex = -1;
  let selectedArea = "work";
  let selectedMode = "Auto";
  let selectedInspectorTab = "result";
  let capabilitiesRequest = null;

  const areaNames = new Set(["work", "projects", "tools", "data", "models", "research", "build", "gemini"]);
  const interactionModes = new Set(["Auto", "Math", "Physics", "Research", "Build"]);
  const inspectorTabs = new Set(["result", "variables", "evidence"]);

  function workspace() {
    return document.querySelector(".workbench-shell");
  }

  function activeForm() {
    return document.querySelector(".active-cell[data-centl-form]");
  }

  function activeEditor() {
    return document.querySelector("#active-command");
  }

  function hasNotebookContent() {
    return Boolean(document.querySelector(".result-cell, .system-result, [data-receipt-target]"));
  }

  function syncComposerActions() {
    const hasInput = Boolean(activeEditor()?.value.trim());
    document.querySelectorAll("[data-run-active], .composer-run").forEach((button) => {
      button.disabled = !hasInput;
      button.setAttribute("aria-disabled", String(!hasInput));
    });
    const canClear = hasInput || hasNotebookContent();
    document.querySelectorAll("[data-clear-session]").forEach((button) => {
      button.disabled = !canClear;
      button.setAttribute("aria-disabled", String(!canClear));
    });
  }

  function readStorage(key) {
    try {
      return localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  function writeStorage(key, value) {
    try {
      localStorage.setItem(key, value);
    } catch (_) {
      // The workbench remains fully usable when persistent storage is unavailable.
    }
  }

  function removeStorage(key) {
    try {
      localStorage.removeItem(key);
    } catch (_) {
      // Nothing needs to be recovered when storage is unavailable.
    }
  }

  function applyTheme(theme) {
    const isDim = theme === "dim";
    document.body.classList.toggle("theme-dim", isDim);
    document.documentElement.dataset.theme = isDim ? "dim" : "light";
    document.querySelectorAll(".theme-toggle, [data-toggle-theme]").forEach((button) => {
      const sun = button.querySelector(".theme-icon-sun");
      const moon = button.querySelector(".theme-icon-moon");
      if (sun) sun.style.display = isDim ? "none" : "block";
      if (moon) moon.style.display = isDim ? "block" : "none";
      button.setAttribute("title", isDim ? "Switch to standard theme" : "Toggle dimmed theme");
      button.setAttribute("aria-label", isDim ? "Switch to standard theme" : "Toggle dimmed theme");
    });
    writeStorage(themeKey, isDim ? "dim" : "light");
  }

  function toggleTheme() {
    const current = readStorage(themeKey) || (document.body.classList.contains("theme-dim") ? "dim" : "light");
    applyTheme(current === "dim" ? "light" : "dim");
  }

  function paneIsVisible(name) {
    return !document.body.classList.contains(paneClasses[name]);
  }

  function syncLayoutControls() {
    const controls = {
      explorer: "[data-toggle-explorer]",
      inspector: "[data-toggle-inspector]",
      console: "[data-toggle-console]"
    };

    Object.entries(controls).forEach(([name, selector]) => {
      const visible = paneIsVisible(name);
      document.querySelectorAll(selector).forEach((control) => {
        control.setAttribute("aria-pressed", String(visible));
      });
    });
  }

  function saveLayout() {
    const hidden = {};
    Object.entries(paneClasses).forEach(([name, className]) => {
      hidden[name] = document.body.classList.contains(className);
    });
    writeStorage(storageKey, JSON.stringify({ version: 1, hidden }));
  }

  function restoreLayout() {
    const stored = readStorage(storageKey);

    // A fresh profile deliberately keeps the calm, panel-free classes from the
    // server-rendered document instead of manufacturing a layout from defaults.
    if (stored === null) {
      syncLayoutControls();
      return;
    }

    try {
      const state = JSON.parse(stored);
      const hidden = state && state.hidden;
      if (!hidden || typeof hidden !== "object") throw new Error("invalid layout");

      Object.entries(paneClasses).forEach(([name, className]) => {
        if (typeof hidden[name] === "boolean") {
          document.body.classList.toggle(className, hidden[name]);
        }
      });
    } catch (_) {
      removeStorage(storageKey);
    }

    syncLayoutControls();
  }

  function setPaneVisible(name, visible, { persist = true } = {}) {
    const className = paneClasses[name];
    if (!className) return;
    document.body.classList.toggle(className, !visible);
    if (persist) saveLayout();
    syncLayoutControls();
  }

  function togglePane(name) {
    setPaneVisible(name, !paneIsVisible(name));
  }

  function storedChoice(key, allowed, fallback) {
    const stored = readStorage(key);
    if (stored && allowed.has(stored)) return stored;
    if (stored !== null) removeStorage(key);
    return fallback;
  }

  function selectArea(area, { focus = false, openExplorer = false, persist = true } = {}) {
    if (!areaNames.has(area)) area = "work";
    selectedArea = area;
    if (persist) writeStorage(areaKey, area);

    document.querySelectorAll(".rail-button[data-select-area]").forEach((button) => {
      const active = button.dataset.selectArea === area;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-pressed", String(active));
      if (active) button.setAttribute("aria-current", "page");
      else button.removeAttribute("aria-current");
    });

    document.querySelectorAll("[data-area-panel]").forEach((panel) => {
      panel.hidden = panel.dataset.areaPanel !== area;
    });

    const activePanel = document.querySelector(`[data-area-panel="${area}"]`);
    const title = document.querySelector("[data-area-title]:not([data-area-panel])");
    const subtitle = document.querySelector("[data-area-subtitle]:not([data-area-panel])");
    if (title) title.textContent = activePanel?.dataset.areaTitle || "Work";
    if (subtitle) subtitle.textContent = activePanel?.dataset.areaSubtitle || "Local project";

    if (openExplorer || area !== "work") setPaneVisible("explorer", true);
    if (focus && area === "work") activeEditor()?.focus({ preventScroll: true });
  }

  function modePlaceholder(mode) {
    if (mode === "Math") return "Enter an exact or symbolic expression…";
    if (mode === "Physics") return "Enter a supported physics command…";
    if (mode === "Research") return "Enter a supported research command…";
    if (mode === "Build") return "Build execution is unavailable; inspect Build status…";
    return "Enter a supported expression or command…";
  }

  function applyInteractionMode(mode, { persist = true } = {}) {
    if (!interactionModes.has(mode)) mode = "Auto";
    selectedMode = mode;
    if (persist) writeStorage(modeKey, mode);

    document.querySelectorAll(".mode-control select").forEach((select) => {
      select.value = mode;
    });
    document.querySelectorAll('input[type="hidden"][name="interaction_mode"]').forEach((input) => {
      input.value = mode;
    });
    document.querySelectorAll("#active-command").forEach((editor) => {
      editor.placeholder = modePlaceholder(mode);
    });

    const input = paletteInput();
    if (input && palette() && !palette().hidden) filterPalette(input.value);
  }

  function statusLabel(status) {
    if (!status) return "Unavailable";
    const words = status.replaceAll("-", " ");
    return words.charAt(0).toUpperCase() + words.slice(1);
  }

  async function capabilityPayload(root = document) {
    const endpoint = root.querySelector?.("[data-capabilities-endpoint]")?.dataset.capabilitiesEndpoint
      || document.querySelector("[data-capabilities-endpoint]")?.dataset.capabilitiesEndpoint
      || "/api/capabilities";
    if (!capabilitiesRequest) {
      capabilitiesRequest = fetch(endpoint, {
        credentials: "same-origin",
        headers: { Accept: "application/json" }
      }).then((response) => {
        if (!response.ok) throw new Error(`capabilities returned ${response.status}`);
        return response.json();
      }).catch(() => {
        capabilitiesRequest = null;
        return null;
      });
    }
    return capabilitiesRequest;
  }

  async function hydrateCapabilities(root = document) {
    const payload = await capabilityPayload(root);
    if (!payload || (root !== document && !root.isConnected)) return;
    const capabilities = new Map(
      (Array.isArray(payload.capabilities) ? payload.capabilities : [])
        .filter((capability) => capability && typeof capability.id === "string")
        .map((capability) => [capability.id, capability])
    );

    document.querySelectorAll("[data-capability-id]").forEach((row) => {
      const capability = capabilities.get(row.dataset.capabilityId);
      if (!capability) return;
      const status = typeof capability.status === "string" ? capability.status : "unavailable";
      const effectiveStatus = capability.runtime_available === false ? "unavailable" : status;
      const provider = row.querySelector("[data-capability-provider]");
      const statusNode = row.querySelector("[data-capability-status]");
      row.dataset.status = effectiveStatus;
      if (provider) {
        const unavailableReason = typeof capability.unavailable_reason === "string"
          ? capability.unavailable_reason
          : "";
        provider.textContent = capability.runtime_available === false && unavailableReason
          ? unavailableReason
          : (capability.provider || "Not registered");
      }
      if (statusNode) statusNode.textContent = statusLabel(effectiveStatus);
    });

    document.querySelectorAll("[data-requires-capability]").forEach((control) => {
      const capability = capabilities.get(control.dataset.requiresCapability);
      if (!capability) return;
      const status = typeof capability.status === "string" ? capability.status : "unavailable";
      const unavailable = capability.runtime_available === false
        || status === "unavailable"
        || status === "integration-planned";
      const badge = control.querySelector("kbd");
      if (badge && !badge.dataset.runtimeLabel) badge.dataset.runtimeLabel = badge.textContent;
      control.disabled = unavailable;
      control.setAttribute("aria-disabled", String(unavailable));
      control.dataset.runtimeAvailable = String(!unavailable);
      if (badge) badge.textContent = unavailable ? "Unavailable" : badge.dataset.runtimeLabel;
      if (unavailable) {
        control.title = capability.unavailable_reason || `${statusLabel(status)} in this runtime`;
      } else {
        control.removeAttribute("title");
      }
    });

    const input = paletteInput();
    if (input) filterPalette(input.value);
  }

  function valueAtPath(value, path) {
    return path.split(".").reduce((current, part) => {
      if (!current || typeof current !== "object") return undefined;
      return current[part];
    }, value);
  }

  async function hydrateWorkspace(root = document) {
    const endpoint = root.querySelector?.("[data-workspace-endpoint]")?.dataset.workspaceEndpoint;
    if (!endpoint) return;
    try {
      const response = await fetch(endpoint, {
        credentials: "same-origin",
        headers: { Accept: "application/json" }
      });
      if (!response.ok) return;
      const payload = await response.json();
      if (root !== document && !root.isConnected) return;
      root.querySelectorAll?.("[data-workspace-field]").forEach((node) => {
        const value = valueAtPath(payload, node.dataset.workspaceField || "");
        if (["string", "number", "bigint"].includes(typeof value)) {
          node.textContent = String(value);
        }
      });
    } catch (_) {
      // Server-rendered session facts remain the honest fallback.
    }
  }

  function encodeForm(form, submitter) {
    const data = new FormData(form);
    if (submitter && submitter.name) {
      data.set(submitter.name, submitter.value);
    }
    return new URLSearchParams(Array.from(data.entries()));
  }

  async function execute(parameters, options = {}) {
    const current = workspace();
    if (!current || current.classList.contains("is-loading")) return;

    const restoreEditorFocus = options.restoreEditorFocus ?? document.activeElement === activeEditor();
    current.classList.add("is-loading");
    current.setAttribute("aria-busy", "true");

    try {
      const response = await fetch("/api/run", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8" },
        body: parameters,
        credentials: "same-origin"
      });
      if (!response.ok) throw new Error(`CentL26 returned ${response.status}`);

      const fragment = document.createRange().createContextualFragment(await response.text());
      const next = fragment.querySelector(".workbench-shell");
      if (!next) throw new Error("CentL26 returned an invalid workspace fragment");

      current.replaceWith(next);
      removeStorage(draftKey);
      initializeWorkspace(next);
      syncLayoutControls();

      // Keep the newest cell visible inside the notebook without moving the page.
      const feed = next.querySelector(".notebook-feed, .notebook-scroll");
      if (feed) feed.scrollTop = feed.scrollHeight;

      // Restore typing only when the editor itself launched the run. Toolbar and
      // palette runs should not unexpectedly steal focus from the user's control.
      if (restoreEditorFocus) activeEditor()?.focus({ preventScroll: true });
    } catch (error) {
      current.classList.remove("is-loading");
      current.setAttribute("aria-busy", "false");
      showHostError(error instanceof Error ? error.message : String(error));
    }
  }

  function runCommand(command, { interactionMode = selectedMode } = {}) {
    closePalette({ restoreFocus: false });
    execute(new URLSearchParams({
      lab_action: "calculate",
      cmd: command,
      interaction_mode: interactionMode
    }));
  }

  function startNewComputation({ fromPalette = false } = {}) {
    if (fromPalette) closePalette({ restoreFocus: false });
    selectArea("work", { focus: true });
    const editor = activeEditor();
    if (editor) {
      editor.value = "";
      removeStorage(draftKey);
      editor.scrollIntoView({ block: "nearest" });
      syncComposerActions();
    }
    execute(new URLSearchParams({
      lab_action: "calculate",
      cmd: ":new-notebook",
      interaction_mode: selectedMode
    }), { restoreEditorFocus: true });
  }

  function clearNotebook() {
    const editor = activeEditor();
    const hasWork = Boolean(editor?.value.trim()) || hasNotebookContent();
    if (hasWork && !window.confirm("Clear this CentL26 notebook and its saved receipts?")) return;
    execute(new URLSearchParams({
      lab_action: "calculate",
      cmd: ":clear",
      interaction_mode: selectedMode
    }), { restoreEditorFocus: true });
  }

  function showHostError(message) {
    let notice = document.querySelector(".host-error");
    if (!notice) {
      notice = document.createElement("div");
      notice.className = "host-error";
      notice.setAttribute("role", "alert");
      document.body.appendChild(notice);
    }
    notice.textContent = message;
    window.setTimeout(() => notice.remove(), 5000);
  }

  function showHostNotice(message) {
    let notice = document.querySelector(".host-notice");
    if (!notice) {
      notice = document.createElement("div");
      notice.className = "host-notice";
      notice.setAttribute("role", "status");
      document.body.appendChild(notice);
    }
    notice.textContent = message;
    window.setTimeout(() => notice.remove(), 5000);
  }

  // --- STEM Academic Omnibar & FCF Knowledge Router ---
  let fcfDocsCache = [];
  let omnibarActiveCategory = "all";
  let omnibarActiveIndex = -1;
  let activeDoc = null;

  async function loadFcfDocs() {
    try {
      const res = await fetch("/api/fcf-docs", { credentials: "same-origin" });
      if (res.ok) {
        const json = await res.json();
        if (json.documents && Array.isArray(json.documents)) {
          fcfDocsCache = json.documents;
        }
      }
    } catch (_) {}
  }

  function omnibar() {
    return document.querySelector(".header-omnibar");
  }

  function omnibarInput() {
    return document.querySelector("[data-omnibar-input]");
  }

  function omnibarDropdown() {
    return document.querySelector("[data-omnibar-dropdown]");
  }

  function omnibarResults() {
    return document.querySelector("[data-omnibar-results]");
  }

  function omnibarClear() {
    return document.querySelector("[data-omnibar-clear]");
  }

  function escapeHtml(text) {
    if (!text) return "";
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function renderMarkdownToHtml(md) {
    if (!md) return "";
    let html = escapeHtml(md)
      .replace(/```([a-z0-9_-]*)\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>')
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/^### (.*$)/gim, '<h3>$1</h3>')
      .replace(/^## (.*$)/gim, '<h2>$1</h2>')
      .replace(/^# (.*$)/gim, '<h1>$1</h1>')
      .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
      .replace(/\*([^*]+)\*/g, '<em>$1</em>')
      .replace(/^\&gt; (.*$)/gim, '<blockquote style="margin: 8px 0; padding: 6px 12px; border-left: 3px solid #1A73E8; background: var(--surface-subtle); color: var(--muted);">$1</blockquote>')
      .replace(/^\s*[-*]\s+(.*$)/gim, '<li style="margin-left: 18px;">$1</li>')
      .replace(/\n\n/g, '</p><p>');

    return `<p>${html}</p>`
      .replace(/<p><\/p>/g, '')
      .replace(/<p>(<h[1-3]>.*?<\/h[1-3]>)<\/p>/g, '$1')
      .replace(/<p>(<pre>.*?<\/pre>)<\/p>/gs, '$1');
  }

  function getChromeProviders(query) {
    const term = (query || "quantum mechanics").trim();
    const q = encodeURIComponent(term);
    return [
      {
        id: "google-scholar",
        category: "chrome",
        source: "Google Scholar",
        title: `Google Scholar: Search "${term}"`,
        subtitle: "Peer-reviewed scientific research, citations, patents and preprints",
        url: `https://scholar.google.com/scholar?q=${q}`
      },
      {
        id: "arxiv",
        category: "chrome",
        source: "arXiv.org",
        title: `arXiv Preprints: Search "${term}"`,
        subtitle: "Physics, Mathematics, Quantitative Biology, CS & Machine Learning",
        url: `https://arxiv.org/search/?query=${q}&searchtype=all`
      },
      {
        id: "pubmed",
        category: "chrome",
        source: "PubMed / NCBI",
        title: `PubMed Central: Search "${term}"`,
        subtitle: "Biomedical articles, molecular biology, genetics & pharmacology",
        url: `https://pubmed.ncbi.nlm.nih.gov/?term=${q}`
      },
      {
        id: "mathworld",
        category: "chrome",
        source: "Wolfram MathWorld",
        title: `Wolfram MathWorld: Lookup "${term}"`,
        subtitle: "Definitive mathematical definitions, derivations, theorems and proofs",
        url: `https://mathworld.wolfram.com/search/?query=${q}`
      },
      {
        id: "nist",
        category: "chrome",
        source: "NIST Chemistry WebBook",
        title: `NIST Chemistry WebBook: "${term}"`,
        subtitle: "Thermochemical kinetics, IR/UV/MS spectra & reaction equilibrium constants",
        url: `https://webbook.nist.gov/cgi/cbook.cgi?Name=${q}`
      },
      {
        id: "oeis",
        category: "chrome",
        source: "OEIS Database",
        title: `OEIS Integer Sequences: "${term}"`,
        subtitle: "On-Line Encyclopedia of Integer Sequences and generating series",
        url: `https://oeis.org/search?q=${q}`
      },
      {
        id: "ieee-xplore",
        category: "chrome",
        source: "IEEE Xplore",
        title: `IEEE Xplore Research: "${term}"`,
        subtitle: "Electrical engineering, computer science & applied physics literature",
        url: `https://ieeexplore.ieee.org/search/searchresult.jsp?newsearch=true&queryText=${q}`
      },
      {
        id: "nasa-ads",
        category: "chrome",
        source: "NASA Astrophysics (ADS)",
        title: `NASA ADS: Search "${term}"`,
        subtitle: "Astrophysics, planetary sciences & high-energy particle physics",
        url: `https://ui.adsabs.harvard.edu/search/q=${q}`
      }
    ];
  }

  function getCentlSolverSuggestions(query) {
    const q = query.trim();
    if (!q) {
      return [
        {
          id: "solver-calc",
          category: "tools",
          source: "Exact Math",
          title: "Exact Rational Arithmetic (1/3 + 5/7)",
          subtitle: "Arbitrary-precision fractions and integer computation",
          command: "1/3 + 5/7"
        },
        {
          id: "solver-solve",
          category: "tools",
          source: "Algebra",
          title: "Solve Equation (solve(x^2 - 5*x + 6 = 0, x))",
          subtitle: "Exact symbolic polynomial roots",
          command: "solve(x^2 - 5*x + 6 = 0, x)"
        },
        {
          id: "solver-diff",
          category: "tools",
          source: "Calculus",
          title: "Differentiate (diff(x^3 * sin(x), x))",
          subtitle: "Exact symbolic derivative",
          command: "diff(x^3 * sin(x), x)"
        },
        {
          id: "solver-chem",
          category: "tools",
          source: "Chemistry",
          title: "Balance Reaction (chem balance C3H8 + O2 = CO2 + H2O)",
          subtitle: "Stoichiometric matrix balancing",
          command: "chem balance C3H8 + O2 = CO2 + H2O"
        },
        {
          id: "solver-physics",
          category: "tools",
          source: "Physics",
          title: "SI Unit Conversion (physics convert 100 km/h m/s)",
          subtitle: "Typed dimensional analysis",
          command: "physics convert 100 km/h m/s"
        },
        {
          id: "solver-es",
          category: "tools",
          source: "Research",
          title: "Erdős–Straus Solver (es solve 1009)",
          subtitle: "Exact 4/p Egyptian fraction decomposition",
          command: "es solve 1009"
        }
      ];
    }

    return [
      {
        id: "solver-eval",
        category: "tools",
        source: "CentL Engine",
        title: `Run in Notebook: "${q}"`,
        subtitle: "Execute in active CentL26 workspace session",
        command: q
      }
    ];
  }

  function renderOmnibarResults(query = "", category = omnibarActiveCategory) {
    const container = omnibarResults();
    if (!container) return;

    const rawQuery = query.trim();
    const q = rawQuery.toLowerCase();
    const tokens = q.split(/\s+/).filter(Boolean);
    const items = [];

    // 1. Google Chrome Academic Suggestions
    if (category === "all" || category === "chrome") {
      const providers = getChromeProviders(rawQuery);
      providers.forEach((p) => {
        items.push({
          type: "chrome",
          iconClass: "chrome",
          iconSvg: `<svg viewBox="0 0 24 24" class="fcf-chrome-emblem" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2"/><path d="M12 2a10 10 0 0 1 8.66 5H12z" fill="#EA4335"/><path d="M20.66 7A10 10 0 0 1 15 21.32L10.67 13.82z" fill="#FBBC05"/><path d="M15 21.32A10 10 0 0 1 3.34 12.5L7.67 5z" fill="#34A853"/><path d="M3.34 12.5A10 10 0 0 1 12 2l4.33 7.5H7.67z" fill="#4285F4"/><circle cx="12" cy="12" r="4.5" fill="#ffffff" stroke="#cbd5e1" stroke-width="0.8"/><circle cx="12" cy="12" r="2.8" fill="#1A73E8"/></svg>`,
          source: p.source,
          title: p.title,
          subtitle: p.subtitle,
          actionLabel: "Search in Chrome ↗",
          actionClass: "chrome-action",
          url: p.url
        });
      });
    }

    // 2. FCF Manuals & Documentation
    if (category === "all" || category === "docs") {
      const docs = fcfDocsCache.filter(d => d.category === "manual" || d.category === "spec");
      const matchedDocs = tokens.length === 0 ? docs : docs.filter(d => {
        const text = `${d.title} ${d.summary} ${d.tags ? d.tags.join(" ") : ""}`.toLowerCase();
        return tokens.some(t => text.includes(t));
      });
      matchedDocs.forEach(d => {
        items.push({
          type: "doc",
          iconClass: "doc",
          iconText: "📖",
          source: d.category === "manual" ? "FCF Manual" : "FCF Spec",
          title: d.title,
          subtitle: d.summary,
          actionLabel: "Read In-App",
          actionClass: "",
          docId: d.id
        });
      });
    }

    // 3. FCF Research Papers & Preprints
    if (category === "all" || category === "research") {
      const papers = fcfDocsCache.filter(d => d.category === "research");
      const matchedPapers = tokens.length === 0 ? papers : papers.filter(d => {
        const text = `${d.title} ${d.summary} ${d.tags ? d.tags.join(" ") : ""}`.toLowerCase();
        return tokens.some(t => text.includes(t));
      });
      matchedPapers.forEach(p => {
        items.push({
          type: "research",
          iconClass: "research",
          iconText: "📑",
          source: "FCF Preprint",
          title: p.title,
          subtitle: p.summary,
          actionLabel: "Read Paper In-App",
          actionClass: "",
          docId: p.id
        });
      });
    }

    // 4. CentL Tools & Solvers
    if (category === "all" || category === "tools") {
      const solvers = getCentlSolverSuggestions(rawQuery);
      solvers.forEach(s => {
        items.push({
          type: "solver",
          iconClass: "solver",
          iconText: "⚙",
          source: s.source,
          title: s.title,
          subtitle: s.subtitle,
          actionLabel: "Run in Notebook ↵",
          actionClass: "",
          command: s.command
        });
      });
    }

    if (items.length === 0) {
      container.innerHTML = `
        <div style="padding: 24px 16px; text-align: center; color: var(--muted); font-size: 12.5px;">
          No local results found.<br>
          <button type="button" class="doc-btn doc-chrome-btn" data-omnibar-url="https://scholar.google.com/scholar?q=${encodeURIComponent(rawQuery)}" style="margin-top: 10px;">
            Search "${escapeHtml(rawQuery)}" on Google Scholar with Chrome ↗
          </button>
        </div>
      `;
      return;
    }

    let html = "";
    let currentGroup = null;

    items.forEach((item, index) => {
      if (item.type !== currentGroup) {
        currentGroup = item.type;
        const groupLabels = {
          chrome: "Academic Literature (Google Chrome Router)",
          doc: "FCF Manuals & Documentation",
          research: "FCF Theoretical Research Papers",
          solver: "CentL Tools & Exact Solvers"
        };
        html += `<div class="omnibar-group-header">${groupLabels[currentGroup] || "Suggestions"}</div>`;
      }

      const icon = item.iconSvg || `<span class="omnibar-item-icon ${item.iconClass}">${item.iconText || "•"}</span>`;
      const actionAttr = item.url
        ? `data-omnibar-url="${escapeHtml(item.url)}"`
        : item.docId
        ? `data-omnibar-doc="${escapeHtml(item.docId)}"`
        : item.command
        ? `data-omnibar-cmd="${escapeHtml(item.command)}"`
        : "";

      html += `
        <button type="button" class="omnibar-item" role="option" tabindex="-1" ${actionAttr} data-item-index="${index}">
          <span class="omnibar-item-icon ${item.iconClass}">${item.iconSvg || item.iconText || "•"}</span>
          <span class="omnibar-item-content">
            <strong>${escapeHtml(item.title)}</strong>
            <small>${escapeHtml(item.subtitle)}</small>
          </span>
          <span class="omnibar-item-action ${item.actionClass || ''}">${escapeHtml(item.actionLabel || '')}</span>
        </button>
      `;
    });

    container.innerHTML = html;
    setOmnibarActiveIndex(0);
  }

  function setOmnibarActiveIndex(index) {
    const container = omnibarResults();
    if (!container) return;
    const items = Array.from(container.querySelectorAll(".omnibar-item"));
    items.forEach(i => i.classList.remove("is-highlighted"));

    if (items.length === 0) {
      omnibarActiveIndex = -1;
      return;
    }

    omnibarActiveIndex = ((index % items.length) + items.length) % items.length;
    const active = items[omnibarActiveIndex];
    if (active) {
      active.classList.add("is-highlighted");
      active.scrollIntoView({ block: "nearest" });
    }
  }

  let isOpeningChrome = false;
  function openInChrome(url) {
    if (!url || isOpeningChrome) return;
    isOpeningChrome = true;
    setTimeout(() => { isOpeningChrome = false; }, 800);

    showHostNotice("Opening in Google Chrome...");
    closeOmnibar();

    fetch("/api/open-chrome", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url })
    }).catch(() => {});
  }

  function openFcfDoc(docId) {
    const doc = fcfDocsCache.find(d => d.id === docId);
    if (!doc) return;
    activeDoc = doc;
    const modal = document.querySelector("[data-fcf-doc-modal]");
    const title = document.querySelector("#fcf-doc-title");
    const content = document.querySelector("[data-fcf-doc-content]");
    if (modal && title && content) {
      title.textContent = doc.title;
      content.innerHTML = renderMarkdownToHtml(doc.content);
      modal.hidden = false;
      closeOmnibar();
    }
  }

  function closeFcfDoc() {
    const modal = document.querySelector("[data-fcf-doc-modal]");
    if (modal) modal.hidden = true;
    activeDoc = null;
  }

  // --- STEM DYNAMIC VISUALIZER & THEOREM LAB ---
  const StemVisualizer = {
    canvas: null,
    ctx: null,
    modal: null,
    animId: null,
    isOpen: false,
    initialized: false,
    
    // Viewport
    view: {
      centerX: 0,
      centerY: 0,
      zoom: 46, // pixels per unit
      isDragging: false,
      dragStartX: 0,
      dragStartY: 0,
      origCenterX: 0,
      origCenterY: 0
    },
    
    // Animation
    anim: {
      time: 0,
      isPlaying: true,
      speed: 1.0,
      lastFrame: 0,
      maxTime: 10.0
    },
    
    // Parameters
    params: {
      a: 1.0,
      b: 1.0,
      c: 0.0,
      k: 3,
      omega: 1.5
    },
    
    // Active theorem
    currentTheorem: "riemann",
    
    // Custom Tracks
    tracks: [
      { expr: "sin(x - 2*t)", active: true, color: "#06b6d4", compiled: null },
      { expr: "cos(2*x + t) * exp(-0.1*abs(x))", active: true, color: "#8b5cf6", compiled: null },
      { expr: "", active: false, color: "#f59e0b", compiled: null }
    ],

    compileExpression: function(expr) {
      if (!expr || !expr.trim()) return null;
      let clean = expr.trim()
        .replace(/\^/g, "**")
        .replace(/\bpi\b/gi, "Math.PI")
        .replace(/\be\b/g, "Math.E")
        .replace(/\btau\b/gi, "(2*Math.PI)")
        .replace(/\bsin\b/g, "Math.sin")
        .replace(/\bcos\b/g, "Math.cos")
        .replace(/\btan\b/g, "Math.tan")
        .replace(/\basin\b/g, "Math.asin")
        .replace(/\bacos\b/g, "Math.acos")
        .replace(/\batan\b/g, "Math.atan")
        .replace(/\bexp\b/g, "Math.exp")
        .replace(/\bln\b/g, "Math.log")
        .replace(/\blog\b/g, "Math.log10")
        .replace(/\bsqrt\b/g, "Math.sqrt")
        .replace(/\babs\b/g, "Math.abs")
        .replace(/\bsinc\b/g, "(x === 0 ? 1 : Math.sin(x)/x)")
        .replace(/\bfloor\b/g, "Math.floor")
        .replace(/\bceil\b/g, "Math.ceil");
      
      try {
        return new Function("x", "t", "a", "b", "c", "k", "omega", `return (${clean});`);
      } catch (e) {
        return null;
      }
    },

    toScreen: function(x, y) {
      const rect = StemVisualizer.canvas.getBoundingClientRect();
      const v = StemVisualizer.view;
      return {
        x: rect.width / 2 + v.centerX + x * v.zoom,
        y: rect.height / 2 + v.centerY - y * v.zoom
      };
    },

    toMath: function(screenX, screenY) {
      const rect = StemVisualizer.canvas.getBoundingClientRect();
      const v = StemVisualizer.view;
      return {
        x: (screenX - (rect.width / 2 + v.centerX)) / v.zoom,
        y: ((rect.height / 2 + v.centerY) - screenY) / v.zoom
      };
    },

    drawMathCurve: function(ctx, fn, color, lineWidth = 2) {
      const rect = StemVisualizer.canvas.getBoundingClientRect();
      const w = rect.width;
      ctx.strokeStyle = color;
      ctx.lineWidth = lineWidth;
      ctx.beginPath();
      
      let isDrawing = false;
      const pxStep = 2;
      for (let px = 0; px <= w; px += pxStep) {
        const math = StemVisualizer.toMath(px, 0);
        try {
          const y = fn(math.x);
          if (isNaN(y) || !isFinite(y) || Math.abs(y) > 500) {
            isDrawing = false;
            continue;
          }
          const sc = StemVisualizer.toScreen(math.x, y);
          if (!isDrawing) {
            ctx.moveTo(sc.x, sc.y);
            isDrawing = true;
          } else {
            ctx.lineTo(sc.x, sc.y);
          }
        } catch (e) {
          isDrawing = false;
        }
      }
      ctx.stroke();
    },

    drawGrid: function(ctx, width, height) {
      ctx.fillStyle = "#090d16";
      ctx.fillRect(0, 0, width, height);
      
      const v = StemVisualizer.view;
      const originX = width / 2 + v.centerX;
      const originY = height / 2 + v.centerY;
      
      let step = 1;
      if (v.zoom < 25) step = 5;
      else if (v.zoom < 10) step = 10;
      else if (v.zoom > 120) step = 0.5;
      else if (v.zoom > 240) step = 0.25;
      
      const pixelStep = step * v.zoom;
      
      // Grid lines
      ctx.strokeStyle = "rgba(255, 255, 255, 0.05)";
      ctx.lineWidth = 1;
      
      const startX = (originX % pixelStep) - pixelStep;
      for (let x = startX; x < width + pixelStep; x += pixelStep) {
        ctx.beginPath();
        ctx.moveTo(x, 0); ctx.lineTo(x, height);
        ctx.stroke();
      }
      const startY = (originY % pixelStep) - pixelStep;
      for (let y = startY; y < height + pixelStep; y += pixelStep) {
        ctx.beginPath();
        ctx.moveTo(0, y); ctx.lineTo(width, y);
        ctx.stroke();
      }
      
      // Axes
      ctx.strokeStyle = "rgba(255, 255, 255, 0.25)";
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(0, originY); ctx.lineTo(width, originY);
      ctx.moveTo(originX, 0); ctx.lineTo(originX, height);
      ctx.stroke();
      
      // Labels
      ctx.fillStyle = "rgba(148, 163, 184, 0.7)";
      ctx.font = "10px monospace";
      for (let x = startX; x < width + pixelStep; x += pixelStep) {
        const mathX = (x - originX) / v.zoom;
        if (Math.abs(mathX) > 0.001) {
          ctx.fillText(mathX.toFixed(step < 1 ? 2 : 0), x - 8, originY + 14);
        }
      }
      for (let y = startY; y < height + pixelStep; y += pixelStep) {
        const mathY = (originY - y) / v.zoom;
        if (Math.abs(mathY) > 0.001) {
          ctx.fillText(mathY.toFixed(step < 1 ? 2 : 0), originX + 6, y + 4);
        }
      }
      ctx.fillText("0", originX - 10, originY + 14);
    },

    theorems: {
      riemann: {
        title: "Riemann Integral Sum Approximation",
        desc: "Definite integral ∫ f(x)dx approximated by n step rectangles converging to exact analytical area.",
        render: function(ctx, width, height, t, p, toScreen) {
          const fn = (x) => Math.sin(x) + 0.4 * Math.sin(2 * x) + 1.2;
          const a = -2.5;
          const b = 2.0 + 0.8 * Math.sin(t * 0.8);
          const n = Math.max(4, Math.min(120, Math.round(p.k * 4)));
          const dx = (b - a) / n;
          
          let riemannSum = 0;
          for (let i = 0; i < n; i++) {
            const xi = a + i * dx;
            const xmid = xi + dx / 2;
            const yi = fn(xmid);
            riemannSum += yi * dx;
            
            const p1 = toScreen(xi, 0);
            ctx.fillStyle = i % 2 === 0 ? "rgba(6, 182, 212, 0.28)" : "rgba(14, 165, 233, 0.18)";
            ctx.strokeStyle = "rgba(56, 189, 248, 0.6)";
            ctx.lineWidth = 1;
            const rectW = dx * StemVisualizer.view.zoom;
            const rectH = (0 - yi) * StemVisualizer.view.zoom;
            ctx.fillRect(p1.x, p1.y, rectW, rectH);
            ctx.strokeRect(p1.x, p1.y, rectW, rectH);
          }
          
          StemVisualizer.drawMathCurve(ctx, fn, "#38bdf8", 2.5);
          
          const boundA = toScreen(a, 0);
          const boundB = toScreen(b, 0);
          ctx.strokeStyle = "#f43f5e";
          ctx.lineWidth = 1.5;
          ctx.setLineDash([4, 4]);
          ctx.beginPath();
          ctx.moveTo(boundA.x, 0); ctx.lineTo(boundA.x, height);
          ctx.moveTo(boundB.x, 0); ctx.lineTo(boundB.x, height);
          ctx.stroke();
          ctx.setLineDash([]);
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Interval [${a.toFixed(2)}, ${b.toFixed(2)}] | n = ${n} | Riemann Area ≈ ${riemannSum.toFixed(4)}`, 20, height - 30);
        }
      },
      
      taylor: {
        title: "Taylor / Maclaurin Series Polynomial Expansion",
        desc: "Polynomial series Pₙ(x) = ∑ f⁽ᵏ⁾(0)/k! · xᵏ converging to transcendental function sin(x).",
        render: function(ctx, width, height, t, p) {
          const n = Math.max(1, Math.min(15, Math.round(p.k)));
          const exactFn = Math.sin;
          const taylorSin = (x) => {
            let sum = 0;
            let term = x;
            for (let m = 0; m < n; m++) {
              sum += term;
              term = -term * x * x / ((2 * m + 2) * (2 * m + 3));
            }
            return sum;
          };
          
          ctx.setLineDash([6, 4]);
          StemVisualizer.drawMathCurve(ctx, exactFn, "rgba(255, 255, 255, 0.4)", 1.5);
          ctx.setLineDash([]);
          StemVisualizer.drawMathCurve(ctx, taylorSin, "#8b5cf6", 2.8);
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Target: sin(x) (Dashed) | Maclaurin Degree: ${2*n-1} (n=${n}) (Violet)`, 20, height - 30);
        }
      },

      fourier: {
        title: "Fourier Series Harmonic Synthesis",
        desc: "Superposition of infinite harmonic sines approximating square wave with Gibbs phenomenon.",
        render: function(ctx, width, height, t, p) {
          const N = Math.max(1, Math.min(30, Math.round(p.k)));
          const fourierSquare = (x) => {
            let sum = 0;
            for (let m = 1; m <= N; m++) {
              const k = 2 * m - 1;
              sum += (4 / Math.PI) * (Math.sin(k * (x - p.omega * t * 0.5)) / k);
            }
            return sum;
          };
          
          const targetSquare = (x) => Math.sin(x - p.omega * t * 0.5) >= 0 ? 1 : -1;
          ctx.setLineDash([4, 4]);
          StemVisualizer.drawMathCurve(ctx, targetSquare, "rgba(255, 255, 255, 0.3)", 1.2);
          ctx.setLineDash([]);
          StemVisualizer.drawMathCurve(ctx, fourierSquare, "#10b981", 2.5);
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Square Wave Harmonic Sum: N = ${N} | Phase ω = ${p.omega.toFixed(2)} rad/s`, 20, height - 30);
        }
      },

      tangent: {
        title: "Tangent Line & Instantaneous Derivative Flow",
        desc: "Instantaneous slope dy/dx vector flow moving along differentiable curve.",
        render: function(ctx, width, height, t, p, toScreen) {
          const fn = (x) => 0.2 * Math.pow(x, 3) - 0.8 * x + 0.5 * Math.sin(t);
          const df = (x) => 0.6 * Math.pow(x, 2) - 0.8;
          
          const x0 = 2.4 * Math.sin(t * 0.8);
          const y0 = fn(x0);
          const slope = df(x0);
          
          StemVisualizer.drawMathCurve(ctx, fn, "#38bdf8", 2.2);
          
          const tanFn = (x) => slope * (x - x0) + y0;
          StemVisualizer.drawMathCurve(ctx, tanFn, "#f43f5e", 2.0);
          
          const p0 = toScreen(x0, y0);
          ctx.fillStyle = "#f43f5e";
          ctx.beginPath();
          ctx.arc(p0.x, p0.y, 6, 0, Math.PI * 2);
          ctx.fill();
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`x₀ = ${x0.toFixed(2)}, f(x₀) = ${y0.toFixed(2)}, Instantaneous Slope f'(x₀) = ${slope.toFixed(3)}`, 20, height - 30);
        }
      },

      newton: {
        title: "Newton-Raphson Root Finding Iteration",
        desc: "Superlinear quadratic convergence xₙ₊₁ = xₙ - f(xₙ)/f'(xₙ) following tangent projections to the root.",
        render: function(ctx, width, height, t, p, toScreen) {
          const fn = (x) => 0.3 * Math.pow(x, 3) - 2 * x + 1;
          const df = (x) => 0.9 * Math.pow(x, 2) - 2;
          
          StemVisualizer.drawMathCurve(ctx, fn, "#38bdf8", 2.0);
          
          let xCurr = 3.2;
          const steps = Math.max(1, Math.min(6, Math.round(p.k)));
          
          for (let i = 0; i < steps; i++) {
            const yCurr = fn(xCurr);
            const slope = df(xCurr);
            const xNext = xCurr - yCurr / slope;
            
            const ptCurrent = toScreen(xCurr, yCurr);
            const ptGround = toScreen(xCurr, 0);
            const ptNext = toScreen(xNext, 0);
            
            ctx.strokeStyle = "rgba(245, 158, 11, 0.4)";
            ctx.setLineDash([2, 2]);
            ctx.beginPath();
            ctx.moveTo(ptGround.x, ptGround.y);
            ctx.lineTo(ptCurrent.x, ptCurrent.y);
            ctx.stroke();
            
            ctx.strokeStyle = "#f59e0b";
            ctx.setLineDash([]);
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.moveTo(ptCurrent.x, ptCurrent.y);
            ctx.lineTo(ptNext.x, ptNext.y);
            ctx.stroke();
            
            ctx.fillStyle = "#f59e0b";
            ctx.beginPath();
            ctx.arc(ptNext.x, ptNext.y, 4, 0, Math.PI * 2);
            ctx.fill();
            
            xCurr = xNext;
          }
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Newton Steps: ${steps} | Current Root Estimate: x ≈ ${xCurr.toFixed(6)} | Residue f(x) ≈ ${fn(xCurr).toExponential(2)}`, 20, height - 30);
        }
      },

      wave_interf: {
        title: "Wave Superposition, Interference & Standing Waves",
        desc: "Linear superposition y(x,t) = A₁ sin(kx - ωt) + A₂ sin(kx + ωt) creating stationary nodes and antinodes.",
        render: function(ctx, width, height, t, p) {
          const k = p.k * 0.8;
          const w = p.omega;
          const y1 = (x) => Math.sin(k * x - w * t);
          const y2 = (x) => Math.sin(k * x + w * t);
          const yCombined = (x) => y1(x) + y2(x);
          
          ctx.setLineDash([4, 4]);
          StemVisualizer.drawMathCurve(ctx, y1, "rgba(6, 182, 212, 0.4)", 1.2);
          StemVisualizer.drawMathCurve(ctx, y2, "rgba(139, 92, 246, 0.4)", 1.2);
          ctx.setLineDash([]);
          StemVisualizer.drawMathCurve(ctx, yCombined, "#10b981", 2.6);
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Standing Wave: 2·sin(${k.toFixed(1)}x)·cos(${w.toFixed(1)}t) | Emerald Curve`, 20, height - 30);
        }
      },

      damped_osc: {
        title: "Damped Harmonic Oscillator & Attenuation",
        desc: "Dynamic phase-attenuation envelope y(x, t) = e^(-γt) cos(ωd·t + φ) showing energy dissipation.",
        render: function(ctx, width, height, t, p) {
          const gamma = 0.15 * p.a;
          const wd = p.omega;
          const waveFn = (x) => Math.exp(-gamma * Math.abs(x)) * Math.cos(wd * x - 2 * t);
          const envelopePos = (x) => Math.exp(-gamma * Math.abs(x));
          const envelopeNeg = (x) => -Math.exp(-gamma * Math.abs(x));
          
          ctx.setLineDash([3, 3]);
          StemVisualizer.drawMathCurve(ctx, envelopePos, "rgba(244, 63, 94, 0.5)", 1.2);
          StemVisualizer.drawMathCurve(ctx, envelopeNeg, "rgba(244, 63, 94, 0.5)", 1.2);
          ctx.setLineDash([]);
          StemVisualizer.drawMathCurve(ctx, waveFn, "#f43f5e", 2.4);
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Damping γ = ${gamma.toFixed(3)} | Damped Frequency ω = ${wd.toFixed(2)} rad/s`, 20, height - 30);
        }
      },

      projectile: {
        title: "Projectile Drag Dynamics & Trajectory Comparison",
        desc: "Analytical vacuum parabola vs numerical Euler integration of quadratic air drag F_drag = -c|v|v.",
        render: function(ctx, width, height, t, p, toScreen) {
          const g = 9.81;
          const v0 = 16.0;
          const angle = (p.a * 15 + 30) * Math.PI / 180;
          const vx0 = v0 * Math.cos(angle);
          const vy0 = v0 * Math.sin(angle);
          
          const maxDistVac = (v0 * v0 * Math.sin(2 * angle)) / g;
          const vacY = (x) => (x * Math.tan(angle)) - (g * x * x) / (2 * v0 * v0 * Math.cos(angle) * Math.cos(angle));
          
          ctx.setLineDash([4, 4]);
          StemVisualizer.drawMathCurve(ctx, (x) => x >= 0 && x <= maxDistVac ? vacY(x) : NaN, "rgba(255, 255, 255, 0.35)", 1.4);
          ctx.setLineDash([]);
          
          const cDrag = 0.08 * p.b;
          let x = 0, y = 0, vx = vx0, vy = vy0, dtSim = 0.02;
          const pts = [{ x, y }];
          while (y >= 0 && x < 40) {
            const v = Math.sqrt(vx * vx + vy * vy);
            const ax = -cDrag * v * vx;
            const ay = -g - cDrag * v * vy;
            vx += ax * dtSim;
            vy += ay * dtSim;
            x += vx * dtSim;
            y += vy * dtSim;
            pts.push({ x, y: Math.max(0, y) });
          }
          
          ctx.strokeStyle = "#38bdf8";
          ctx.lineWidth = 2.4;
          ctx.beginPath();
          pts.forEach((pt, i) => {
            const sc = toScreen(pt.x, pt.y);
            if (i === 0) ctx.moveTo(sc.x, sc.y);
            else ctx.lineTo(sc.x, sc.y);
          });
          ctx.stroke();
          
          const currentSimIdx = Math.min(pts.length - 1, Math.floor((t % 4.0) * 25));
          const currPt = pts[currentSimIdx];
          const currSc = toScreen(currPt.x, currPt.y);
          ctx.fillStyle = "#f59e0b";
          ctx.beginPath();
          ctx.arc(currSc.x, currSc.y, 6, 0, Math.PI * 2);
          ctx.fill();
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Launch θ = ${(angle*180/Math.PI).toFixed(1)}° | v₀ = ${v0} m/s | Drag c = ${cDrag.toFixed(3)} | Vacuum (Dashed) vs Drag (Cyan)`, 20, height - 30);
        }
      },

      quantum_packet: {
        title: "Quantum Gaussian Wavepacket Dispersion",
        desc: "Time evolution of free quantum particle probability density |ψ(x,t)|² showing uncertainty spreading.",
        render: function(ctx, width, height, t, p) {
          const sigma0 = 0.8;
          const hbar_m = 0.5;
          const vg = 1.2;
          const x0 = vg * (t - 4.0);
          const sigmaT = Math.sqrt(sigma0 * sigma0 + Math.pow(hbar_m * t / sigma0, 2));
          
          const probDensity = (x) => (1 / (sigmaT * Math.sqrt(2 * Math.PI))) * Math.exp(-Math.pow(x - x0, 2) / (2 * sigmaT * sigmaT));
          const waveRe = (x) => probDensity(x) * Math.cos(5 * (x - x0));
          
          StemVisualizer.drawMathCurve(ctx, probDensity, "#06b6d4", 2.6);
          StemVisualizer.drawMathCurve(ctx, waveRe, "rgba(139, 92, 246, 0.6)", 1.2);
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Wavepacket Peak x₀ = ${x0.toFixed(2)} | Spatial Width σ(t) = ${sigmaT.toFixed(3)} | Group Velocity vg = ${vg} m/s`, 20, height - 30);
        }
      },

      chem_kinetics: {
        title: "Reversible First-Order Reaction Kinetics",
        desc: "Equilibrium concentrations [A](t) ⇌ [B](t) governed by forward/reverse rate constants k₁ and k₋₁.",
        render: function(ctx, width, height, t, p) {
          const k1 = Math.max(0.1, p.a * 0.5);
          const k_rev = Math.max(0.1, p.b * 0.3);
          const A0 = 2.0;
          const B0 = 0.0;
          const A_eq = (k_rev * (A0 + B0)) / (k1 + k_rev);
          const B_eq = (A0 + B0) - A_eq;
          const kSum = k1 + k_rev;
          
          const concA = (x) => x < 0 ? A0 : A_eq + (A0 - A_eq) * Math.exp(-kSum * x);
          const concB = (x) => x < 0 ? B0 : B_eq + (B0 - B_eq) * Math.exp(-kSum * x);
          
          StemVisualizer.drawMathCurve(ctx, concA, "#f43f5e", 2.4);
          StemVisualizer.drawMathCurve(ctx, concB, "#10b981", 2.4);
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`[A](t) Reactant (Red) | [B](t) Product (Green) | k₁ = ${k1.toFixed(2)}, k₋₁ = ${k_rev.toFixed(2)} | [A]eq = ${A_eq.toFixed(2)}`, 20, height - 30);
        }
      },

      maxwell_boltzmann: {
        title: "Maxwell-Boltzmann Molecular Speed Distribution",
        desc: "Statistical distribution of particle kinetic velocities f(v) = 4π(M/2πRT)^(3/2) v² exp(-Mv²/2RT).",
        render: function(ctx, width, height, t, p) {
          const T = Math.max(0.2, p.a);
          const mbSpeed = (v) => {
            if (v < 0) return 0;
            return (4 / Math.sqrt(Math.PI)) * Math.pow(1 / T, 1.5) * Math.pow(v, 2) * Math.exp(-Math.pow(v, 2) / T);
          };
          
          StemVisualizer.drawMathCurve(ctx, mbSpeed, "#f59e0b", 2.6);
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Temperature Parameter T = ${T.toFixed(2)} | Peak Speed vp = ${Math.sqrt(T).toFixed(2)}`, 20, height - 30);
        }
      },

      michaelis_menten: {
        title: "Enzyme Kinetics (Michaelis-Menten Model)",
        desc: "Substrate saturation velocity v = (Vmax · [S]) / (Km + [S]) and transition to zero-order maximum rate.",
        render: function(ctx, width, height, t, p) {
          const Vmax = 2.5 * p.a;
          const Km = Math.max(0.2, p.b);
          const mmRate = (S) => S < 0 ? 0 : (Vmax * S) / (Km + S);
          
          StemVisualizer.drawMathCurve(ctx, mmRate, "#10b981", 2.6);
          
          ctx.setLineDash([4, 4]);
          StemVisualizer.drawMathCurve(ctx, () => Vmax, "rgba(255, 255, 255, 0.35)", 1.2);
          ctx.setLineDash([]);
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Vmax = ${Vmax.toFixed(2)} | Michaelis Constant Km = ${Km.toFixed(2)}`, 20, height - 30);
        }
      },

      lissajous: {
        title: "Lissajous Complex Parametric Harmonics",
        desc: "Orthogonal harmonic oscillator trajectory (x(θ), y(θ)) = (A·sin(a·θ + δ), B·sin(b·θ)).",
        render: function(ctx, width, height, t, p, toScreen) {
          const aFreq = Math.round(p.a * 2);
          const bFreq = Math.round(p.b * 3);
          const delta = p.omega * t;
          
          ctx.strokeStyle = "#8b5cf6";
          ctx.lineWidth = 2.4;
          ctx.beginPath();
          const steps = 360;
          for (let i = 0; i <= steps; i++) {
            const theta = (i / steps) * Math.PI * 2;
            const x = 3.0 * Math.sin(aFreq * theta + delta);
            const y = 3.0 * Math.sin(bFreq * theta);
            const sc = toScreen(x, y);
            if (i === 0) ctx.moveTo(sc.x, sc.y);
            else ctx.lineTo(sc.x, sc.y);
          }
          ctx.stroke();
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Parametric Frequency Ratio a:b = ${aFreq}:${bFreq} | Phase Shift δ = ${delta.toFixed(2)} rad`, 20, height - 30);
        }
      },

      rose_curves: {
        title: "Polar Rose & Epicycloid Petals",
        desc: "Polar coordinate harmonic function r(θ, t) = a·cos(k·θ + ω·t) generating n-petal flowers.",
        render: function(ctx, width, height, t, p, toScreen) {
          const kPetals = Math.max(1, Math.round(p.k));
          const aAmp = 3.2;
          const phase = p.omega * t * 0.5;
          
          ctx.strokeStyle = "#06b6d4";
          ctx.lineWidth = 2.4;
          ctx.beginPath();
          const steps = 400;
          for (let i = 0; i <= steps; i++) {
            const theta = (i / steps) * Math.PI * 2;
            const r = aAmp * Math.cos(kPetals * theta + phase);
            const x = r * Math.cos(theta);
            const y = r * Math.sin(theta);
            const sc = toScreen(x, y);
            if (i === 0) ctx.moveTo(sc.x, sc.y);
            else ctx.lineTo(sc.x, sc.y);
          }
          ctx.stroke();
          
          ctx.fillStyle = "#f8fafc";
          ctx.font = "11.5px monospace";
          ctx.fillText(`Polar Equation: r = ${aAmp}·cos(${kPetals}θ + ${phase.toFixed(2)}) | Petals = ${kPetals % 2 === 0 ? 2 * kPetals : kPetals}`, 20, height - 30);
        }
      }
    },

    init: function() {
      if (StemVisualizer.initialized) return;
      StemVisualizer.canvas = document.getElementById("stem-viz-canvas");
      if (!StemVisualizer.canvas) return;
      StemVisualizer.ctx = StemVisualizer.canvas.getContext("2d");
      StemVisualizer.modal = document.querySelector("[data-visualizer-modal]");
      StemVisualizer.initialized = true;

      // Mouse drag pan & zoom
      StemVisualizer.canvas.addEventListener("mousedown", (e) => {
        StemVisualizer.view.isDragging = true;
        StemVisualizer.view.dragStartX = e.clientX;
        StemVisualizer.view.dragStartY = e.clientY;
        StemVisualizer.view.origCenterX = StemVisualizer.view.centerX;
        StemVisualizer.view.origCenterY = StemVisualizer.view.centerY;
      });

      window.addEventListener("mousemove", (e) => {
        if (!StemVisualizer.isOpen) return;
        if (StemVisualizer.view.isDragging) {
          StemVisualizer.view.centerX = StemVisualizer.view.origCenterX + (e.clientX - StemVisualizer.view.dragStartX);
          StemVisualizer.view.centerY = StemVisualizer.view.origCenterY + (e.clientY - StemVisualizer.view.dragStartY);
        }
        
        // Coordinate readout
        const rect = StemVisualizer.canvas.getBoundingClientRect();
        if (e.clientX >= rect.left && e.clientX <= rect.right && e.clientY >= rect.top && e.clientY <= rect.bottom) {
          const math = StemVisualizer.toMath(e.clientX - rect.left, e.clientY - rect.top);
          const badge = document.querySelector("[data-viz-coord-badge]");
          if (badge) badge.textContent = `(x: ${math.x.toFixed(2)}, y: ${math.y.toFixed(2)})`;
        }
      });

      window.addEventListener("mouseup", () => {
        StemVisualizer.view.isDragging = false;
      });

      StemVisualizer.canvas.addEventListener("wheel", (e) => {
        e.preventDefault();
        const factor = e.deltaY < 0 ? 1.12 : 0.89;
        StemVisualizer.view.zoom = Math.max(8, Math.min(600, StemVisualizer.view.zoom * factor));
      }, { passive: false });
    },

    renderFrame: function(now) {
      if (!StemVisualizer.isOpen) return;
      
      if (StemVisualizer.anim.isPlaying) {
        if (!StemVisualizer.anim.lastFrame) StemVisualizer.anim.lastFrame = now;
        const dt = (now - StemVisualizer.anim.lastFrame) / 1000;
        StemVisualizer.anim.lastFrame = now;
        
        StemVisualizer.anim.time += dt * StemVisualizer.anim.speed;
        if (StemVisualizer.anim.time > StemVisualizer.anim.maxTime) {
          StemVisualizer.anim.time = 0;
        }
        
        const scrubber = document.querySelector("[data-viz-scrubber]");
        if (scrubber && document.activeElement !== scrubber) {
          scrubber.value = StemVisualizer.anim.time.toFixed(2);
        }
        const timeDisplay = document.querySelector("[data-viz-time-display]");
        if (timeDisplay) {
          timeDisplay.textContent = `t = ${StemVisualizer.anim.time.toFixed(2)} s`;
        }
      } else {
        StemVisualizer.anim.lastFrame = now;
      }
      
      const canvas = StemVisualizer.canvas;
      const ctx = StemVisualizer.ctx;
      if (!canvas || !ctx) return;
      
      const dpr = window.devicePixelRatio || 1;
      const rect = canvas.getBoundingClientRect();
      if (canvas.width !== Math.floor(rect.width * dpr) || canvas.height !== Math.floor(rect.height * dpr)) {
        canvas.width = Math.floor(rect.width * dpr);
        canvas.height = Math.floor(rect.height * dpr);
      }
      
      ctx.save();
      ctx.scale(dpr, dpr);
      const width = rect.width;
      const height = rect.height;
      
      StemVisualizer.drawGrid(ctx, width, height);
      
      const t = StemVisualizer.anim.time;
      const p = StemVisualizer.params;
      
      const activePanel = document.querySelector(".viz-tab-panel:not([hidden])");
      const isCustomTab = activePanel?.dataset.vizPanel === "custom";
      
      if (isCustomTab) {
        StemVisualizer.tracks.forEach(track => {
          if (track.active && track.expr) {
            if (!track.compiled) track.compiled = StemVisualizer.compileExpression(track.expr);
            if (track.compiled) {
              StemVisualizer.drawMathCurve(ctx, (x) => track.compiled(x, t, p.a, p.b, p.c, p.k, p.omega), track.color, 2.4);
            }
          }
        });
      } else if (StemVisualizer.currentTheorem && StemVisualizer.theorems[StemVisualizer.currentTheorem]) {
        StemVisualizer.theorems[StemVisualizer.currentTheorem].render(
          ctx, width, height, t, p, StemVisualizer.toScreen, StemVisualizer.toMath
        );
      }
      
      ctx.restore();
      StemVisualizer.animId = requestAnimationFrame(StemVisualizer.renderFrame);
    },

    open: function(prefillFunc) {
      const modal = document.querySelector("[data-visualizer-modal]");
      if (!modal) return;
      modal.hidden = false;
      StemVisualizer.isOpen = true;
      StemVisualizer.init();
      
      if (prefillFunc) {
        const f1Input = document.querySelector('[data-fn-track="1"]');
        if (f1Input) {
          f1Input.value = prefillFunc;
          StemVisualizer.tracks[0].expr = prefillFunc;
          StemVisualizer.tracks[0].compiled = null;
        }
        const customTab = document.querySelector('[data-viz-tab="custom"]');
        if (customTab) customTab.click();
      }
      
      StemVisualizer.anim.lastFrame = performance.now();
      cancelAnimationFrame(StemVisualizer.animId);
      StemVisualizer.animId = requestAnimationFrame(StemVisualizer.renderFrame);
    },

    close: function() {
      const modal = document.querySelector("[data-visualizer-modal]");
      if (modal) modal.hidden = true;
      StemVisualizer.isOpen = false;
      cancelAnimationFrame(StemVisualizer.animId);
    },

    setTheorem: function(id) {
      if (!StemVisualizer.theorems[id]) return;
      StemVisualizer.currentTheorem = id;
      document.querySelectorAll("[data-load-theorem]").forEach(btn => {
        btn.classList.toggle("is-selected", btn.dataset.loadTheorem === id);
      });
      
      const bannerTitle = document.querySelector("[data-viz-banner-title]");
      const bannerDesc = document.querySelector("[data-viz-banner-desc]");
      if (bannerTitle) bannerTitle.textContent = StemVisualizer.theorems[id].title;
      if (bannerDesc) bannerDesc.textContent = StemVisualizer.theorems[id].desc;
    }
  };

  function focusOmnibar() {
    const input = omnibarInput();
    const dropdown = omnibarDropdown();
    const clearBtn = omnibarClear();
    if (input) {
      input.focus();
      input.select();
      if (dropdown) dropdown.hidden = false;
      if (clearBtn) clearBtn.hidden = !input.value.trim();
      renderOmnibarResults(input.value, omnibarActiveCategory);
    }
  }

  function closeOmnibar() {
    const dropdown = omnibarDropdown();
    if (dropdown) dropdown.hidden = true;
    omnibarActiveIndex = -1;
  }

  function palette() {
    return document.querySelector(".command-palette");
  }

  function paletteInput() {
    return palette()?.querySelector("#palette-search, input") || null;
  }

  function paletteOptions() {
    return Array.from(palette()?.querySelectorAll(".palette-results > button") || []);
  }

  function visiblePaletteOptions() {
    return paletteOptions().filter((option) => !option.hidden && !option.disabled);
  }

  function preparePalette() {
    const node = palette();
    const input = paletteInput();
    const results = node?.querySelector(".palette-results");
    if (!node || !input || !results) return;

    if (!results.id) results.id = "palette-results";
    results.setAttribute("role", "listbox");
    input.setAttribute("role", "combobox");
    input.setAttribute("aria-autocomplete", "list");
    input.setAttribute("aria-controls", results.id);
    input.setAttribute("aria-expanded", String(!node.hidden));

    paletteOptions().forEach((option, index) => {
      if (!option.id) option.id = `centl26-palette-option-${index + 1}`;
      option.setAttribute("role", "option");
      option.setAttribute("aria-selected", "false");
      option.tabIndex = -1;
    });
  }

  function setPaletteActive(index, { scroll = true } = {}) {
    const input = paletteInput();
    const options = visiblePaletteOptions();

    paletteOptions().forEach((option) => {
      option.classList.remove("is-highlighted");
      option.setAttribute("aria-selected", "false");
    });

    if (!input || options.length === 0) {
      paletteActiveIndex = -1;
      input?.removeAttribute("aria-activedescendant");
      return;
    }

    paletteActiveIndex = ((index % options.length) + options.length) % options.length;
    const active = options[paletteActiveIndex];
    active.classList.add("is-highlighted");
    active.setAttribute("aria-selected", "true");
    input.setAttribute("aria-activedescendant", active.id);
    if (scroll) active.scrollIntoView({ block: "nearest" });
  }

  function filterPalette(query) {
    const commandText = query.trim().replace(/^>\s*/, "");
    const normalized = commandText.toLowerCase();
    const tokens = normalized.split(/\s+/).filter(Boolean);
    const results = palette()?.querySelector(".palette-results");
    const runInput = palette()?.querySelector('[data-palette-action="run-input"]');
    const mode = selectedMode.toLowerCase();
    const exactPresetCommand = paletteOptions().some((option) => {
      const preset = option.dataset.command;
      return option !== runInput
        && typeof preset === "string"
        && preset.trim().toLowerCase() === normalized;
    });
    const prioritizeRunInput = Boolean(runInput && commandText && !exactPresetCommand);

    paletteOptions().forEach((option) => {
      if (option === runInput) {
        option.hidden = true;
        return;
      }
      const modes = (option.dataset.modes || "all").toLowerCase().split(/\s+/);
      const matchesMode = selectedMode === "Auto" || modes.includes("all") || modes.includes(mode);
      const searchable = `${option.textContent} ${option.dataset.command || ""} ${option.dataset.paletteAction || ""}`.toLowerCase();
      option.hidden = !matchesMode || tokens.some((token) => !searchable.includes(token));
    });

    if (runInput) {
      runInput.hidden = !prioritizeRunInput;
      const preview = runInput.querySelector("[data-run-input-preview]");
      if (preview) preview.textContent = prioritizeRunInput ? commandText : "";
    }

    if (results) {
      let label = null;
      let groupHasResult = false;
      Array.from(results.children).forEach((child) => {
        if (child.matches("p")) {
          if (label) label.hidden = !groupHasResult;
          label = child;
          groupHasResult = false;
        } else if (child.matches("button") && !child.hidden) {
          groupHasResult = true;
        }
      });
      if (label) label.hidden = !groupHasResult;
    }

    const preferredIndex = prioritizeRunInput
      ? visiblePaletteOptions().indexOf(runInput)
      : 0;
    setPaletteActive(Math.max(preferredIndex, 0), { scroll: false });
  }

  function openPalette(mode = "quick-open") {
    const node = palette();
    const input = paletteInput();
    if (!node || !input) return;

    if (node.hidden) {
      paletteReturnFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    }

    node.hidden = false;
    node.dataset.mode = mode;
    input.placeholder = selectedMode === "Build"
      ? "Search Build status and workspace actions…"
      : selectedMode === "Auto"
      ? (mode === "commands" ? "Run a supported CentL26 command…" : "Search supported tools and commands…")
      : `Search ${selectedMode} commands…`;
    input.value = "";
    input.setAttribute("aria-expanded", "true");
    filterPalette("");
    input.focus({ preventScroll: true });
  }

  function closePalette({ restoreFocus = true } = {}) {
    const node = palette();
    if (!node || node.hidden) return;

    node.hidden = true;
    const input = paletteInput();
    input?.setAttribute("aria-expanded", "false");
    input?.removeAttribute("aria-activedescendant");
    paletteActiveIndex = -1;

    const returnTarget = paletteReturnFocus;
    paletteReturnFocus = null;
    if (restoreFocus && returnTarget?.isConnected) {
      returnTarget.focus({ preventScroll: true });
    }
  }

  function activateInspectorTab(tab, { focus = false } = {}) {
    const inspector = tab.closest(".inspector-pane") || document;
    const selected = tab.dataset.inspectorTab;
    if (!selected) return;
    selectedInspectorTab = selected;
    writeStorage(inspectorTabKey, selected);

    inspector.querySelectorAll("[data-inspector-tab]").forEach((candidate) => {
      const active = candidate === tab;
      candidate.classList.toggle("is-active", active);
      candidate.setAttribute("aria-selected", String(active));
      candidate.tabIndex = active ? 0 : -1;
    });

    inspector.querySelectorAll("[data-inspector-panel]").forEach((panel) => {
      panel.hidden = panel.dataset.inspectorPanel !== selected;
    });

    if (focus) tab.focus({ preventScroll: true });
  }

  function initializeInspectorTabs(root = document) {
    const tabs = Array.from(root.querySelectorAll("[data-inspector-tab]"));
    if (tabs.length === 0) return;
    const selected = tabs.find((tab) => tab.dataset.inspectorTab === selectedInspectorTab)
      || tabs.find((tab) => tab.getAttribute("aria-selected") === "true" || tab.classList.contains("is-active"))
      || tabs[0];
    activateInspectorTab(selected);
  }

  function activateReceipt(button, { focus = false } = {}) {
    const inspector = button.closest(".inspector-pane") || document;
    const target = button.dataset.receiptTarget;
    if (!target) return;

    inspector.querySelectorAll("[data-receipt-target]").forEach((candidate) => {
      const active = candidate === button;
      candidate.classList.toggle("is-selected", active);
      candidate.setAttribute("aria-expanded", String(active));
    });
    inspector.querySelectorAll("[data-receipt-detail]").forEach((detail) => {
      detail.hidden = detail.dataset.receiptDetail !== target;
    });
    if (focus) button.focus({ preventScroll: true });
  }

  function initializeReceipts(root = document) {
    const buttons = Array.from(root.querySelectorAll("[data-receipt-target]"));
    if (buttons.length === 0) return;
    const selected = buttons.find((button) => button.getAttribute("aria-expanded") === "true") || buttons[0];
    activateReceipt(selected);
  }

  function openEvidence() {
    setPaneVisible("inspector", true);
    const evidenceTab = document.querySelector('[data-inspector-tab="evidence"]');
    if (evidenceTab) activateInspectorTab(evidenceTab);
  }

  const WELCOME_QUOTES = [
    ["Good maths should be free.", "Exact rational arithmetic, physics kernels, and offline multi-domain STEM solver."],
    ["The calm scientific workbench for verified computation.", "Think out loud in plain English or compute with exact rational precision."],
    ["Explore the deterministic frontier.", "Instantaneous, offline, and mathematically uncompromised."],
    ["What are you working on today?", "Enter any equation, plot a 2D function, balance a reaction, or synthesize a formula in plain English."],
    ["Exact-first scientific computing.", "Never manufacture mathematical certainty — verified execution receipts every time."]
  ];

  function rotateWelcomeHeadline(root = document) {
    const headline = root.querySelector?.("[data-welcome-headline]");
    const subline = root.querySelector?.("[data-welcome-subline]");
    if (headline && subline) {
      const pick = WELCOME_QUOTES[Math.floor(Math.random() * WELCOME_QUOTES.length)];
      headline.textContent = pick[0];
      subline.textContent = pick[1];
    }
  }

  function initializeWorkspace(root = document) {
    initializeInspectorTabs(root);
    initializeReceipts(root);
    rotateWelcomeHeadline(root);
    selectArea(selectedArea, { openExplorer: selectedArea !== "work", persist: false });
    applyInteractionMode(selectedMode, { persist: false });
    syncComposerActions();
    void hydrateCapabilities(root);
    void hydrateWorkspace(root);
  }

  document.addEventListener("submit", (event) => {
    const geminiForm = event.target.closest("[data-gemini-key-form]");
    if (geminiForm) {
      event.preventDefault();
      const input = geminiForm.querySelector(".gemini-key-input");
      const keyVal = input?.value.trim();
      if (keyVal) {
        execute(new URLSearchParams({
          lab_action: "calculate",
          cmd: `:gemini-key ${keyVal}`,
          interaction_mode: selectedMode
        }), { restoreEditorFocus: false });
        input.value = "";
      }
      return;
    }

    const form = event.target.closest("[data-centl-form]");
    if (!form) return;
    event.preventDefault();
    if (!activeEditor()?.value.trim()) {
      syncComposerActions();
      return;
    }
    execute(encodeForm(form, event.submitter));
  });

  document.addEventListener("click", (event) => {
    if (event.target.matches(".command-palette")) {
      closePalette();
      return;
    }

    const target = event.target.closest("button, [data-open-palette], .tab-close, [data-switch-notebook]");
    if (!target) return;

    if (target.matches("[data-open-palette]")) openPalette();
    if (target.matches("[data-toggle-explorer]")) togglePane("explorer");
    if (target.matches("[data-toggle-inspector]")) togglePane("inspector");
    if (target.matches("[data-toggle-console]")) togglePane("console");
    if (target.dataset.selectArea) {
      selectArea(target.dataset.selectArea, {
        focus: target.dataset.selectArea === "work",
        openExplorer: true
      });
    }
    if (target.matches("[data-open-evidence]")) openEvidence();
    if (target.dataset.receiptTarget) {
      openEvidence();
      activateReceipt(target);
    }

    const modelChip = target.closest(".gemini-model-chip");
    if (modelChip && modelChip.dataset.model) {
      const modelName = modelChip.dataset.model;
      document.querySelectorAll(".gemini-model-chip").forEach((c) => c.classList.remove("is-active"));
      modelChip.classList.add("is-active");
      execute(new URLSearchParams({
        lab_action: "calculate",
        cmd: `:gemini-model ${modelName}`,
        interaction_mode: selectedMode
      }), { restoreEditorFocus: false });
    }

    if (target.matches("[data-gemini-test]")) {
      execute(new URLSearchParams({
        lab_action: "calculate",
        cmd: ":gemini-status",
        interaction_mode: selectedMode
      }), { restoreEditorFocus: false });
    }

    if (target.matches("[data-new-notebook], [data-new-notebook] *")) {
      execute(new URLSearchParams({
        lab_action: "calculate",
        cmd: ":new-notebook",
        interaction_mode: selectedMode
      }), { restoreEditorFocus: true });
    }

    const switchBtn = target.closest("[data-switch-notebook]");
    if (switchBtn && !target.closest("[data-close-notebook]")) {
      const idx = switchBtn.dataset.switchNotebook;
      execute(new URLSearchParams({
        lab_action: "calculate",
        cmd: `:switch-notebook ${idx}`,
        interaction_mode: selectedMode
      }), { restoreEditorFocus: true });
    }

    const closeBtn = target.closest("[data-close-notebook]");
    if (closeBtn) {
      const idx = closeBtn.dataset.closeNotebook;
      if (window.confirm("Close this notebook tab?")) {
        execute(new URLSearchParams({
          lab_action: "calculate",
          cmd: `:close-notebook ${idx}`,
          interaction_mode: selectedMode
        }), { restoreEditorFocus: true });
      }
    }

    if (target.matches("[data-open-help], [data-open-help] *")) {
      const modal = document.querySelector(".help-modal");
      if (modal) modal.hidden = false;
    }

    if (target.matches("[data-close-help], [data-close-help] *") || (target.matches(".help-modal") && !target.closest(".help-dialog"))) {
      const modal = document.querySelector(".help-modal");
      if (modal) modal.hidden = true;
    }

    if (target.matches("[data-run-active]")) {
      const form = activeForm();
      if (form) form.requestSubmit();
    }

    if (target.matches("[data-clear-session]")) {
      clearNotebook();
    }

    if (target.matches("[data-open-fcf-about], [data-open-fcf-about] *")) {
      const modal = document.querySelector(".fcf-about-modal");
      if (modal) modal.hidden = false;
    }

    if (target.matches("[data-close-fcf-about], [data-close-fcf-about] *") || (target.matches(".fcf-about-modal") && !target.closest(".fcf-about-dialog"))) {
      const modal = document.querySelector(".fcf-about-modal");
      if (modal) modal.hidden = true;
    }

    function runUpdateCheck() {
      const modal = document.querySelector(".fcf-update-modal");
      if (modal) modal.hidden = false;

      const spinnerText = document.querySelector("[data-update-status-text]");
      const details = document.querySelector("[data-update-details]");
      const installBtn = document.querySelector("[data-update-install]");
      const spinner = document.querySelector("[data-update-spinner]");

      if (spinner) spinner.hidden = false;
      if (installBtn) installBtn.hidden = true;
      if (spinnerText) spinnerText.textContent = "Checking for available updates...";
      if (details) details.textContent = "Connecting to repository origin and inspecting build tags...";

      const updater = window.webkit?.messageHandlers?.centl26Update;
      if (updater && typeof updater.postMessage === "function") {
        try {
          updater.postMessage({ action: "check" });
        } catch (_) {
          showHostNotice("Automatic updates are available in the CentL26 macOS app.");
        }
      }

      fetch("/api/update")
        .then((r) => r.json())
        .then((data) => {
          if (spinner) spinner.hidden = true;
          if (data.update_available) {
            if (spinnerText) spinnerText.textContent = "⚡ " + data.message;
            if (details) details.textContent = `A newer build (${data.latest_version || "latest"}) is available. Click 'Install Update' to pull and compile in-place.`;
            if (installBtn) {
              installBtn.hidden = false;
              installBtn.textContent = "Install Update";
            }
          } else {
            if (spinnerText) spinnerText.textContent = "✓ " + (data.message || `${data.product} ${data.version} is up to date.`);
            if (details) details.textContent = "You are running the latest release version. Click below to pull and recompile in-place anytime.";
            if (installBtn) {
              installBtn.hidden = false;
              installBtn.textContent = "Rebuild & Sync Now";
            }
          }
        })
        .catch((err) => {
          if (spinner) spinner.hidden = true;
          if (spinnerText) spinnerText.textContent = "Update check failed";
          if (details) details.textContent = String(err);
        });
    }

    if (target.matches("[data-update], [data-update-check]") || target.closest("[data-update], [data-update-check]")) {
      runUpdateCheck();
    }

    if (target.matches("[data-update-install]")) {
      const spinnerText = document.querySelector("[data-update-status-text]");
      const details = document.querySelector("[data-update-details]");
      const installBtn = document.querySelector("[data-update-install]");
      const spinner = document.querySelector("[data-update-spinner]");

      if (spinner) spinner.hidden = false;
      if (installBtn) installBtn.disabled = true;
      if (spinnerText) spinnerText.textContent = "Updating repository & rebuilding CentL26...";
      if (details) details.textContent = "Executing git pull and cargo release compilation in-place. Please wait...";

      fetch("/api/update", { method: "POST" })
        .then((r) => r.json())
        .then((res) => {
          if (spinner) spinner.hidden = true;
          if (spinnerText) spinnerText.textContent = res.message;
          if (res.updated) {
            if (details) details.textContent = "Rebuild completed successfully. Reloading workbench...";
            setTimeout(() => window.location.reload(), 1500);
          } else {
            if (details) details.textContent = "Update could not complete. Check terminal logs for details.";
            if (installBtn) installBtn.disabled = false;
          }
        })
        .catch((err) => {
          if (spinner) spinner.hidden = true;
          if (spinnerText) spinnerText.textContent = "Update build failed";
          if (details) details.textContent = String(err);
          if (installBtn) installBtn.disabled = false;
        });
    }

    if (target.matches("[data-update-close], [data-update-close] *") || (target.matches(".fcf-update-modal") && !target.closest(".fcf-update-dialog"))) {
      const modal = document.querySelector(".fcf-update-modal");
      if (modal) modal.hidden = true;
    }

    if (target.matches("[data-toggle-theme], [data-toggle-theme] *")) {
      toggleTheme();
    }

    if (target.matches("[data-save-project], [data-save-project] *")) {
      runCommand(":save");
    }

    if (target.dataset.paletteAction === "save-project") {
      closePalette({ restoreFocus: false });
      runCommand(":save");
    }

    if (target.dataset.paletteAction === "download-examples") {
      closePalette({ restoreFocus: false });
      window.location.href = "/download/centl26-examples.csv";
    }

    if (target.dataset.paletteAction === "download-notebook") {
      closePalette({ restoreFocus: false });
      window.location.href = "/download/notebook.md";
    }

    if (target.dataset.paletteAction === "download-notebook-json") {
      closePalette({ restoreFocus: false });
      window.location.href = "/download/notebook.json";
    }

    if (target.dataset.paletteAction === "download-project") {
      closePalette({ restoreFocus: false });
      window.location.href = "/download/project.json";
    }

    if (target.dataset.paletteAction === "run-input") {
      const command = paletteInput()?.value.trim().replace(/^>\s*/, "");
      if (command) runCommand(command);
    } else if (target.dataset.command) {
      const interactionMode = interactionModes.has(target.dataset.commandMode)
        ? target.dataset.commandMode
        : selectedMode;
      runCommand(target.dataset.command, { interactionMode });
    }

    if (target.dataset.fill) {
      if (interactionModes.has(target.dataset.interactionMode)) {
        applyInteractionMode(target.dataset.interactionMode);
      }
      const editor = activeEditor();
      if (editor) {
        editor.value = target.dataset.fill;
        editor.focus({ preventScroll: true });
        writeStorage(draftKey, editor.value);
        syncComposerActions();
      }
    }

    if (target.matches("[data-new-computation]")) startNewComputation();

    if (target.matches("[data-focus-cell]")) activeEditor()?.focus({ preventScroll: true });

    if (target.dataset.paletteAction === "new-computation") {
      startNewComputation({ fromPalette: true });
    }

    if (target.dataset.paletteAction === "inspector") {
      closePalette({ restoreFocus: false });
      togglePane("inspector");
    }

    if (target.dataset.paletteAction === "console") {
      closePalette({ restoreFocus: false });
      togglePane("console");
    }

    if (target.dataset.paletteAction === "area-build") {
      closePalette({ restoreFocus: false });
      selectArea("build", { openExplorer: true });
    }

    // Omnibar Category Chips
    if (target.matches("[data-chip]") || target.closest("[data-chip]")) {
      const chip = target.matches("[data-chip]") ? target : target.closest("[data-chip]");
      const cat = chip.dataset.chip;
      if (cat) {
        omnibarActiveCategory = cat;
        document.querySelectorAll("[data-chip]").forEach(c => c.classList.toggle("is-active", c === chip));
        const input = omnibarInput();
        renderOmnibarResults(input ? input.value : "", cat);
      }
    }

    // Omnibar Clear Button
    if (target.matches("[data-omnibar-clear]") || target.closest("[data-omnibar-clear]")) {
      const input = omnibarInput();
      if (input) {
        input.value = "";
        input.focus();
        target.hidden = true;
        renderOmnibarResults("", omnibarActiveCategory);
      }
    }

    // Omnibar Item Selection
    const omniUrlItem = target.closest("[data-omnibar-url]");
    if (omniUrlItem) {
      openInChrome(omniUrlItem.dataset.omnibarUrl);
      return;
    }

    const omniDocItem = target.closest("[data-omnibar-doc]");
    if (omniDocItem) {
      openFcfDoc(omniDocItem.dataset.omnibarDoc);
      return;
    }

    const omniCmdItem = target.closest("[data-omnibar-cmd]");
    if (omniCmdItem) {
      closeOmnibar();
      runCommand(omniCmdItem.dataset.omnibarCmd);
      return;
    }

    // FCF Document Reader Modal Controls
    if (target.matches("[data-doc-close]") || target.closest("[data-doc-close]") || (target.matches(".fcf-doc-modal") && !target.closest(".fcf-doc-dialog"))) {
      closeFcfDoc();
      return;
    }

    if (target.matches("[data-doc-open-chrome]") || target.closest("[data-doc-open-chrome]")) {
      if (activeDoc) {
        openInChrome(`https://scholar.google.com/scholar?q=${encodeURIComponent(activeDoc.title)}`);
      }
      return;
    }

    // Welcome Screen Actions
    if (target.matches("[data-resume-session]") || target.closest("[data-resume-session]")) {
      const startWrap = document.querySelector("[data-start-surface-wrap]");
      const noteWrap = document.querySelector("[data-notebook-wrap]");
      if (startWrap && noteWrap) {
        startWrap.hidden = true;
        noteWrap.hidden = false;
        activeEditor()?.focus({ preventScroll: true });
      } else {
        activeEditor()?.focus({ preventScroll: true });
      }
      return;
    }

    if (target.matches("[data-open-welcome]") || target.closest("[data-open-welcome]")) {
      const startWrap = document.querySelector("[data-start-surface-wrap]");
      const noteWrap = document.querySelector("[data-notebook-wrap]");
      if (startWrap) {
        startWrap.hidden = false;
        if (noteWrap) noteWrap.hidden = true;
        const comp = startWrap.querySelector("#active-command");
        comp?.focus({ preventScroll: true });
      }
      return;
    }

    // STEM Dynamic Visualizer Modal Controls
    if (target.matches("[data-open-visualizer]") || target.closest("[data-open-visualizer]")) {
      StemVisualizer.open();
      return;
    }

    if (target.matches("[data-visualizer-close]") || target.closest("[data-visualizer-close]") || (target.matches(".stem-visualizer-modal") && !target.closest(".stem-visualizer-dialog"))) {
      StemVisualizer.close();
      return;
    }

    const thChip = target.closest("[data-load-theorem]");
    if (thChip) {
      StemVisualizer.setTheorem(thChip.dataset.loadTheorem);
      return;
    }

    const vizTab = target.closest("[data-viz-tab]");
    if (vizTab) {
      const tabName = vizTab.dataset.vizTab;
      document.querySelectorAll("[data-viz-tab]").forEach(t => t.classList.toggle("is-active", t === vizTab));
      document.querySelectorAll("[data-viz-panel]").forEach(p => p.hidden = p.dataset.vizPanel !== tabName);
      return;
    }

    const fnToggle = target.closest("[data-fn-toggle]");
    if (fnToggle) {
      const trackIdx = parseInt(fnToggle.dataset.fnToggle, 10) - 1;
      if (StemVisualizer.tracks[trackIdx]) {
        StemVisualizer.tracks[trackIdx].active = !StemVisualizer.tracks[trackIdx].active;
        fnToggle.classList.toggle("is-active", StemVisualizer.tracks[trackIdx].active);
      }
      return;
    }

    const vizAction = target.closest("[data-viz-action]");
    if (vizAction) {
      const act = vizAction.dataset.vizAction;
      if (act === "export-png") {
        if (StemVisualizer.canvas) {
          const a = document.createElement("a");
          a.download = `centl-stem-graph-${Date.now()}.png`;
          a.href = StemVisualizer.canvas.toDataURL("image/png");
          a.click();
        }
      } else if (act === "reset-view") {
        StemVisualizer.view.centerX = 0;
        StemVisualizer.view.centerY = 0;
        StemVisualizer.view.zoom = 46;
      } else if (act === "play-pause") {
        StemVisualizer.anim.isPlaying = !StemVisualizer.anim.isPlaying;
        vizAction.textContent = StemVisualizer.anim.isPlaying ? "⏯" : "▶";
      } else if (act === "reset-time") {
        StemVisualizer.anim.time = 0;
      }
      return;
    }

    const zoomBtn = target.closest("[data-viz-zoom]");
    if (zoomBtn) {
      const dir = zoomBtn.dataset.vizZoom;
      const factor = dir === "in" ? 1.25 : 0.8;
      StemVisualizer.view.zoom = Math.max(8, Math.min(600, StemVisualizer.view.zoom * factor));
      return;
    }

    // Click outside Omnibar closes dropdown
    if (!target.closest(".header-omnibar")) {
      closeOmnibar();
    }

    if (target.matches("[data-inspector-tab]")) activateInspectorTab(target);
  });

  document.addEventListener("focusin", (event) => {
    if (event.target.matches("[data-omnibar-input]")) {
      focusOmnibar();
    }
  });

  document.addEventListener("pointermove", (event) => {
    const omniItem = event.target.closest(".omnibar-item");
    if (omniItem) {
      const index = parseInt(omniItem.dataset.itemIndex, 10);
      if (!isNaN(index) && index !== omnibarActiveIndex) setOmnibarActiveIndex(index);
    }
    const option = event.target.closest(".palette-results > button");
    if (!option || palette()?.hidden) return;
    const index = visiblePaletteOptions().indexOf(option);
    if (index >= 0 && index !== paletteActiveIndex) setPaletteActive(index, { scroll: false });
  });

  document.addEventListener("input", (event) => {
    if (event.target.matches("[data-omnibar-input]")) {
      const clearBtn = omnibarClear();
      if (clearBtn) clearBtn.hidden = !event.target.value.trim();
      const dropdown = omnibarDropdown();
      if (dropdown) dropdown.hidden = false;
      renderOmnibarResults(event.target.value, omnibarActiveCategory);
    }
    if (event.target.matches("#palette-search")) filterPalette(event.target.value);
    if (event.target.matches("#active-command")) {
      writeStorage(draftKey, event.target.value);
      syncComposerActions();
    }
    if (event.target.matches("[data-fn-track]")) {
      const trackIdx = parseInt(event.target.dataset.fnTrack, 10) - 1;
      if (StemVisualizer.tracks[trackIdx]) {
        StemVisualizer.tracks[trackIdx].expr = event.target.value;
        StemVisualizer.tracks[trackIdx].compiled = null;
      }
    }
    if (event.target.matches("[data-slider]")) {
      const paramName = event.target.dataset.slider;
      const val = parseFloat(event.target.value);
      StemVisualizer.params[paramName] = val;
      const readout = document.querySelector(`[data-slider-val="${paramName}"]`);
      if (readout) readout.textContent = Number.isInteger(val) ? val.toString() : val.toFixed(2);
    }
    if (event.target.matches("[data-viz-scrubber]")) {
      StemVisualizer.anim.time = parseFloat(event.target.value);
    }
  });

  document.addEventListener("change", (event) => {
    const select = event.target.closest(".mode-control select");
    if (select) {
      const mode = select.value || "Auto";
      applyInteractionMode(mode);
    }
    if (event.target.matches("[data-viz-speed]")) {
      StemVisualizer.anim.speed = parseFloat(event.target.value) || 1.0;
    }
  });

  document.addEventListener("keydown", (event) => {
    const primary = event.metaKey || event.ctrlKey;
    const key = event.key.toLowerCase();
    const omnibarDropdownEl = omnibarDropdown();
    const omnibarIsOpen = omnibarDropdownEl && !omnibarDropdownEl.hidden;
    const docModal = document.querySelector("[data-fcf-doc-modal]");
    const docModalIsOpen = docModal && !docModal.hidden;
    const vizModal = document.querySelector("[data-visualizer-modal]");
    const vizModalIsOpen = vizModal && !vizModal.hidden;

    if (vizModalIsOpen && event.key === "Escape") {
      event.preventDefault();
      StemVisualizer.close();
      return;
    }

    if (docModalIsOpen && event.key === "Escape") {
      event.preventDefault();
      closeFcfDoc();
      return;
    }

    if (omnibarIsOpen) {
      if (event.key === "Escape") {
        event.preventDefault();
        closeOmnibar();
        return;
      }
      if (event.key === "ArrowDown" || event.key === "ArrowUp") {
        event.preventDefault();
        setOmnibarActiveIndex(omnibarActiveIndex + (event.key === "ArrowDown" ? 1 : -1));
        return;
      }
      if (event.key === "Enter") {
        event.preventDefault();
        const resultsEl = omnibarResults();
        const active = resultsEl?.querySelector(".omnibar-item.is-highlighted");
        if (active) {
          active.click();
        } else {
          const val = omnibarInput()?.value.trim();
          if (val) {
            openInChrome(`https://scholar.google.com/scholar?q=${encodeURIComponent(val)}`);
          }
        }
        return;
      }
    }

    const paletteIsOpen = palette() && !palette().hidden;
    if (paletteIsOpen) {
      if (event.key === "Escape") {
        event.preventDefault();
        closePalette();
        return;
      }
      if (event.key === "ArrowDown" || event.key === "ArrowUp") {
        event.preventDefault();
        setPaletteActive(paletteActiveIndex + (event.key === "ArrowDown" ? 1 : -1));
        return;
      }
      if (event.key === "Home" || event.key === "End") {
        event.preventDefault();
        setPaletteActive(event.key === "Home" ? 0 : visiblePaletteOptions().length - 1);
        return;
      }
      if (event.key === "Enter") {
        const option = visiblePaletteOptions()[paletteActiveIndex];
        if (option) {
          event.preventDefault();
          option.click();
        }
        return;
      }
    }

    if (primary && !event.altKey && key === "k") {
      event.preventDefault();
      focusOmnibar();
      return;
    }

    if (!primary && event.key === "/" && !["INPUT", "TEXTAREA"].includes(document.activeElement?.tagName)) {
      event.preventDefault();
      focusOmnibar();
      return;
    }

    if (primary && !event.altKey && key === "p") {
      event.preventDefault();
      openPalette(event.shiftKey ? "commands" : "quick-open");
      return;
    }

    if (primary && !event.altKey && key === "b") {
      event.preventDefault();
      togglePane("explorer");
      return;
    }

    if (primary && !event.altKey && key === "j") {
      event.preventDefault();
      togglePane("console");
      return;
    }

    if ((primary && event.shiftKey && key === "n") || (event.altKey && key === "n")) {
      event.preventDefault();
      startNewComputation();
      return;
    }

    if (primary && !event.altKey && key === "s") {
      event.preventDefault();
      runCommand(":save");
      return;
    }

    if (primary && event.key === "Enter") {
      const form = activeForm();
      if (form) {
        event.preventDefault();
        form.requestSubmit();
      }
      return;
    }

    const inspectorTab = event.target.closest?.("[data-inspector-tab]");
    if (inspectorTab && ["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
      const inspector = inspectorTab.closest(".inspector-pane") || document;
      const tabs = Array.from(inspector.querySelectorAll("[data-inspector-tab]"));
      const current = tabs.indexOf(inspectorTab);
      let next = current;
      if (event.key === "ArrowLeft") next = (current - 1 + tabs.length) % tabs.length;
      if (event.key === "ArrowRight") next = (current + 1) % tabs.length;
      if (event.key === "Home") next = 0;
      if (event.key === "End") next = tabs.length - 1;
      event.preventDefault();
      activateInspectorTab(tabs[next], { focus: true });
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.target.matches("[data-rename-notebook]") && event.key === "Enter") {
      event.preventDefault();
      event.target.blur();
    }
  });

  document.addEventListener("focusout", (event) => {
    if (event.target.matches("[data-rename-notebook]")) {
      const newName = (event.target.value !== undefined ? event.target.value : event.target.textContent).trim();
      if (newName) {
        execute(new URLSearchParams({
          lab_action: "calculate",
          cmd: `:rename-notebook ${newName}`,
          interaction_mode: selectedMode
        }), { restoreEditorFocus: false });
      }
    }
  });

  document.addEventListener("change", (event) => {
    if (event.target.matches("[data-rename-notebook]") && event.target.tagName === "INPUT") {
      const newName = event.target.value.trim();
      if (newName) {
        execute(new URLSearchParams({
          lab_action: "calculate",
          cmd: `:rename-notebook ${newName}`,
          interaction_mode: selectedMode
        }), { restoreEditorFocus: false });
      }
    }
  });

  selectedArea = storedChoice(areaKey, areaNames, "work");
  selectedMode = "Auto"; // Always auto-detect mode behind the scenes
  selectedInspectorTab = storedChoice(inspectorTabKey, inspectorTabs, "result");
  preparePalette();
  restoreLayout();
  initializeWorkspace();
  loadFcfDocs();
  const savedTheme = readStorage(themeKey);
  if (savedTheme) applyTheme(savedTheme);

  const editor = activeEditor();
  const draft = readStorage(draftKey);
  if (editor && !editor.value && draft) editor.value = draft;
  syncComposerActions();
})();
