defmodule LantternWeb.CurriculumLive do
  use LantternWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">Curriculum</h1>
      <div class="mt-12">
        <.link
          patch={~p"/curriculum/bncc_ef"}
          class="flex items-center font-display font-black text-lg text-ltrn-subtle"
        >
          Aero <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
        <.link
          patch={~p"/curriculum/bncc_ef"}
          class="flex items-center mt-4 font-display font-black text-lg text-ltrn-subtle"
        >
          BNCC EI <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
        <.link
          patch={~p"/curriculum/bncc_ef"}
          class="flex items-center mt-4 font-display font-black text-lg text-ltrn-subtle"
        >
          BNCC EF <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
        <.link
          patch={~p"/curriculum/bncc_ef"}
          class="flex items-center mt-4 font-display font-black text-lg text-ltrn-subtle"
        >
          BNCC EM <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
        <.link
          patch={~p"/curriculum/bncc_ef"}
          class="flex items-center mt-4 font-display font-black text-lg text-ltrn-subtle"
        >
          Camino School <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
        <.link
          patch={~p"/curriculum/bncc_ef"}
          class="flex items-center mt-4 font-display font-black text-lg text-ltrn-subtle"
        >
          Common Core <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
