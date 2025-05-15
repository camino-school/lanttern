const dayjs = require('dayjs')
require('dayjs/locale/en')
require('dayjs/locale/pt-br')
/**
 * Requires `datetime` from database,
 * translate to client's browser datetime.
 */
const clientTimeHook = {
  mounted() {
    const hook = this;
    const el = hook.el;
    newTime = new Date(el.getAttribute('time') + 'Z');
    format = el.getAttribute('format');
    lang = el.getAttribute('lang');
    
    if(format == null)
      if(lang == 'pt-br')
        el.innerHTML = dayjs(newTime).locale(lang).format('D MMM YYYY HH:mm');  
      else
        el.innerHTML = dayjs(newTime).locale(lang).format('MMM D, YYYY HH:mm');  
    else
      el.innerHTML = dayjs(newTime).locale(lang).format(format);
  },
};

export default clientTimeHook;
