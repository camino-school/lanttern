defmodule LantternWeb.CurriculumBNCCLive do
  use LantternWeb, :live_view

  alias Lanttern.BNCC

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">BNCC</h1>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-slate-400">
        <.link patch={~p"/curriculum"} class="underline">Curriculum</.link>
        <span class="mx-1">/</span>
        <span>BNCC</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <div class="flex items-center text-sm">
        <p>Exploring: all subjects | all years</p>
        <button class="flex items-center ml-4 text-slate-400">
          <.icon name="hero-funnel-mini" class="text-cyan-400 mr-2" />
          <span class="underline">Change</span>
        </button>
      </div>
    </div>
    <div class="relative w-full mt-6 rounded shadow-xl bg-white">
      <.table id="habilidades-bncc" rows={@habilidades_bncc}>
        <:col :let={ha} label="Code"><%= ha.code %></:col>
        <:col :let={ha} label="Campo de Atuação">
          <%= if ha.campo_de_atuacao, do: ha.campo_de_atuacao.name, else: "—" %>
        </:col>
        <:col :let={ha} label="Prática de Linguagem">
          <%= if ha.pratica_de_linguagem, do: ha.pratica_de_linguagem.name, else: "—" %>
        </:col>
        <:col :let={ha} label="Unidade Temática">
          <%= if ha.unidade_tematica, do: ha.unidade_tematica.name, else: "—" %>
        </:col>
        <:col :let={ha} label="Objeto de Conhecimento"><%= ha.objeto_de_conhecimento.name %></:col>
        <:col :let={ha} label="Habilidade"><%= ha.name %></:col>
      </.table>
    </div>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [habilidades_bncc: []]}
  end

  def handle_params(_params, _uri, socket) do
    habilidades_bncc = BNCC.list_bncc_ef_items()

    {:noreply, assign(socket, :habilidades_bncc, habilidades_bncc)}
  end
end
