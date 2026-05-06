# AGENTS.md — Lanttern Core

## 🎯 Project Context & Persona
Lanttern is a Phoenix-based web application for educational assessment and learning management[cite: 1]. 
*   **Primary Stack**: Elixir, Phoenix 1.8+, LiveView, PostgreSQL[cite: 1].
*   **Infrastructure**: Supabase, Fly.io[cite: 1].
*   **AI Philosophy**: We prioritize external LLM workflows for curriculum search and lesson planning[cite: 1]. Lanttern acts as the authoritative data source for these integrations[cite: 1].

## 🛠️ Operational Workflows
*   **Development Tooling**: Use **Tidewave MCP** and **Claude Code**[cite: 1].
*   **Database Migrations**: Always generate migrations via the CLI using `mix ecto.gen.migration <name>` before editing the file. Do not create migration files manually.
*   **Validation**: Run `mix credo --strict`, `mix sobelow`, and `mix test`[cite: 1]. 
    *   *Agent Rule*: Suggest these commands to the user; do not run them automatically unless requested[cite: 1].
*   **HTTP Client**: Use `:req` exclusively. **Avoid** `:httpoison`, `:tesla`, and `:httpc`[cite: 1].

## 🏗️ Architecture & Patterns

### 1. Ecto & Database
*   **Query Syntax**: Always prefer **Keyword Query syntax** over the Macro API (pipe-based queries).
    *   *Good*: `from(u in User, where: u.active == true)`
    *   *Avoid*: `User |> where([u], u.active == true)`
*   **Query Logic**: Write query functions directly in the **Context** file, not the Schema[cite: 1].
*   **Legacy Data**: Consult `docs/legacy.md` before touching older tables[cite: 1].

### 2. Contexts & Scoping
*   **Scope Pattern**: All new context functions **must** accept `Scope` as the first parameter to support our migration to Phoenix Scopes[cite: 1].
    *   *Example*: `def list_items(%Scope{} = scope, attrs)`
*   **Fallback Access**: Until the official migration is complete, use `current_user` (`%User{}`) within functions to extract necessary profile or school data for access control[cite: 1].
*   **Permission Checks**: Raise on failure (MatchError) in context functions (e.g., `true = Scope.has_permission?...`)[cite: 1].

### 3. LiveView Conventions
*   **Event Returns**: Always assign the modified socket to a `socket` variable before returning the tuple.
    *   *Good*: 
        ```elixir
        socket = socket |> assign(:foo, 1) |> push_patch(to: "/path")
        {:noreply, socket}
        ```

### 4. General Elixir Patterns
*   **Module References**: Always use `__MODULE__` instead of aliasing the module in itself[cite: 1].
*   **Type Specs**: Use `pos_integer()` for IDs and `non_neg_integer()` for positions[cite: 1]. Always include `| Ecto.Association.NotLoaded.t()` for preloads[cite: 1].
*   **User-Facing Strings**: Always wrap user-facing text in `gettext()`. This applies to all changeset error messages, validation messages, and any string shown to users.

## 🧪 Testing Strategy
*   **Factories vs. Fixtures**: Exclusively use `ExMachina` factories.
    *   **Proactive Cleanup**: Replace and remove existing Phoenix generator fixtures when modifying files.
    *   **Lazy Evaluation**: Manually handle merge and lazy evaluation (refer to the `a_factory` pattern)[cite: 1].
*   **Frontend**: Use `phoenix_test` for all new view tests[cite: 1].
*   **Assertions**: Use **pattern matching** instead of `length/1` or `hd/1`[cite: 1].

## 📚 Usage Rules
**IMPORTANT**: Consult these for package-specific conventions[cite: 1].

*   **phoenix:elixir**: [elixir.md](deps/phoenix/usage-rules/elixir.md)[cite: 1]
*   **phoenix:phoenix**: [phoenix.md](deps/phoenix/usage-rules/phoenix.md)[cite: 1]
*   **phoenix:ecto**: [ecto.md](deps/phoenix/usage-rules/ecto.md)[cite: 1]
*   **phoenix:liveview**: [liveview.md](deps/phoenix/usage-rules/liveview.md)[cite: 1]
*   **igniter**: [usage-rules.md](deps/igniter/usage-rules.md)[cite: 1]
*   **usage_rules**: [usage-rules.md](deps/usage_rules/usage-rules.md)[cite: 1]
