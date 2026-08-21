(() => {
  "use strict";

  const storageKey = "centl26:26.0:layout:v1";
  const draftKey = "centl26:26.0:draft:v1";
  const paneClasses = {
    explorer: "hide-explorer",
    inspector: "hide-inspector",
    console: "hide-console"
  };

  let paletteReturnFocus = null;
  let paletteActiveIndex = -1;

  function workspace() {
    return document.querySelector(".workbench-shell");
  }

  function activeForm() {
    return document.querySelector(".active-cell[data-centl-form]");
  }

  function activeEditor() {
    return document.querySelector("#active-command");
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

  function togglePane(name) {
    const className = paneClasses[name];
    if (!className) return;
    document.body.classList.toggle(className);
    saveLayout();
    syncLayoutControls();
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
      preparePalette();
      initializeInspectorTabs(next);
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

  function runCommand(command) {
    closePalette({ restoreFocus: false });
    execute(new URLSearchParams({ lab_action: "calculate", cmd: command }));
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
    return paletteOptions().filter((option) => !option.hidden);
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
    const normalized = query.trim().toLowerCase().replace(/^>\s*/, "");
    const tokens = normalized.split(/\s+/).filter(Boolean);
    const results = palette()?.querySelector(".palette-results");

    paletteOptions().forEach((option) => {
      const searchable = `${option.textContent} ${option.dataset.command || ""} ${option.dataset.paletteAction || ""}`.toLowerCase();
      option.hidden = tokens.some((token) => !searchable.includes(token));
    });

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

    setPaletteActive(0, { scroll: false });
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
    input.placeholder = mode === "commands" ? "Run a CentL26 command…" : "Search tools, commands, files, and settings…";
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
    const selected = tabs.find((tab) => tab.getAttribute("aria-selected") === "true" || tab.classList.contains("is-active")) || tabs[0];
    activateInspectorTab(selected);
  }

  document.addEventListener("submit", (event) => {
    const form = event.target.closest("[data-centl-form]");
    if (!form) return;
    event.preventDefault();
    execute(encodeForm(form, event.submitter));
  });

  document.addEventListener("click", (event) => {
    if (event.target.matches(".command-palette")) {
      closePalette();
      return;
    }

    const target = event.target.closest("button, [data-open-palette]");
    if (!target) return;

    if (target.matches("[data-open-palette]")) openPalette();
    if (target.matches("[data-toggle-explorer]")) togglePane("explorer");
    if (target.matches("[data-toggle-inspector]")) togglePane("inspector");
    if (target.matches("[data-toggle-console]")) togglePane("console");

    if (target.matches("[data-run-active]")) {
      const form = activeForm();
      if (form) form.requestSubmit();
    }

    if (target.dataset.command) runCommand(target.dataset.command);

    if (target.dataset.fill) {
      const editor = activeEditor();
      if (editor) {
        editor.value = target.dataset.fill;
        editor.focus({ preventScroll: true });
        writeStorage(draftKey, editor.value);
      }
    }

    if (target.matches(".toolbar-button") && target.textContent.includes("New cell")) {
      const editor = activeEditor();
      if (editor) {
        editor.value = "";
        removeStorage(draftKey);
        editor.focus({ preventScroll: true });
      }
    }

    if (target.matches("[data-focus-cell]")) activeEditor()?.focus({ preventScroll: true });

    if (target.dataset.paletteAction === "focus") {
      closePalette({ restoreFocus: false });
      activeEditor()?.focus({ preventScroll: true });
    }

    if (target.dataset.paletteAction === "inspector") {
      closePalette({ restoreFocus: false });
      togglePane("inspector");
    }

    if (target.dataset.paletteAction === "console") {
      closePalette({ restoreFocus: false });
      togglePane("console");
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
    if (event.target.matches("#active-command")) writeStorage(draftKey, event.target.value);
  });

  document.addEventListener("change", (event) => {
    const select = event.target.closest(".mode-control select");
    if (!select) return;
    const mode = select.value || "Auto";
    const composerMode = document.querySelector(".composer-mode");
    if (composerMode) {
      const label = composerMode.querySelector("span");
      if (label) label.textContent = mode;
    }
    if (mode !== "Auto") {
      openPalette("quick-open");
      const input = paletteInput();
      if (input) {
        input.value = mode;
        filterPalette(mode);
      }
    }
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

  preparePalette();
  initializeInspectorTabs();
  restoreLayout();

  const editor = activeEditor();
  const draft = readStorage(draftKey);
  if (editor && !editor.value && draft) editor.value = draft;
})();
