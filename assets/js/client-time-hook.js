const dayjs = require('dayjs')
require('dayjs/locale/en')
require('dayjs/locale/pt-br')
/**
 * Formats the datetime provided in the element's 'time' attribute, 
   * according to the element's 'lang' and 'format' attributes.
   * 
   * If 'format' is not provided, it falls back to:
   *  - 'D MMM YYYY HH:mm' for pt-br locale
   *  - 'MMM D, YYYY HH:mm' for other locales.
   * 
   * The formatted datetime is then set as the element's innerHTML.
   *
 */
const clientTimeHook = {
  mounted() {
    const hook = this;
    const el = hook.el;

    let newTime = new Date(el.getAttribute('time') + 'Z');
    let format = el.getAttribute('format');
    let lang = el.getAttribute('lang');

    if(lang == null){
      lang = 'en'
    }

    if(format == null){
      format = 'D, YYYY HH:mm'
    }
    
    if (lang === 'pt-br' && format === 'MMM D, YYYY HH:mm') {
      format = 'D MMM YYYY HH:mm';
    } else if (lang === 'pt-br' && format === 'MMM D, YYYY') {
      format = 'D MMM YYYY';
    }

    el.innerHTML = dayjs(newTime).locale(lang).format(format);
  }
};

export default clientTimeHook;
