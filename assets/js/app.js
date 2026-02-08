// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

// external imports
import 'glider-js';

// hooks
import autocompleteHook from "./autocomplete-hook";
import copyToClipboardHook from "./copy-to-clipboard-hook";
import cookiesHook from "./cookies-hook";
import dropdownMenuHook from "./dropdown-menu-hook";
import lantternVizHook from "./lanttern-viz-hook";
import menuButtonrHook from "./menu-button-hook";
import navScrollspyHook from "./nav-scrollspy-hook";
import scrollToTopHook from "./scroll-to-top-hook";
import sliderHook from "./slider-hook";
import sortableHook from "./sortable-hook";

// colocated hooks (Phoenix.LiveView.ColocatedHook)
import { hooks as colocatedHooks } from "phoenix-colocated/lanttern";

let Hooks = {};
Hooks.Autocomplete = autocompleteHook;
Hooks.Cookies = cookiesHook;
Hooks.CopyToClipboard = copyToClipboardHook;
Hooks.DropdownMenu = dropdownMenuHook;
Hooks.LantternViz = lantternVizHook;
Hooks.MenuButton = menuButtonrHook;
Hooks.NavScrollspy = navScrollspyHook;
Hooks.ScrollToTop = scrollToTopHook;
Hooks.Slider = sliderHook;
Hooks.Sortable = sortableHook;

Object.assign(Hooks, colocatedHooks);

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken, timezone: Intl.DateTimeFormat().resolvedOptions().timeZone },
  hooks: Hooks
});

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: "#22d3ee" },
  shadowColor: "rgba(0, 0, 0, .3)",
});
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

window.addEventListener("phx:open_external", (e) => {
  window.open(e.detail.url, "_blank");
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
