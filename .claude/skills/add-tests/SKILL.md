---
description: Add or fill test coverage for a Lanttern module. Usage: /add-tests [path/to/module.ex]
---

## Context

- Target (from args, or infer from recent changes): `$ARGUMENTS`
- Current branch: !`git branch --show-current`
- Recent unstaged/staged changes (to infer target if not given): !`git diff HEAD --name-only`

## Your task

Add or fill test coverage for the target module following Lanttern's testing conventions. If no argument is given, infer the target from recent changes — prefer the most recently modified non-test `.ex` file.

### Step 1 — Locate files

Given the target module path, find:

1. **The source file** — read it fully to understand all public functions, their signatures, and edge cases.
2. **The test file** — it mirrors the source path under `test/`:
   - `lib/lanttern/foo.ex` → `test/lanttern/foo_test.exs`
   - `lib/lanttern_web/live/pages/foo/foo_live.ex` → `test/lanttern_web/live/pages/foo/foo_live_test.exs`
   
   If the test file doesn't exist, create it. If it does exist, read it to find which functions/cases are already covered — only add what's missing.

3. **Relevant factories** — look in `test/support/factories/` for factories matching the schemas used. Read `test/support/factory.ex` if you need to check which factories are available.

### Step 2 — Determine test type

**Context module** (`lib/lanttern/*.ex`, no LiveView):
- Use `Lanttern.DataCase`
- Import `Lanttern.Factory`
- Alias `Lanttern.Identity.Scope`
- Define module-level scope attrs:
  ```elixir
  @staff_scope %Scope{profile_type: "staff"}
  @student_scope %Scope{profile_type: "student"}
  ```
- All context functions take `%Scope{}` as first arg — always test with scope

**LiveView module** (`lib/lanttern_web/live/**`):
- Use `LantternWeb.ConnCase`
- Import `Lanttern.Factory` and `PhoenixTest`
- Always `setup [:register_and_log_in_staff_member]`
- Use the `conn |> visit(path) |> assert_has(...) |> click_button(...)` pipeline
- Use `set_user_permissions(["permission"], context)` when the page requires permissions
- Define `@live_view_path` as a module attribute

### Step 3 — Write the tests

Follow these rules without exception:

**Factories, not fixtures**
- Always use `insert(:factory_name, attrs)` from ExMachina
- Never use `_fixture()` helpers — if you find them in the file, replace them
- For associations, pass the struct directly: `insert(:thing, school: school)` not `insert(:thing, school_id: school.id)`

**No mocks** — hit the real database; that's what the sandbox is for.

**Pattern matching over length/hd**
```elixir
# Good
assert [%MySchema{id: ^expected_id}] = result
assert {:ok, %MySchema{name: "foo"}} = MyContext.create_thing(scope, attrs)

# Bad
assert length(result) == 1
assert hd(result).id == expected_id
```

**Scope coverage for context functions**
- Test that student/guardian scopes are rejected when the function is staff-only
- Test the permission check raises (MatchError) rather than returning an error tuple:
  ```elixir
  test "raises when called with non-staff scope" do
    assert_raise MatchError, fn ->
      MyContext.create_thing(@student_scope, %{})
    end
  end
  ```

**`describe` blocks** — one per public function, named `"function_name/arity"`.

**Test naming** — describe the behavior, not the implementation:
- Good: `"returns only items belonging to the given school"`
- Bad: `"filters by school_id"`

**Async** — use `async: true` on `DataCase` tests unless there's a known concurrency issue. Do not use it on `ConnCase` tests.

### Step 4 — Output

Write the test file. Then print a single summary line:

```
Added N tests to test/path/to/file_test.exs (M describe blocks)
```

Do not explain what each test does — the test names already say that.
