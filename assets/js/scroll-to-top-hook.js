/**
 * Scrolls the element to top on element mount.
 * 
 * Useful for elements rendering toggle via `:if` attr.
 * 
 */

const scrollToTopHook = {
  mounted() {
    const selector = this.el.getAttribute("data-scroll-to-selector");

    // use setTimeout to wait for content loading before scrolling
    setTimeout(() => {
      if (selector) {
        document.querySelector(selector).scrollTo({ top: 0 });
      } else {
        window.scrollTo({ top: 0 });
      }
    }, 10);
  },
};

export default scrollToTopHook;
