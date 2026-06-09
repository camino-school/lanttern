---
description: Complete missing and fuzzy gettext translations for the given language(s), keeping terminology consistent with the rest of the app. Usage: /gettext_add_missing_and_fuzzy <lang> [<lang>...] (e.g. /gettext_add_missing_and_fuzzy pt-br)
disable-model-invocation: true
---

## Context

- Target language(s) (from args): `$ARGUMENTS`
- Available locales: !`ls -d priv/gettext/*/ | xargs -n1 basename | grep -v '\.pot$'`

## Your task

Fill in every incomplete translation in the `default.po` file(s) for the requested language(s), and rewrite every fuzzy translation from scratch — treating fuzzy entries as if they were empty. Keep terminology consistent with how the rest of the app already translates the same words.

**Do this yourself, in this conversation. Never delegate to a sub-agent / the Agent tool.**

### Step 1 — Resolve the locale(s)

Map each language argument to its gettext locale directory under `priv/gettext/`:

- Arguments are case-insensitive and may use `-` or `_` (e.g. `pt-br`, `pt_br`, `PT-BR` all → `pt_BR`).
- Match against the actual directory names listed in **Available locales** above. The correct path is `priv/gettext/<locale>/LC_MESSAGES/default.po`.
- If an argument matches no existing locale, tell the user which locales exist and stop.
- If no argument was given, tell the user the usage and stop.

> **Scope:** this skill only touches `default.po`. Do not edit `errors.po`, `schools.po`, `taxonomy.po`, or any `.pot` file.

### Step 2 — Ensure the file is up to date (only if needed)

The user has *usually* already run the extract/merge mix tasks, so **do not run them by default.** Only run them if the `.po` file looks stale or the user asked you to — e.g. you have reason to believe new source strings exist that aren't in the file yet. When needed, run:

```
mix gettext.extract
mix gettext.merge priv/gettext
```

Otherwise skip straight to Step 3.

### Step 3 — Read the whole file and build a glossary

Read the **entire** `default.po` file for the locale — not just the incomplete parts. You need the full picture to stay consistent.

While reading, build a mental glossary of how recurring domain terms are *already* translated in completed (non-fuzzy, non-empty) entries. Lanttern is an educational assessment app, so pay attention to domain vocabulary like: strand, moment, assessment point, rubric, curriculum, report card, grade(s) report, composition, marking, scale, ordinal/numeric, student, staff, school cycle, etc.

When a word has more than one plausible translation, **the winner is whatever the rest of the file already uses.** Do not introduce a new variant. Match register, capitalization, and punctuation conventions of the surrounding completed entries.

### Step 4 — Identify what needs work

An entry needs translating if **either**:

1. **Empty** — `msgstr ""` (or, for plurals, any `msgstr[N] ""`), **and** it is not the file header (the very first `msgid ""` block with `msgstr ""` followed by `"Language: ...\n"` lines — leave the header untouched).
2. **Fuzzy** — the entry has a `#, ... fuzzy` flag comment. Treat the existing `msgstr` as garbage and rewrite it from the `msgid`.

### Step 5 — Translate

For each entry that needs work:

- Write a natural, idiomatic translation of the `msgid` into the target language, consistent with the Step 3 glossary.
- **Preserve everything structural:** interpolation placeholders (`%{name}`, `%{count}`, …), HTML tags, leading/trailing whitespace, newlines (`\n`), and punctuation must appear in the translation exactly as in the source. Never translate the contents of a `%{...}` placeholder.
- **Plurals:** fill every `msgstr[N]` according to the locale's `Plural-Forms` header (e.g. `pt_BR` has `nplurals=2`). Use `%{count}` where appropriate.
- **Fuzzy entries:** after writing the new translation, **remove the `fuzzy` token** from the flag comment. If `fuzzy` was the only flag, remove it but keep the other autogen flags. The line `#, elixir-autogen, elixir-format, fuzzy` becomes `#, elixir-autogen, elixir-format`.
- Do **not** touch `msgid`s, source-reference comments (`#:`), or the file header.

Use the Edit tool for these changes. Leave already-complete, non-fuzzy entries exactly as they are.

### Step 6 — Verify

After editing each file:

1. Run `mix gettext.merge priv/gettext` to normalize formatting and confirm the file still parses. This should report **0 fuzzy** for the locale and should not reintroduce fuzzy flags on the entries you just fixed.
2. Confirm there are no remaining empty translations (other than the header):

   ```
   grep -n '^msgstr ""$' priv/gettext/<locale>/LC_MESSAGES/default.po
   ```

   The only acceptable hit is the header block at the top.
3. Confirm no `fuzzy` flags remain: `grep -c fuzzy priv/gettext/<locale>/LC_MESSAGES/default.po` should print `0`.

### Step 7 — Report

Summarize per locale: how many empty entries you filled, how many fuzzy entries you rewrote, and call out any terms where you had to pick between competing existing translations (and which you chose, and why). If you ran the extract/merge tasks in Step 2, say so.
