const COOKIE_KEY = "lanttern_accept_cookies";
const ANALYTICS_COOKIE_KEY = "lanttern_analytics_consent";
const MAX_AGE = 24 * 60 * 60 * 365;
const COOKIE_POLICY_DATE = new Date("2026-02-27T00:00:00Z");

const showContainer = (container) => {
  container.classList.remove("hidden");
  container.classList.add("flex");
};

const hideContainer = (container) => {
  container.classList.add("hidden");
};

const updateAnalyticsConsent = (state) => {
  if (typeof gtag === "function") {
    gtag("consent", "update", { analytics_storage: state });
  }
};

const getCookieValue = (key) => {
  return document.cookie
    .split("; ")
    .find((row) => row.startsWith(key + "="))
    ?.split("=")[1];
};

const cookiesHook = {
  mounted() {
    /**
     * Check if there's an accept_cookie cookie newer than COOKIE_POLICY_DATE.
     * If valid, restore analytics consent state and skip showing the banner.
     * Otherwise, show the cookie consent banner.
     */
    const container = this.el;

    const acceptCookieISODateStr = getCookieValue(COOKIE_KEY);

    if (acceptCookieISODateStr) {
      const acceptCookieDate = new Date(acceptCookieISODateStr);
      if (acceptCookieDate > COOKIE_POLICY_DATE) {
        const analyticsConsent = getCookieValue(ANALYTICS_COOKIE_KEY);
        if (analyticsConsent === "granted") {
          updateAnalyticsConsent("granted");
        }
        return;
      }
    }

    // No valid acknowledgment — show the cookie banner

    showContainer(container);

    const acceptAllButton = document.getElementById(
      "accept-all-cookies-button",
    );
    const essentialOnlyButton = document.getElementById(
      "essential-only-cookies-button",
    );

    acceptAllButton.addEventListener("click", () => {
      document.cookie = `${COOKIE_KEY}=${new Date().toISOString()}; max-age=${MAX_AGE}; Secure`;
      document.cookie = `${ANALYTICS_COOKIE_KEY}=granted; max-age=${MAX_AGE}; Secure`;
      updateAnalyticsConsent("granted");
      hideContainer(container);
    });

    essentialOnlyButton.addEventListener("click", () => {
      document.cookie = `${COOKIE_KEY}=${new Date().toISOString()}; max-age=${MAX_AGE}; Secure`;
      document.cookie = `${ANALYTICS_COOKIE_KEY}=denied; max-age=${MAX_AGE}; Secure`;
      hideContainer(container);
    });
  },
};

export default cookiesHook;
