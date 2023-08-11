defmodule LantternWeb.CreateAssessmentPointFormComponent do
  use LantternWeb, :live_component

  alias Phoenix.LiveView.JS

  def render(assigns) do
    ~H"""
    <div>
      <div
        :if={@show}
        id="create-form"
        class="relative z-10"
        aria-labelledby="slide-over-title"
        role="dialog"
        aria-modal="true"
        phx-mounted={show_create_form()}
        phx-remove={hide_create_form()}
      >
        <div
          id="create-form__backdrop"
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity hidden"
        >
        </div>

        <div class="fixed inset-0 overflow-hidden">
          <div class="absolute inset-0 overflow-hidden">
            <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
              <div
                id="create-form__panel"
                class="pointer-events-auto w-screen max-w-xl py-6 transition-translate hidden"
              >
                <div class="flex h-full flex-col divide-y divide-gray-200 bg-white shadow-xl rounded-l">
                  <div class="flex min-h-0 flex-1 flex-col overflow-y-scroll py-6">
                    <div class="px-4 sm:px-6">
                      <div class="flex items-start justify-between">
                        <h2
                          class="text-base font-semibold leading-6 text-gray-900"
                          id="slide-over-title"
                        >
                          Panel title
                        </h2>
                      </div>
                    </div>
                    <div class="relative mt-6 flex-1 px-4 sm:px-6">
                      <p>
                        Consequatur qui est et autem velit consequatur quidem. Ipsa sit reprehenderit totam rerum voluptas dolorem quisquam sit. Nisi molestiae vitae nostrum labore. Distinctio quia fuga et temporibus maxime quas. Maiores deleniti distinctio quas debitis voluptates accusamus.

                        Totam hic eum expedita. Aut sequi tempore aut et sapiente. Quo aut commodi praesentium aut voluptas qui. Corporis et laborum exercitationem itaque magnam rerum fuga. Reprehenderit fugiat ab voluptas autem.

                        Ea ducimus quia pariatur illum. Est qui quibusdam recusandae harum et unde qui consequatur. Praesentium illo exercitationem eum quo tempora.

                        Aliquam consectetur est esse. Facilis id ratione et id ut. Consequatur labore eum quam odio recusandae. In architecto dicta et at est facere. Id temporibus odit nobis et aspernatur qui.

                        Et enim deleniti quo. Id laboriosam dolores aut mollitia id consequatur deleniti. Explicabo quia et rerum. Id perspiciatis et velit saepe ab. Reiciendis reiciendis dolorem consequatur aliquid.
                      </p>
                      <p>
                        Consequatur qui est et autem velit consequatur quidem. Ipsa sit reprehenderit totam rerum voluptas dolorem quisquam sit. Nisi molestiae vitae nostrum labore. Distinctio quia fuga et temporibus maxime quas. Maiores deleniti distinctio quas debitis voluptates accusamus.

                        Totam hic eum expedita. Aut sequi tempore aut et sapiente. Quo aut commodi praesentium aut voluptas qui. Corporis et laborum exercitationem itaque magnam rerum fuga. Reprehenderit fugiat ab voluptas autem.

                        Ea ducimus quia pariatur illum. Est qui quibusdam recusandae harum et unde qui consequatur. Praesentium illo exercitationem eum quo tempora.

                        Aliquam consectetur est esse. Facilis id ratione et id ut. Consequatur labore eum quam odio recusandae. In architecto dicta et at est facere. Id temporibus odit nobis et aspernatur qui.

                        Et enim deleniti quo. Id laboriosam dolores aut mollitia id consequatur deleniti. Explicabo quia et rerum. Id perspiciatis et velit saepe ab. Reiciendis reiciendis dolorem consequatur aliquid.
                      </p>
                      <p>
                        Consequatur qui est et autem velit consequatur quidem. Ipsa sit reprehenderit totam rerum voluptas dolorem quisquam sit. Nisi molestiae vitae nostrum labore. Distinctio quia fuga et temporibus maxime quas. Maiores deleniti distinctio quas debitis voluptates accusamus.

                        Totam hic eum expedita. Aut sequi tempore aut et sapiente. Quo aut commodi praesentium aut voluptas qui. Corporis et laborum exercitationem itaque magnam rerum fuga. Reprehenderit fugiat ab voluptas autem.

                        Ea ducimus quia pariatur illum. Est qui quibusdam recusandae harum et unde qui consequatur. Praesentium illo exercitationem eum quo tempora.

                        Aliquam consectetur est esse. Facilis id ratione et id ut. Consequatur labore eum quam odio recusandae. In architecto dicta et at est facere. Id temporibus odit nobis et aspernatur qui.

                        Et enim deleniti quo. Id laboriosam dolores aut mollitia id consequatur deleniti. Explicabo quia et rerum. Id perspiciatis et velit saepe ab. Reiciendis reiciendis dolorem consequatur aliquid.
                      </p>
                    </div>
                  </div>
                  <div class="flex flex-shrink-0 justify-end px-4 py-4">
                    <button
                      type="button"
                      class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:ring-gray-400"
                      phx-click="hide-create-assessment-point-form"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      class="ml-4 inline-flex justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
                    >
                      Save
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_create_form() do
    JS.add_class(
      "overflow-hidden",
      to: "body"
    )
    |> JS.show(
      to: "#create-form__backdrop",
      transition: {"ease-in-out duration-500", "opacity-0", "opacity-100"},
      time: 500
    )
    |> JS.show(
      to: "#create-form__panel",
      transition: {
        "ease-in-out duration-500",
        "translate-x-full",
        "translate-x-0"
      },
      time: 500
    )
  end

  def hide_create_form() do
    JS.remove_class("overflow-hidden", to: "body")
    |> JS.hide(
      to: "#create-form__backdrop",
      transition: {"ease-in-out duration-500", "opacity-100", "opacity-0"},
      time: 500
    )
    |> JS.hide(
      to: "#create-form__panel",
      transition: {
        "ease-in-out duration-500",
        "translate-x-0",
        "translate-x-full"
      },
      time: 500
    )
  end
end
