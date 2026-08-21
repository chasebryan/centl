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

    if (target.matches("[data-inspector-tab]")) activateInspectorTab(target);
  });

  document.addEventListener("pointermove", (event) => {
    const option = event.target.closest(".palette-results > button");
    if (!option || palette()?.hidden) return;
    const index = visiblePaletteOptions().indexOf(option);
    if (index >= 0 && index !== paletteActiveIndex) setPaletteActive(index, { scroll: false });
  });

  document.addEventListener("input", (event) => {
    if (event.target.matches("#palette-search")) filterPalette(event.target.value);
    if (event.target.matches("#active-command")) {
      writeStorage(draftKey, event.target.value);
      syncComposerActions();
    }
  });

  document.addEventListener("change", (event) => {
    const select = event.target.closest(".mode-control select");
    if (!select) return;
    const mode = select.value || "Auto";
    applyInteractionMode(mode);
  });

  document.addEventListener("keydown", (event) => {
    const primary = event.metaKey || event.ctrlKey;
    const key = event.key.toLowerCase();
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

    if (primary && !event.altKey && key === "p") {
      event.preventDefault();
      openPalette(event.shiftKey ? "commands" : "quick-open");
      return;
    }

    if (primary && !event.altKey && key === "k") {
      event.preventDefault();
      openPalette("quick-open");
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
  const savedTheme = readStorage(themeKey);
  if (savedTheme) applyTheme(savedTheme);

  const editor = activeEditor();
  const draft = readStorage(draftKey);
  if (editor && !editor.value && draft) editor.value = draft;
  syncComposerActions();
})();
