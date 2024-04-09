const COOKIE_KEY = "lanttern_accept_cookies"
const MAX_AGE = 24 * 60 * 60 * 365
const COOKIE_POLICY_DATE = new Date("2024-04-01T00:00:00Z")

const showContainer = (container) => {
  container.classList.remove("hidden")
  container.classList.add("flex")
}

const hideContainer = (container) => {
  container.classList.add("hidden")
}

const cookiesHook = {
  mounted() {
    /**
     * check if there's an accept_cookie cookie
     * newer than COOKIE_POLICY_DATE.
     * 
     * if not, show the cookie panel
     */
    const container = this.el;

    const acceptCookieISODateStr = document.cookie
      .split("; ")
      .find((row) => row.startsWith(COOKIE_KEY))
      ?.split("=")[1];

    if (acceptCookieISODateStr) {
      const acceptCookieDate = new Date(acceptCookieISODateStr)
      if (acceptCookieDate > COOKIE_POLICY_DATE) return
    }

    // accept_cookie not valid, show cookie panel

    showContainer(container)

    const acceptCookiesButton = document.getElementById("accept-cookies-button");

    acceptCookiesButton.addEventListener("click", (e) => {
      document.cookie = `${COOKIE_KEY}=${new Date().toISOString()}; max-age=${MAX_AGE}; Secure`
      hideContainer(container)
    });
  },
};

export default cookiesHook;
