const handleButtonClick = (event, menu, liveSocket) => {
  // event.preventDefault();
  setTimeout(() => {
    liveSocket.execJS(menu, menu.getAttribute("data-open"));
  }, 1)
};

const handleButtonKeydown = (event, menu, liveSocket) => {
  // (enter and space already work without any extra JS)

  // handle up and down arrows keydown
  // for now, just exec "data-open", which will open the menu and focus on first item.
  // in the future, arrow up should focus the last menu item
  if (event.keyCode === 40 || event.keyCode === 38) {
    event.preventDefault();
    liveSocket.execJS(menu, menu.getAttribute("data-open"));
  }
};

const handleItemKeydown = (event, items, menu, liveSocket) => {
  // handle tab
  if (event.keyCode === 9) {
    liveSocket.execJS(menu, menu.getAttribute("data-close"));
  }

  // handle arrows keydown
  if (event.keyCode === 40 || event.keyCode === 38) {
    event.preventDefault();

    const currentIndex = Array.from(items).indexOf(event.target);

    let nextIndex;

    // 38 up arrow / 40 down arrow
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
    // if (item.id === event.target.id) {
    if (item === event.target) {
      item.setAttribute("tabindex", "0");
      item.focus();
    } else {
      item.setAttribute("tabindex", "-1");
    }
  });
};

const dropdownMenuHook = {
  mounted() {
    const menu = this.el;
    const button = document.querySelector(`#${menu.getAttribute("aria-labelledby")}`);
    const items = menu.querySelectorAll("[role=\"menuitem\"]");

    /**
     * `<.dropdown_menu>` component responsibilities:
     *
     * - provide menu visibility functions on button interaction via JS.show/hide on data-open/close attrs,
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
          } else {
            items.forEach((item) => {
              item.setAttribute("tabindex", "-1");
            });
          }
        }
      }
    });

    // Start observing the target node for configured mutations
    observer.observe(menu, { attributes: true });

    // Button setup
    // 1. add aria-haspopup="true"
    // 2. add aria-controls="dropdown-id"
    // 3. add click listener to button
    button.setAttribute("aria-haspopup", "true");
    button.setAttribute("aria-controls", menu.id);
    button.addEventListener("click", (event) => {
      handleButtonClick(event, menu, this.liveSocket);
    });

    // Add keyboard listener to button
    button.addEventListener("keydown", (event) => {
      handleButtonKeydown(event, menu, this.liveSocket);
    });

    // Add menu items listeners
    for (const item of items) {
      item.addEventListener("keydown", (event) => {
        handleItemKeydown(event, items, menu, this.liveSocket);
      });

      item.addEventListener("mouseenter", (event) => {
        handleItemMouseEnter(event, items);
      });
    }
  },
};

export default dropdownMenuHook;
