# Global instructions

These apply in every project. A project's own CLAUDE.md wins on conflict.

## Code changes

Binding as written; `/andrej-karpathy-skills:karpathy-guidelines` holds the full text.

**Think before coding.** State assumptions explicitly and ask when uncertain. If several
interpretations exist, present them instead of silently picking one. If a simpler approach
exists, say so.

**Simplicity first.** Minimum code that solves the problem. No speculative features, no
abstractions for single-use code, no unrequested configurability, no error handling for
impossible states. If 200 lines could be 50, rewrite it.

**Surgical changes.** Every changed line traces to the request. Don't improve adjacent code,
comments, or formatting. Match existing style. Remove only the orphans your own change
created; mention pre-existing dead code rather than deleting it.

**Goal-driven execution.** Turn the task into a verifiable goal ("fix the bug" → "write a
test that reproduces it, then make it pass") and name the verification step for each step of
a multi-step plan.

## Comments

Default to none. A comment must earn its line.

- Comment only the *why*: a non-obvious constraint, a workaround and its cause, an invariant
  the reader cannot infer, a spec or issue reference. Never the *what*.
- One line, two at most. An explanation needing a paragraph belongs in a commit message or a
  docs file — or the code needs restructuring.
- No prose blocks above functions, no section banners, no decorative separators.
- No narration of the edit ("changed X to Y", "new helper", "as requested"). That is the
  diff's job.
- Docstrings only where the language or the file already uses them, and then one line unless
  the neighbours are longer.
- Match the file's existing comment density. A file with no comments gets no new ones.
