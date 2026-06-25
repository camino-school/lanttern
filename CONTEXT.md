# Lanttern — Domain Glossary

A glossary of the ubiquitous language. No implementation details — terms only.

## Strand lock

A boolean state on a **strand** (`is_locked`) that freezes its **assessment and
marking** so the grade families saw can't change after a report card is shared.
While locked, those mutations are blocked for ordinary staff. The lock is a
manual, reversible action — not an automatic lifecycle side effect.

- **Frozen** by the lock: **assessment points** (and their order), **marking**
  (assessment point entries), and **composition structure** (which components
  make up a composed grade, and their weights).
- **Left editable** while locked (not assessment/marking, so they can't change a
  shared grade): strand details, moments, lessons + attachments/curriculum-items,
  rubrics + descriptors + AP↔rubric links, strand curriculum items, class
  assignments, and entry **evidence**.
- **Outside the lock entirely** (governed elsewhere): strand **reports** and
  **grade components** (report-card lifecycle); lesson **tags** (school-owned);
  per-user state (starring, strand filters, AI chat).
- A lock is a *freeze*, not a *delete* — read access is unchanged.

## Strand lock management (permission)

The authority to **lock/unlock a strand** and to **edit a strand while it is
locked** (i.e. bypass the lock). It is *not* a general strand-administration
role: ordinary staff continue to create and edit *unlocked* strands without it.
Holders are the only users who can toggle the lock or mutate locked data.

Permission key: `strand_lock_management`.
