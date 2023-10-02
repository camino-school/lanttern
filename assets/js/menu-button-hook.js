const handleItemKeydown = (event, items) => {
  // handle arrows keydown
  if (event.keyCode === 40 || event.keyCode === 38) {
    event.preventDefault();

    const currentIndex = Array.from(items).indexOf(event.target);

    let nextIndex;

    // 38 = up, 40 = down
    if (event.keyCode === 40) {
      if (items.length > currentIndex + 1) nextIndex = currentIndex + 1;
      else nextIndex = 0;
    } else {
      if (currentIndex === 0) nextIndex = items.length - 1;
      else nextIndex = currentIndex - 1;
    }

    items.forEach((item, i) => {
      if (i === nextIndex) {
        item.setAttribute("tabindex", "0");
        item.focus();
      } else {
        item.setAttribute("tabindex", "-1");
      }
    });
  }
};

const handleItemMouseEnter = (event, items) => {
  items.forEach((item) => {
    if (item.id === event.target.id) {
      item.setAttribute("tabindex", "0");
      item.focus();
    } else {
      item.setAttribute("tabindex", "-1");
    }
  });
};

const menuButtonHook = {
  mounted() {
    const button = this.el;
    const menu = document.querySelector(`[aria-labelledby=${button.id}]`);
    const items = document.querySelectorAll(`#${menu.id} [role="menuitem"]`);

    /**
     * `<.menu_button>` component responsibilities:
     *
     * - manage menu visibility on button interaction via JS.show/hide,
     * - manage `aria-expanded` button attribute, which this hook relies on to triger open and close actions
     */

    const observer = new MutationObserver((mutationList, observer) => {
      for (const mutation of mutationList) {
        if (
          mutation.type === "attributes" &&
          mutation.attributeName == "aria-expanded"
        ) {
          if (mutation.target.getAttribute("aria-expanded")) {
            const [firstItem, ...otherItems] = items;
            firstItem.setAttribute("tabindex", "0");
            firstItem.focus();
          }
        }
      }
    });

    // Start observing the target node for configured mutations
    observer.observe(button, { attributes: true });

    // Add keyboard listener to menu items
    for (const item of items) {
      item.addEventListener("keydown", (event) => {
        handleItemKeydown(event, items);
      });

      item.addEventListener("mouseenter", (event) => {
        handleItemMouseEnter(event, items);
      });
    }
  },
};

export default menuButtonHook;
