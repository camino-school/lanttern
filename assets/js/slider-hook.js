/**
 * Based on this Pen: https://codepen.io/thenutz/pen/VwYeYEE
 */
const sliderHook = {
  mounted() {
    const slider = this.el;
    let isDown = false;
    let startX;
    let scrollLeft;

    slider.classList.add("data-[slider=active]:cursor-grabbing");

    slider.addEventListener("mousedown", (e) => {
      isDown = true;
      slider.setAttribute("data-slider", "active");
      startX = e.pageX - slider.offsetLeft;
      scrollLeft = slider.scrollLeft;
    });
    slider.addEventListener("mouseleave", () => {
      isDown = false;
      slider.removeAttribute("data-slider");
    });
    slider.addEventListener("mouseup", () => {
      isDown = false;
      slider.removeAttribute("data-slider");
    });
    slider.addEventListener("mousemove", (e) => {
      if (!isDown) return;
      e.preventDefault();
      const x = e.pageX - slider.offsetLeft;
      const walk = (x - startX) * 3; //scroll-fast
      slider.scrollLeft = scrollLeft - walk;
    });
  },
};

export default sliderHook;
