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
  // force visible input value change
  input.value = selected.name;

  // force hidden input value change and trigger phx-change event
  const hiddenInput = document.getElementById(
    input.getAttribute("data-hidden-input-id")
  );
  hiddenInput.value = selected.id;
  hiddenInput.dispatchEvent(new Event("input", { bubbles: true }));

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
  let input = this.el;
  let controlId = input.getAttribute("aria-controls");
  let controls = document.getElementById(controlId);

  // on li mouseenter
  let activateLi = (event) => {
    setActive(event.target.id, input, controls);
  };

  // on li click
  let selectLi = (event) => {
    let targetParentLi = event.target.closest("li");
    let selected = {
      id: targetParentLi.getAttribute("data-result-id"),
      name: targetParentLi.getAttribute("data-result-name"),
    };

    // send event to liveview server
    pushSelect(this, input, selected);
  };

  if (event.detail.results.length > 0) {
    setActive(`results-${event.detail.results[0].id}`, input, controls);

    controls.querySelectorAll("li").forEach((li) => {
      li.addEventListener("mouseenter", activateLi);
      li.addEventListener("click", selectLi);
    });
  }
}

function removeCurriculumItem(event) {
  let input = this.el;

  // force hidden input value change and trigger phx-change event
  const hiddenInput = document.getElementById(
    input.getAttribute("data-hidden-input-id")
  );
  hiddenInput.value = "";
  hiddenInput.dispatchEvent(new Event("input", { bubbles: true }));
}

// on click away
function clickAwayHandler(event) {
  let input = this.el;
  let controlId = input.getAttribute("aria-controls");
  let controls = document.getElementById(controlId);

  if (
    event.target.id !== input.id &&
    !event.target.closest(`#${controls.id}`)
  ) {
    hideControls(input);
  }
}

// on keydown
function keydownHandler(event) {
  let input = this.el;
  let controlId = input.getAttribute("aria-controls");
  let controls = document.getElementById(controlId);
  let list = controls.querySelectorAll("li");
  let isShowing = input.getAttribute("aria-expanded") === "true";
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
      let active = document.getElementById(activeDescendantId);
      let selected = {
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
        let newActiveDescendantId = list[indexOfActive + 1].id;
        setActive(newActiveDescendantId, input, controls);
      } else if (
        indexOfActive !== -1 &&
        event.keyCode === 38 &&
        indexOfActive > 0
      ) {
        let newActiveDescendantId = list[indexOfActive - 1].id;
        setActive(newActiveDescendantId, input, controls);
      }
    }
  }
}

const autocompleteHook = {
  mounted() {
    window.addEventListener(
      "phx:autocomplete_search_results",
      autocompleteSearchResults.bind(this)
    );

    window.addEventListener(
      "phx:remove_curriculum_item",
      removeCurriculumItem.bind(this)
    );

    window.addEventListener("click", clickAwayHandler.bind(this));

    this.el.addEventListener("keydown", keydownHandler.bind(this));
  },
};

export default autocompleteHook;
