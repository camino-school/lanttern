# AGENTS.md — Lanttern Core

## 🎯 Project Context & Persona
Lanttern is a Phoenix-based web application for educational assessment and learning management.
*   **Primary Stack**: Elixir, Phoenix 1.8+, LiveView, PostgreSQL.
*   **Additional Stack**: React via `live_react`.
*   **Infrastructure**: Supabase, Fly.io.

## 🛠️ Operational Workflows
*   **Validation**: After changes, always run `mix compile --warning-as-errors`, `mix deps.unlock --unused`, `mix format`, `mix credo --strict`, and `mix test` (scoped to the change).
*   **HTTP Client**: Use `:req` exclusively — never `:httpoison`, `:tesla`, or `:httpc`.
*   **Migrations**: Creating or editing a migration → use the `db-migrations` skill (CLI generation, legacy tables, `und-x-icu` collation).

## 🏗️ Architecture & Patterns

### Ecto & Database
*   Prefer **keyword query syntax** (`from(u in User, where: u.active == true)`) over the pipe/macro API.
*   Write query functions in the **context**, not the schema.

### Contexts & Scoping
*   New context functions **must** take `Scope` as the first param: `def list_items(%Scope{} = scope, attrs)`.
*   Until the Scope migration is complete, use `current_user` (`%User{}`) inside functions to extract profile/school data for access control.
*   Permission checks raise on failure (MatchError), e.g. `true = Scope.has_permission?(...)`.

### UI & Design
*   At "sm" and (especially) "xs" font sizes, default to `font-sans` — the display and serif fonts are hard to read when small.

### LiveView
*   Assign to a `socket` variable before returning the tuple — never inline the pipe in `{:noreply, ...}`:
    ```elixir
    socket = socket |> assign(:foo, 1) |> push_patch(to: "/path")
    {:noreply, socket}
    ```

### General Elixir
*   Use `__MODULE__` instead of aliasing a module within itself.
*   Type specs: `pos_integer()` for IDs, `non_neg_integer()` for positions; add `| Ecto.Association.NotLoaded.t()` for preloads.
*   Wrap all user-facing text in `gettext()` — including changeset/validation error messages.
*   Trailing `?` is for **functions** returning a boolean (`composed?`). For variables, params, and schema fields use an `is_`/`has_` prefix (`is_already_a_component`, `has_marking`).

## 🧪 Testing Strategy
*   Use `ExMachina` factories exclusively — replace Phoenix generator fixtures when you touch a file; handle merge/lazy evaluation manually (see the `a_factory` pattern).
*   Use `phoenix_test` for all new view tests.
*   Assert with **pattern matching**, not `length/1` or `hd/1`.

## 📚 Usage Rules
**IMPORTANT**: Consult these for package-specific conventions.

*   Elixir / Phoenix / Ecto / LiveView: [`deps/phoenix/usage-rules/`](deps/phoenix/usage-rules/) (`elixir.md`, `phoenix.md`, `ecto.md`, `liveview.md`)
*   igniter: [`deps/igniter/usage-rules.md`](deps/igniter/usage-rules.md)
*   usage_rules: [`deps/usage_rules/usage-rules.md`](deps/usage_rules/usage-rules.md)
