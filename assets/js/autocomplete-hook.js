// use this map with hook element ids as keys to keep track of abort controllers,
// which should be used to clean event listeners on destroyed() callback
const hookAbortControllerMap = {};

const showControls = (input) => {
  if (input) {
    input.setAttribute("aria-expanded", "true");
  }
};

const hideControls = (input) => {
  if (input) {
    input.setAttribute("aria-expanded", "false");
  }
};

const pushSelect = (hook, input, selected) => {
  if (input.getAttribute("data-refocus-on-select") === "true") {
    // clear input
    input.value = "";
    input.focus()
  } else {
    // force visible input value change
    input.value = selected.name;
  }

  // send event to liveview server
  hook.pushEventTo(input, "autocomplete_result_select", selected);
};

const setActive = (activeId, input, controls) => {
  // set `aria-activedescendant` to the id of the active option
  if (input) {
    input.setAttribute("aria-activedescendant", activeId);
    showControls(input);
  }

  // set `data-active` attr to each option
  if (controls) {
    controls.querySelectorAll("li").forEach((li) => {
      let isActive = "false";
      if (li.id == activeId) {
        isActive = "true";
      }
      li.setAttribute("data-active", isActive);
    });
  }
};

function autocompleteSearchResults(event) {
  const input = this.el;
  const controlId = input.getAttribute("aria-controls");
  const controls = document.getElementById(controlId);

  // on li mouseenter
  const activateLi = (event) => {
    setActive(event.target.id, input, controls);
  };

  // on li click
  const selectLi = (event) => {
    const targetParentLi = event.target.closest("li");
    const selected = {
      id: targetParentLi.getAttribute("data-result-id"),
      name: targetParentLi.getAttribute("data-result-name"),
    };

    // send event to liveview server
    pushSelect(this, input, selected);
  };

  if (event.detail.results.length > 0) {
    setActive(`results-${event.detail.results[0].id}`, input, controls);

    controls.querySelectorAll("li").forEach((li) => {
      li.addEventListener("mouseenter", activateLi, {
        signal: hookAbortControllerMap[input.id].signal,
      });
      li.addEventListener("click", selectLi, {
        signal: hookAbortControllerMap[input.id].signal,
      });
    });
  }
}

// on click away
function clickAwayHandler(event) {
  const input = this.el;
  const controlId = input.getAttribute("aria-controls");
  const controls = document.getElementById(controlId);

  if (
    event.target.id !== input.id &&
    !event.target.closest(`#${controls.id}`)
  ) {
    hideControls(input);
  }
}

// on keydown
function keydownHandler(event) {
  const input = this.el;
  const controlId = input.getAttribute("aria-controls");
  const controls = document.getElementById(controlId);
  const list = controls.querySelectorAll("li");
  const isShowing = input.getAttribute("aria-expanded") === "true";
  let activeDescendantId = input.getAttribute("aria-activedescendant");

  // handle Escape
  if (event.keyCode === 27) {
    hideControls(input);
    return;
  }

  // handle select with Enter keydown
  if (event.keyCode === 13) {
    event.preventDefault();
    // if controls are visible and there's a active descendant, select it
    if (isShowing && activeDescendantId) {
      const active = document.getElementById(activeDescendantId);
      const selected = {
        id: active.getAttribute("data-result-id"),
        name: active.getAttribute("data-result-name"),
      };

      // send event to liveview server
      pushSelect(this, input, selected);
    }
    return;
  }

  // handle arrows keydown
  if (event.keyCode === 40 || event.keyCode === 38) {
    event.preventDefault();

    // if controls are hidden and list is not empty, check activedescendant and show controls
    if (!isShowing && list.length > 0) {
      if (!activeDescendantId) {
        activeDescendantId = list[0].id;
      }
      setActive(activeDescendantId, input, controls);
      return;
    }

    // if controls are visible and there's a active descendant, handle arrow navigation
    if (isShowing && activeDescendantId && list.length > 0) {
      let indexOfActive;

      list.forEach((li, i) => {
        if (li.id === activeDescendantId) indexOfActive = i;
      });

      if (
        indexOfActive !== -1 &&
        event.keyCode === 40 &&
        indexOfActive < list.length - 1
      ) {
        const newActiveDescendantId = list[indexOfActive + 1].id;
        setActive(newActiveDescendantId, input, controls);
      } else if (
        indexOfActive !== -1 &&
        event.keyCode === 38 &&
        indexOfActive > 0
      ) {
        const newActiveDescendantId = list[indexOfActive - 1].id;
        setActive(newActiveDescendantId, input, controls);
      }
    }
  }
}

const autocompleteHook = {
  mounted() {
    const id = this.el.id
    hookAbortControllerMap[id] = new AbortController();
    window.addEventListener(
      `phx:autocomplete_search_results:${id}`,
      autocompleteSearchResults.bind(this),
      { signal: hookAbortControllerMap[this.el.id].signal }
    );

    window.addEventListener("click", clickAwayHandler.bind(this), {
      signal: hookAbortControllerMap[this.el.id].signal,
    });

    this.el.addEventListener("keydown", keydownHandler.bind(this), {
      signal: hookAbortControllerMap[this.el.id].signal,
    });
  },
  destroyed() {
    hookAbortControllerMap[this.el.id].abort();
  },
};

export default autocompleteHook;
