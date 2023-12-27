const handleIntersect = (navLinks) => (entries, observer) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      for (const navLink of navLinks) {
        if (navLink.getAttribute('href') === `#${entry.target.id}`) {
          navLink.setAttribute('aria-current', 'true')
        } else {
          navLink.setAttribute('aria-current', 'false')
        }
      }
    }
  });
}

const navScrollspyHook = {
  mounted() {
    // this hook is expected to be used in a <nav> component.
    // it will use all of it's children links href as the intersection observer targets
    const navEl = this.el
    const navLinks = document.querySelectorAll(`${navEl.id} a`)

    const options = {
      root: null,
      rootMargin: "0px",
      threshold: 0.5,
    };

    const observer = new IntersectionObserver(handleIntersect(navLinks), options);

    for (const navLink of navLinks) {
      const elementId = navLink.getAttribute('href').replace('#', '')
      const target = document.getElementById(elementId)
      observer.observe(target)
    }
  },
};

export default navScrollspyHook;
