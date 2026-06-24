# Lanttern — Domain Glossary

A glossary of the ubiquitous language. No implementation details — terms only.

## Strand lock

A boolean state on a **strand** (`is_locked`) that freezes the strand and
**all** of its owned data (moments, lessons, assessment points, grade
entries/markings, evidence, curriculum items, class assignments). While locked,
those mutations are blocked for ordinary staff.

- **Owned** by the strand (frozen by the lock): moments, lessons + their
  attachments/curriculum-items, assessment points + entries + evidence,
  composition components, assessment **rubrics** (+ descriptors), strand
  curriculum items, class assignments.
- **Excluded** from the lock: strand **reports** and **grade components** (both
  governed by the report-card lifecycle, not the strand); lesson **tags**
  (school-owned); and per-user state (starring, strand filters, AI chat).
- A lock is a *freeze*, not a *delete* — read access is unchanged.

## Strand lock management (permission)

The authority to **lock/unlock a strand** and to **edit a strand while it is
locked** (i.e. bypass the lock). It is *not* a general strand-administration
role: ordinary staff continue to create and edit *unlocked* strands without it.
Holders are the only users who can toggle the lock or mutate locked data.

Permission key: `strand_lock_management`.
