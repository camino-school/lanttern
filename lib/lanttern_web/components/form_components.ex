defmodule LantternWeb.FormComponents do
  @moduledoc """
  Provides core form components.
  """
  use Phoenix.Component

  import LantternWeb.CoreComponents
  alias Phoenix.LiveView.JS
  import LantternWeb.Gettext

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week toggle)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :help_text, :string, default: nil, doc: "render a tooltip with some extra instructions"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :show_optional, :boolean, default: false, doc: "control the display of optional text"
  attr :class, :any, default: nil

  attr :theme, :string,
    default: nil,
    doc: "Used to modify underlying input components (e.g. toggle)"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :custom_label

  slot :description,
    doc: "works for type select, textarea and text variations (e.g. number, email)"

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "toggle", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <label id={"#{@id}-label"} class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="hidden"
          {@rest}
        />
        <.toggle
          theme={@theme}
          enabled={@checked}
          phx-click={JS.dispatch("click", to: "##{@id}-label")}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <.label
        :if={@label || @custom_label != []}
        for={@id}
        show_optional={@show_optional}
        custom={if @custom_label == [], do: false, else: true}
      >
        <%= @label || render_slot(@custom_label) %>
      </.label>
      <div :if={@description != []} class="mb-2 text-sm">
        <%= render_slot(@description) %>
      </div>
      <.select
        id={@id}
        name={@name}
        multiple={@multiple}
        prompt={@prompt}
        options={@options}
        value={@value}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "radio"} = assigns) do
    ~H"""
    <fieldset phx-feedback-for={@name} class={@class}>
      <legend class="text-sm font-bold"><%= @prompt %></legend>
      <div :for={{label, value} <- @options} class="flex items-center gap-2 mt-4 text-sm">
        <input
          id={"#{@name}-option-#{value}"}
          name={@name}
          type="radio"
          value={value}
          checked={"#{@value}" == "#{value}"}
        />
        <label for={"#{@name}-option-#{value}"}><%= label %></label>
      </div>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </fieldset>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <.label
        :if={@label || @custom_label != []}
        for={@id}
        show_optional={@show_optional}
        custom={if @custom_label == [], do: false, else: true}
      >
        <%= @label || render_slot(@custom_label) %>
      </.label>
      <div :if={@description != []} class="mb-2 text-sm">
        <%= render_slot(@description) %>
      </div>
      <.textarea id={@id} name={@name} errors={@errors} value={@value} {@rest} />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <.label
        :if={@label || @custom_label != []}
        for={@id}
        show_optional={@show_optional}
        help_text={@help_text}
        custom={if @custom_label == [], do: false, else: true}
      >
        <%= @label || render_slot(@custom_label) %>
      </.label>
      <div :if={@description != []} class="mb-2 text-sm">
        <%= render_slot(@description) %>
      </div>
      <.base_input type={@type} name={@name} id={@id} value={@value} errors={@errors} {@rest} />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :help_text, :string, default: nil, doc: "render a tooltip with some extra instructions"
  attr :show_optional, :boolean, default: false
  attr :custom, :boolean, default: false
  slot :inner_block, required: true

  def label(%{show_optional: true} = assigns) do
    ~H"""
    <div class="flex justify-between gap-4 mb-2 text-sm">
      <label for={@for} class="font-bold">
        <.help_tooltip text={@help_text} class="inline-block font-normal" />
        <%= render_slot(@inner_block) %>
      </label>
      <span class="text-ltrn-subtle">Optional</span>
    </div>
    """
  end

  def label(%{custom: true} = assigns) do
    ~H"""
    <label for={@for} class="block mb-2">
      <.help_tooltip text={@help_text} class="inline-block font-normal" />
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  def label(assigns) do
    ~H"""
    <label for={@for} class="block mb-2 text-sm font-bold">
      <.help_tooltip text={@help_text} class="inline-block font-normal" />
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Renders a help tooltip.
  """

  attr :text, :string, required: true
  attr :class, :any, default: nil

  def help_tooltip(assigns) do
    ~H"""
    <div :if={@text} class={["group relative", @class]}>
      <.icon name="hero-question-mark-circle" class={@class} />
      <.tooltip><%= @text %></.tooltip>
    </div>
    """
  end

  @doc """
  Base select component
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :value, :any
  attr :prompt, :string, default: nil
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false
  attr :class, :any, default: nil

  attr :rest, :global, include: ~w(disabled multiple readonly required)

  def select(assigns) do
    ~H"""
    <select
      id={@id}
      name={@name}
      class={[
        "block w-full rounded-sm border-0 shadown-sm ring-1 ring-ltrn-lighter bg-white sm:text-sm",
        "focus:ring-2 focus:ring-ltrn-primary focus:ring-inset",
        @class
      ]}
      multiple={@multiple}
      {@rest}
    >
      <%!-- apply bg and text color to prevent issue #75 --%>
      <option :if={@prompt} value="" class="bg-ltrn-lighter text-ltrn-dark"><%= @prompt %></option>
      <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
    </select>
    """
  end

  @doc """
  Base textarea component
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :value, :any
  attr :errors, :list, default: []
  attr :class, :any, default: nil

  attr :rest, :global, include: ~w(autocomplete cols disabled maxlength minlength
                placeholder readonly required rows)

  def textarea(assigns) do
    ~H"""
    <textarea
      id={@id}
      name={@name}
      class={[
        "block w-full min-h-[10rem] rounded-sm border-0 shadow-sm ring-1 sm:text-sm sm:leading-6",
        "focus:ring-2 focus:ring-inset",
        "phx-no-feedback:ring-ltrn-lighter phx-no-feedback:focus:ring-ltrn-primary",
        @errors == [] && "ring-ltrn-lighter focus:ring-ltrn-primary",
        @errors != [] && "ring-rose-400 focus:ring-rose-400",
        @class
      ]}
      {@rest}
    ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
    """
  end

  @doc """
  Textarea with actions
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :value, :any
  attr :label, :string
  attr :errors, :list, default: []
  attr :class, :any, default: nil
  attr :rows, :string, default: "4"

  attr :rest, :global, include: ~w(autocomplete cols disabled maxlength minlength
                placeholder readonly required rows)

  slot :actions, required: true
  slot :actions_left

  def textarea_with_actions(assigns) do
    ~H"""
    <div class={[
      "overflow-hidden rounded-sm shadow-sm ring-1 ring-inset bg-white",
      "focus-within:ring-2",
      "phx-no-feedback:ring-ltrn-lighter phx-no-feedback:focus-within:ring-ltrn-primary",
      @errors == [] && "ring-ltrn-lighter focus-within:ring-ltrn-primary",
      @errors != [] && "ring-rose-400 focus-within:ring-rose-400",
      @class
    ]}>
      <label for={@id} class="sr-only"><%= @label %></label>
      <textarea
        rows={@rows}
        name={@name}
        id={@id}
        class="peer block w-full border-0 bg-transparent p-4 placeholder:text-ltrn-subtle focus:ring-0"
        placeholder={@label}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <div class={[
        "flex items-center justify-between gap-6 w-full p-2 border-t",
        @errors == [] && "border-ltrn-lighter, peer-focus:border-ltrn-primary",
        @errors != [] && "border-rose-400 peer-focus:border-rose-400"
      ]}>
        <div class="flex items-center gap-2">
          <%= render_slot(@actions_left) %>
        </div>
        <div class="flex items-center gap-2">
          <%= render_slot(@actions) %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Base input component
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(color date datetime-local email file hidden month number password
               range radio search tel text time url week)

  attr :errors, :list, default: []
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def base_input(assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      id={@id}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      class={[
        "block w-full rounded-sm border-0 shadow-sm ring-1 sm:text-sm sm:leading-6",
        "focus:ring-2 focus:ring-inset",
        "phx-no-feedback:ring-ltrn-lighter phx-no-feedback:focus:ring-ltrn-primary",
        @errors == [] && "ring-ltrn-lighter focus:ring-ltrn-primary",
        @errors != [] && "ring-rose-400 focus:ring-rose-400",
        @class
      ]}
      {@rest}
    />
    """
  end

  @doc """
  Check field to use in list fields.

  Note that input has `phx-update` attr to avoid form updates
  conflicts with HTML input control.

  In other words, the checked attr works only on mount - keep this
  in mind when working with check fields that should start checked.
  """
  attr :id, :string, required: true

  attr :opt, :map,
    required: true,
    doc: "Check field option. Any map/struct with `:id` and `:name` attrs"

  attr :field, Phoenix.HTML.FormField, required: true

  def check_field(assigns) do
    ~H"""
    <div class="relative flex items-start py-4">
      <div class="min-w-0 flex-1 text-sm leading-6">
        <label for={@id} class="select-none text-ltrn-dark">
          <%= @opt.name %>
        </label>
      </div>
      <div class="ml-3 flex h-6 items-center">
        <input
          id={@id}
          name={@field.name <> "[]"}
          type="checkbox"
          value={@opt.id}
          class="h-4 w-4 rounded border-ltrn-subtle text-ltrn-primary focus:ring-ltrn-primary"
          checked={"#{@opt.id}" in (@field.value || [])}
          phx-update="ignore"
        />
      </div>
    </div>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-2 flex items-center gap-2 text-xs text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Generates error messages for the specified field.

  Use this when you want to display field errors in the interface without using `<.input>`.
  """
  attr :field, Phoenix.HTML.FormField, required: true
  attr :class, :any, default: nil

  def errors(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns =
      assigns
      |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))

    ~H"""
    <div class={@class}>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Generates a generic error message block.
  """
  attr :class, :any, default: nil
  attr :on_dismiss, JS, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def error_block(assigns) do
    ~H"""
    <div
      class={[
        "flex items-center gap-4 p-4 rounded-sm text-sm text-rose-600 bg-rose-100",
        @class
      ]}
      {@rest}
    >
      <.icon name="hero-exclamation-circle" class="shrink-0" />
      <div class="flex-1">
        <%= render_slot(@inner_block) %>
      </div>
      <.icon_button
        :if={@on_dismiss}
        name="hero-x-mark"
        sr_text="Dismiss"
        size="sm"
        theme="ghost"
        rounded
        class="shrink-0"
        phx-click={@on_dismiss}
      />
    </div>
    """
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders a markdown supported message.
  """
  attr :message, :string
  attr :class, :any, default: nil

  def markdown_supported(assigns) do
    assigns =
      assigns
      |> assign(
        :message,
        Map.get(assigns, :message, gettext("Markdown supported"))
      )

    ~H"""
    <p class={["text-sm text-ltrn-subtle", @class]}>
      <a
        href="https://www.markdownguide.org/basic-syntax/"
        target="_blank"
        class="hover:text-ltrn-primary"
      >
        <%= @message %> <.icon name="hero-information-circle" />
      </a>
    </p>
    """
  end
end
