function getAllRows(containerEl) {
  return Array.from(
    containerEl.closest("[data-grid-row]")?.parentElement?.querySelectorAll("[data-grid-row]") || []
  );
}

function getCellsInRow(rowEl) {
  return Array.from(rowEl.querySelectorAll("[data-grid-cell]"));
}

function getCellContainer(cellWrapperEl) {
  return cellWrapperEl.querySelector("[phx-hook='EntryCell']");
}

function findAdjacentContainer(containerEl, direction) {
  const rowEl = containerEl.closest("[data-grid-row]");
  if (!rowEl) return null;
  const allRows = getAllRows(containerEl);
  const rowIndex = allRows.indexOf(rowEl);
  const cells = getCellsInRow(rowEl);
  const colIndex = cells.indexOf(containerEl.closest("[data-grid-cell]"));
  if (rowIndex === -1 || colIndex === -1) return null;

  if (direction === "up" && rowIndex > 0) {
    const prevCells = getCellsInRow(allRows[rowIndex - 1]);
    return getCellContainer(prevCells[Math.min(colIndex, prevCells.length - 1)]);
  }
  if (direction === "down" && rowIndex < allRows.length - 1) {
    const nextCells = getCellsInRow(allRows[rowIndex + 1]);
    return getCellContainer(nextCells[Math.min(colIndex, nextCells.length - 1)]);
  }
  if (direction === "left" && colIndex > 0) {
    return getCellContainer(cells[colIndex - 1]);
  }
  if (direction === "right" && colIndex < cells.length - 1) {
    return getCellContainer(cells[colIndex + 1]);
  }
  return null;
}

function findRowWrapTarget(containerEl, shiftKey) {
  const rowEl = containerEl.closest("[data-grid-row]");
  if (!rowEl) return null;
  const allRows = getAllRows(containerEl);
  const rowIndex = allRows.indexOf(rowEl);
  const cells = getCellsInRow(rowEl);
  const colIndex = cells.indexOf(containerEl.closest("[data-grid-cell]"));

  if (!shiftKey && colIndex === cells.length - 1 && rowIndex < allRows.length - 1) {
    const nextCells = getCellsInRow(allRows[rowIndex + 1]);
    return nextCells[0] ? getCellContainer(nextCells[0]) : null;
  }
  if (shiftKey && colIndex === 0 && rowIndex > 0) {
    const prevCells = getCellsInRow(allRows[rowIndex - 1]);
    return prevCells.length ? getCellContainer(prevCells[prevCells.length - 1]) : null;
  }
  return null;
}

const isMac = /Mac|iPhone|iPad|iPod/.test(navigator.platform || "");

const EntryCellHook = {
  mounted() {
    this._mode = "cell";
    this._inner = this.el.querySelector("select, input");
    this._list = this.el.querySelector("[data-ordinal-list]");
    this._activeItem = null;

    if (this._inner) this._inner.tabIndex = -1;

    this._onCellMousedown = (e) => {
      if (e.target.closest("button")) return;
      if (this._mode === "cell") {
        e.preventDefault();
        this.el.focus();
      }
    };

    this._onCellDblclick = (e) => {
      if (e.target.closest("button")) return;
      if (this._mode !== "input") this._enterInput();
    };

    this._onCellKeydown = (e) => {
      if (e.target !== this.el) return;

      // list-open mode (ordinal picker)
      if (this._list && !this._list.classList.contains("hidden")) {
        const items = Array.from(this._list.querySelectorAll("[data-ordinal-item]"));
        const idx = items.indexOf(this._activeItem);

        if (e.key === "ArrowDown") {
          e.preventDefault();
          this._setActiveItem(items[Math.min(idx + 1, items.length - 1)]);
          return;
        }
        if (e.key === "ArrowUp") {
          e.preventDefault();
          this._setActiveItem(items[Math.max(idx - 1, 0)]);
          return;
        }
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          this._closeList(true);
          const below = findAdjacentContainer(this.el, "down");
          below ? below.focus() : this.el.focus();
          return;
        }
        if (e.key === "Escape") {
          e.preventDefault();
          this._closeList(false);
          this.el.focus();
          return;
        }
        if (e.key === "Tab") {
          e.preventDefault();
          this._closeList(true);
          const wrap = findRowWrapTarget(this.el, e.shiftKey);
          const adjacent = findAdjacentContainer(this.el, e.shiftKey ? "left" : "right");
          const target = wrap || adjacent;
          target ? target.focus() : this.el.focus();
          return;
        }
        return; // swallow all other keys while list is open
      }

      // cell mode
      const mod = isMac ? e.metaKey : e.ctrlKey;

      if (mod && e.key === "d") {
        e.preventDefault();
        this.pushEventTo(this.el, "view_details", {});
        return;
      }
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        this._enterInput();
        return;
      }
      if (e.key === "Delete" || e.key === "Backspace") {
        e.preventDefault();
        this._clearAndEnterInput();
        return;
      }
      if (/^[0-9]$/.test(e.key) && this.el.dataset.scaleType === "numeric") {
        e.preventDefault();
        this._enterInput(e.key);
        return;
      }
      const arrowDir = {
        ArrowUp: "up",
        ArrowDown: "down",
        ArrowLeft: "left",
        ArrowRight: "right",
      }[e.key];
      if (arrowDir) {
        e.preventDefault();
        findAdjacentContainer(this.el, arrowDir)?.focus();
        return;
      }
      if (e.key === "Tab") {
        const wrap = findRowWrapTarget(this.el, e.shiftKey);
        if (wrap) {
          e.preventDefault();
          wrap.focus();
        }
        // else: native Tab navigates to next cell div naturally
      }
    };

    this._onInputKeydown = (e) => {
      const mod = isMac ? e.metaKey : e.ctrlKey;
      if (mod && e.key === "d") {
        e.preventDefault();
        this.pushEventTo(this.el, "view_details", {});
        return;
      }
      if (e.key === "Escape") {
        e.preventDefault();
        this._exitInput(true);
        return;
      }
      if (e.key === "Enter") {
        if (this._inner.tagName === "SELECT") {
          // Let the select confirm the selection natively, then exit and move down
          setTimeout(() => {
            this._exitInput(false);
            const below = findAdjacentContainer(this.el, "down");
            below ? below.focus() : this.el.focus();
          }, 0);
        } else {
          // Prevent form submission, exit and navigate down
          e.preventDefault();
          this._exitInput(false);
          const below = findAdjacentContainer(this.el, "down");
          below ? below.focus() : this.el.focus();
        }
        return;
      }
      if (e.key === "Tab") {
        e.preventDefault();
        this._exitInput(false);
        const wrap = findRowWrapTarget(this.el, e.shiftKey);
        const adjacent = findAdjacentContainer(this.el, e.shiftKey ? "left" : "right");
        const target = wrap || adjacent;
        target ? target.focus() : this.el.focus();
      }
    };

    this._onCellFocus = () => {
      this._mode = "cell";
    };
    this._onCellBlur = (e) => {
      if (!this.el.contains(e.relatedTarget)) {
        if (this._list) this._closeList(false);
        this._mode = "cell";
      }
    };
    this._onInputBlur = (e) => {
      if (!this.el.contains(e.relatedTarget)) this._mode = "cell";
    };

    this._onListClick = (e) => {
      const item = e.target.closest("[data-ordinal-item]");
      if (!item) return;
      this._setActiveItem(item);
      this._closeList(true);
      const below = findAdjacentContainer(this.el, "down");
      below ? below.focus() : this.el.focus();
    };

    this.el.addEventListener("mousedown", this._onCellMousedown);
    this.el.addEventListener("dblclick", this._onCellDblclick);
    this.el.addEventListener("keydown", this._onCellKeydown);
    this.el.addEventListener("focus", this._onCellFocus);
    this.el.addEventListener("blur", this._onCellBlur);
    if (this._inner) {
      this._inner.addEventListener("keydown", this._onInputKeydown);
      this._inner.addEventListener("blur", this._onInputBlur);
    }
    if (this._list) this._list.addEventListener("click", this._onListClick);
  },

  updated() {
    const newInner = this.el.querySelector("select, input");
    if (newInner !== this._inner) {
      this._inner?.removeEventListener("keydown", this._onInputKeydown);
      this._inner?.removeEventListener("blur", this._onInputBlur);
      this._inner = newInner;
      if (this._inner) {
        this._inner.tabIndex = -1;
        this._inner.addEventListener("keydown", this._onInputKeydown);
        this._inner.addEventListener("blur", this._onInputBlur);
      }
    } else if (this._inner) {
      this._inner.tabIndex = -1;
    }
    this._list = this.el.querySelector("[data-ordinal-list]");
  },

  destroyed() {
    this.el.removeEventListener("mousedown", this._onCellMousedown);
    this.el.removeEventListener("dblclick", this._onCellDblclick);
    this.el.removeEventListener("keydown", this._onCellKeydown);
    this.el.removeEventListener("focus", this._onCellFocus);
    this.el.removeEventListener("blur", this._onCellBlur);
    this._inner?.removeEventListener("keydown", this._onInputKeydown);
    this._inner?.removeEventListener("blur", this._onInputBlur);
    this._list?.removeEventListener("click", this._onListClick);
  },

  _enterInput(prefill = null) {
    if (this._list) { this._openList(); return; }
    this._mode = "input";
    if (!this._inner) return;
    if (prefill !== null) {
      this._inner.value = prefill;
      this._inner.dispatchEvent(new Event("input", { bubbles: true }));
    }
    this._inner.focus();
  },

  _clearAndEnterInput() {
    if (!this._inner) return;
    this._inner.value = "";
    this._inner.dispatchEvent(new Event("input", { bubbles: true }));
    // For ordinal: just clear, stay in cell mode (Enter opens the picker)
    if (!this._list) this._enterInput();
  },

  _exitInput(refocusCell) {
    this._mode = "cell";
    this._inner?.blur();
    if (refocusCell) this.el.focus();
  },

  _openList() {
    this._mode = "input";
    this._list.classList.remove("hidden");
    const currentValue = this._inner?.value ?? "";
    const items = Array.from(this._list.querySelectorAll("[data-ordinal-item]"));
    const match = items.find((li) => li.dataset.value === currentValue) ?? items[0];
    this._setActiveItem(match);
  },

  _closeList(confirm) {
    if (confirm && this._activeItem) {
      this._inner.value = this._activeItem.dataset.value;
      this._inner.dispatchEvent(new Event("input", { bubbles: true }));
    }
    this._list.classList.add("hidden");
    this._setActiveItem(null);
    this._mode = "cell";
  },

  _setActiveItem(li) {
    this._activeItem?.removeAttribute("data-active");
    this._activeItem = li;
    li?.setAttribute("data-active", "true");
  },
};

export default EntryCellHook;
