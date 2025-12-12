import Sortable from 'sortablejs';

/**
 * Will send the full dataset `onEnd` for implementation flexibility
 * (e.g. use `data-section-name` for pattern matching).
 * 
 * The predefined data attributes are:
 * - `data-sortable-event` (required) - the event name on pushEvent
 * - `data-sortable-handle` (required) - for `handle` opt
 * - `data-sortable-group` - for `group` opt
 * 
 */

const sortableHook = {
  mounted() {
    const hook = this;
    const el = hook.el;

    let opts = {
      group: el.dataset.sortableGroup,
      handle: el.dataset.sortableHandle,
      chosenClass: 'opacity-50',
      onEnd: function (evt) {
        const payload = {
          oldIndex: evt.oldIndex,
          newIndex: evt.newIndex,
          from: evt.from.dataset,
          to: evt.to.dataset
        };

        hook.pushEventTo(el, el.dataset.sortableEvent, payload);
      },
    };

    new Sortable(el, opts);
  },
};

export default sortableHook;
