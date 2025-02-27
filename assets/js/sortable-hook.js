import Sortable from 'sortablejs';

/**
 * Requires `data-group-id` and `data-group-name`,
 * used to identify the group on sort.
 */

const sortableHook = {
  mounted() {
    const hook = this;
    const el = hook.el;

    let opts = {
      chosenClass: 'opacity-50',
      onUpdate: function (evt) {
        const payload = {
          groupId: el.getAttribute('data-group-id'),
          groupName: el.getAttribute('data-group-name'),
          oldIndex: evt.oldIndex,
          newIndex: evt.newIndex
        };

        hook.pushEventTo(el, "sortable_update", payload);
      },
    };

    if (el.getAttribute('data-sortable-handle')) {
      opts.handle = el.getAttribute('data-sortable-handle');
    }

    Sortable.create(el, opts);
  },
};

export default sortableHook;
