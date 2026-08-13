(() => {
  "use strict";

  const root = document.querySelector("[data-caravan-census]");
  if (!root) return;

  const active = root.querySelector("[data-census-active]");
  const hungry = root.querySelector("[data-census-hungry]");
  const lost = root.querySelector("[data-census-lost]");
  const status = root.querySelector("[data-census-status]");
  const endpoint = "/pub/centl/caravan/lead-census-v1.json";

  const setUnavailable = (message) => {
    active.textContent = "—";
    hungry.textContent = "—";
    lost.textContent = "—";
    status.textContent = message;
  };

  const render = (data) => {
    if (
      !data ||
      data.schema !== "fcf-caravan-lead-census-v1" ||
      data.status !== "live" ||
      !Number.isSafeInteger(data.active_camels) ||
      data.active_camels < 0 ||
      !Number.isSafeInteger(data.hungry_camels) ||
      data.hungry_camels < 0 ||
      !Number.isSafeInteger(data.lost_camels) ||
      data.lost_camels < 0 ||
      typeof data.generated_at !== "string" ||
      !Number.isSafeInteger(data.active_window_seconds) ||
      data.active_window_seconds <= 0
    ) {
      setUnavailable("Census not live yet");
      return;
    }

    const generated = new Date(data.generated_at);
    if (Number.isNaN(generated.getTime())) {
      setUnavailable("Census metadata unavailable");
      return;
    }

    const age = Date.now() - generated.getTime();
    if (age > data.active_window_seconds * 1000) {
      active.textContent = "0";
      hungry.textContent = "1";
      lost.textContent = "0";
      status.textContent = "The lead-census data is stale; the camel is treated as hungry until a fresh probe arrives.";
      return;
    }

    active.textContent = String(data.active_camels);
    hungry.textContent = String(data.hungry_camels);
    lost.textContent = String(data.lost_camels);
    status.textContent = `Updated ${generated.toLocaleString()}. Active means the X200 lead origin passed the latest Tor probe; Lost means the latest probe could not reach it.`;
  };

  const refresh = async () => {
    try {
      const response = await fetch(endpoint, {
        cache: "no-store",
        credentials: "omit",
        referrerPolicy: "no-referrer",
      });
      if (!response.ok) {
        setUnavailable("Census not live yet");
        return;
      }
      render(await response.json());
    } catch (_error) {
      setUnavailable("Census not live yet");
    }
  };

  setUnavailable("Census not live yet");
  void refresh();
  window.setInterval(refresh, 60_000);
})();
