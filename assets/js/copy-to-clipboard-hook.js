const writeClipboardText = async (text) => {
  try {
    await navigator.clipboard.writeText(text);
    return "copied"
  } catch (error) {
    console.error(error.message);
    return "error"
  }
}

/**
 * This hook should be used in button elements.
 * It writes the text in "data-clipboard-text" attr to user's clipboard.
 * After write, it sets the class "copied-to-clipboard" to the button for 2s:
 * we can use this class to add additional styles for UI feedback.
 */
const copyToClipboardHook = {
  mounted() {
    const button = this.el;
    const text = button.getAttribute("data-clipboard-text");

    button.addEventListener("click", async () => {
      const res = await writeClipboardText(text)
      if (res === "copied") {
        button.classList.add("copied-to-clipboard")
        setTimeout(() => button.classList.remove("copied-to-clipboard"), 2000)
      }
    });
  },
};

export default copyToClipboardHook;
