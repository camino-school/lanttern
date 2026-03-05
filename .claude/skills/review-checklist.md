## Review Checklist

Systematically analyze the following areas:

#### 1. Code Quality and Standards
- Verify `mix precommit` was run (proper formatting, no Credo issues)
- Check for proper use of `__MODULE__` instead of self-aliasing
- Ensure schemas avoid query functions (queries belong in context files)
- Verify context functions follow `list_items(opts)` pattern with keyword list options
- Check that `render/1` is at the top of LiveView files
- Look for proper use of `stream` for potentially large datasets

#### 2. Type Specifications
- Verify schema `t()` specs include `| Ecto.Association.NotLoaded.t()` for preloaded structures
- Check `| nil` is included for nullable fields but excluded for required fields

#### 3. Testing Approach
- Ensure tests focus on behavior (what) not implementation (how)
- Verify use of `phoenix_test` for front-end testing (`visit/2`, `click_link/2`, etc.)
- Check that tests cover main user workflows rather than excessive unit tests
- Confirm pattern matching is used for assertions instead of `length/1` and `hd/1`
- Verify ExMachina factories are used instead of fixture functions
- Check factories properly `build` and only `insert` when needed

#### 4. Design Patterns
- Verify HTTP requests use `:req` (Req) library, not `:httpoison`, `:tesla`, or `:httpc`
- Check that test functions are in test files, not context modules
- Ensure new context CRUD functions include `current_user` parameter for access control

#### 5. Security
- Look for potential security vulnerabilities
- Consider if `mix sobelow` analysis would be beneficial
- Verify proper access control implementation

#### 6. Performance
- Check for N+1 query problems
- Verify efficient use of Ecto queries and preloading
- Look for opportunities to use streaming for large datasets

#### 7. Project-Specific Context
- Ensure alignment with Lanttern's educational assessment domain
- Verify changes fit within the Phoenix web framework patterns
- Check consistency with existing codebase patterns

## Output Format

Structure your review as follows:

#### Overview
- Brief summary of what the change accomplishes
- Overall assessment (see framing guidance in the calling skill)
- If GitHub issues were provided, state whether they are addressed

#### Critical Issues
- List any blocking issues that must be fixed before merge
- Include specific file locations and line references when relevant

#### Suggestions for Improvement
- Non-blocking improvements that would enhance code quality
- Best practice recommendations
- Performance optimizations

#### Positive Observations
- Highlight good patterns and implementations
- Acknowledge particularly well-done aspects

#### Questions
- Any clarifications needed about implementation decisions
- Areas where the intent is unclear

## Review Principles

1. **Be Specific**: Reference exact files and line numbers
2. **Be Constructive**: Explain why something should change and suggest alternatives
3. **Be Thorough**: Analyze the actual implementation, don't just skim
4. **Be Balanced**: Acknowledge good work alongside suggestions
5. **Focus on Impact**: Prioritize issues by their effect on functionality, maintainability, and security
6. **Teach**: When suggesting changes, explain the reasoning and project context
