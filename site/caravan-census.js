(() => {
  "use strict";

  const root = document.querySelector("[data-caravan-census]");
  if (!root) return;

  const active = root.querySelector("[data-census-active]");
  const lost = root.querySelector("[data-census-lost]");
  const status = root.querySelector("[data-census-status]");
  const endpoint = "/pub/centl/caravan/census-v1.json";

  const setUnavailable = (message) => {
    active.textContent = "—";
    lost.textContent = "—";
    status.textContent = message;
  };

  const render = (data) => {
    if (
      !data ||
      data.schema !== "fcf-caravan-census-v1" ||
      data.status !== "live" ||
      !Number.isSafeInteger(data.active_camels) ||
      data.active_camels < 0 ||
      !Number.isSafeInteger(data.lost_camels) ||
      data.lost_camels < 0 ||
      typeof data.generated_at !== "string"
    ) {
      setUnavailable("Census not live yet");
      return;
    }

    const generated = new Date(data.generated_at);
    if (Number.isNaN(generated.getTime())) {
      setUnavailable("Census metadata unavailable");
      return;
    }

    active.textContent = String(data.active_camels);
    lost.textContent = String(data.lost_camels);
    status.textContent = `Updated ${generated.toLocaleString()}. Active means a valid heartbeat within the published active window; Lost means beyond the loss threshold without withdrawal.`;
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
