/**
 * Slider Hook
 * 
 * Required HTML structure:
 * - container: children div with class "slider"
 * - dots: div with class "slider-dots"
 */

const sliderHook = {
  mounted() {
    const slider = this.el;
    const container = slider.querySelector(".slider");
    const dots = slider.querySelector(".slider-dots");

    this.glider = new Glider(container, {
      draggable: true,
      scrollLock: true,
      scrollLockDelay: 100,
      dots: dots,
    });
  },
  destroyed() {
    this.glider.destroy();
  },
};

export default sliderHook;
