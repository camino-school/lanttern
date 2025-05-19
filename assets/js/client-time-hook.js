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

    
    let format = el.getAttribute('format');
    let lang = el.getAttribute('lang');
    let time = el.getAttribute('time')

    if(format == null){
      format = 'MMM D, YYYY HH:mm'
    }

    if(lang == null){
      lang = 'en'
    }
    
    let newTime = new Date(time.includes('Z') ? dayjs(time).toDate() : time + "Z");
    
    if (lang === 'pt-br' && format.includes('MMMM D')) {
      format = format.replace('MMMM D', 'D MMMM');
    }
    
    if (lang === 'pt-br' && format.includes('MMM D')) {
      format = format.replace('MMM D', 'D MMM');
    }


    el.innerHTML = dayjs(newTime).locale(lang).format(format);
  }
};


export default clientTimeHook;
