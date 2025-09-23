Lanttern is a web application written using the Phoenix web framework for educational assessment and learning management.

## Project guidelines

- Run `mix credo --strict` and scoped tests when you are done with all changes and fix any pending issues, and always ask the developer to run the broader `mix precommit` task to ensure everything is ok (and save some tokens)
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps
- Use Tidewave MCP for development tooling
- use `mix credo` (also included in `mix precommit`) for code quality
- use `mix sobelow` for security analysis when needed
- when requested to write commit messages, PR summaries, or PR reviews:
  - use markdown, and write it to a `_transfer.md` file, so we can simply copy and paste it in GitHub
  - for PRs, remember that we can see all code changes through diff in the PR UI, so focus on giving information about the context, changes made, expected impacts — the idea is that the summary can complement the code changes. you can still reference the relevant files if needed.
  - for PRs, do not include a test plan

## Testing

- When planning tests, focus on behavior (what) and not on implementation (how). For example: considering a form live component, we don't want to test the form in isolation, we want to test the user flow in the live view where this form is used
- Avoid unit testing every detail of a feature, and focus on main user workflows. It doesn't cost much to develop lots and lots of tests, but it may be costly to maintain them
- Prefer using pattern matching for assertions instead of checking with `length/1` and `hd/1`

### Front end tests

- When testing views, use `phoenix_test` (`conn |> visit("some/path") |> click_link...`). This is not the current project pattern because `phoenix_test` was implemented recently, but we want to use it as the default for front end tests from now on, and we will update old tests little by litte

### Test fixtures

- We are favoring `ExMachina` factories instead of default fixture functions.
- When creating new schemas use factories instead of Phoenix generators' fixtures, and when generating data for testing always prefer using factories, if available.
- Factories should `build` and `insert` only if needed. For example, if a factory of `A` belongs to `B`, the factory should have a `b = Map.get(attrs, :b, insert(:b))`, which is used in `a = %A{b: b}`. As this is not the default ExMachina behavior, we also need to manually handle merge and lazy evaluation. Putting it all together:

```elixir
 def a_factory(attrs) do
  b = Map.get(attrs, :b, build(:b))

  %A{b: b}
  |> merge_attributes(attrs)
  |> evaluate_lazy_attributes()
end
 ```

## Type spec

### Schema type `t()` spec

- Always include `| Ecto.Association.NotLoaded.t()` for preloaded structures
- Always include `| nil` for nullable fields

## PR size check

We should aim for PRs with a maximum of 500 loc (additions and deletions) considering only the `lib` folder.

It's important to periodically update the `main` branch, and check for size with `git diff --stat main lib`.

## Temporary guidelines

### Transition to Phoenix 1.8 scopes

The recent Phoenix framework release introduced [scopes](https://hexdocs.pm/phoenix/scopes.html) for enhanced security.

Currently, the structure we're using more or less like scope is the `current_user` (`%User{}`).
We will officialy migrate to scopes soon, but until that happens, we want the new context functions (e.g. CRUD) to
always include `current_user` as one of the params, so we can extract the user profile, school, and etc. for
access control.

<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below.
Before attempting to use any of these packages or to discover if you should use them, review their
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->

<!-- phoenix:elixir-start -->
## phoenix:elixir usage

[phoenix:elixir usage rules](deps/phoenix/usage-rules/elixir.md)
<!-- phoenix:elixir-end -->
<!-- phoenix:phoenix-start -->
## phoenix:phoenix usage

[phoenix:phoenix usage rules](deps/phoenix/usage-rules/phoenix.md)
<!-- phoenix:phoenix-end -->
<!-- phoenix:ecto-start -->
## phoenix:ecto usage

[phoenix:ecto usage rules](deps/phoenix/usage-rules/ecto.md)
<!-- phoenix:ecto-end -->
<!-- phoenix:html-start -->
## phoenix:html usage

[phoenix:html usage rules](deps/phoenix/usage-rules/html.md)
<!-- phoenix:html-end -->
<!-- phoenix:liveview-start -->
## phoenix:liveview usage

[phoenix:liveview usage rules](deps/phoenix/usage-rules/liveview.md)
<!-- phoenix:liveview-end -->
<!-- igniter-start -->
## igniter usage

_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- usage_rules-start -->
## usage_rules usage

_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

[usage_rules usage rules](deps/usage_rules/usage-rules.md)
<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage

[usage_rules:elixir usage rules](deps/usage_rules/usage-rules/elixir.md)
<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage

[usage_rules:otp usage rules](deps/usage_rules/usage-rules/otp.md)
<!-- usage_rules:otp-end -->
<!-- usage-rules-end -->
