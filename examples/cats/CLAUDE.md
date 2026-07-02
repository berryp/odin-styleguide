# CLAUDE.md — cats

Guidance for AI coding agents working in this package. (This file is the
canonical rules file; `AGENTS.md` and `odin-rules.md` are copies of the same
content for tools that read a different name — see §13 of the style guide.)

## Project

`cats` is a tiny CLI that manages a JSON roster of cats. It exists to
demonstrate the Odin style guide end to end. It has **no third-party
dependencies** — only `core:` — matching the "no package manager" stance.

- Source lives in this directory; it is one package, `package cats` (§10).
- Common commands are in `mise.toml`. Prefer them over ad-hoc invocations.

Before considering a change done:

1. `mise run fmt` — format with `odinfmt` (config in `odinfmt.json`).
2. `mise run check` — type-check with the required vet flags.
3. `mise run test` — run the package tests.

## Odin Code Style

- Code MUST compile clean with: `odin build . -vet -strict-style -vet-tabs -disallow-do -warnings-as-errors`. Treat warnings as errors. Run `odinfmt` before finishing.
- Indentation: tabs. Alignment across lines: spaces (so it's tab-width independent). Never `do` single-line blocks.
- Opening brace at end of line for procs, structs, and control flow.
- Naming: Types and enum values `Ada_Case`; procedures, variables, struct fields, and package/import names `snake_case` (packages: prefer one word); constants `SCREAMING_SNAKE_CASE`.
- One package per directory; `package snake_case` matches the folder. Alias long imports: `import vmem "core:mem/virtual"`.
- Declarations: write `val: int` and `val := 5` (no space before `:`). Prefer type inference: `x := f()` not `x: T = f()`.
- Prefer the literal form `x := T { ... }` over `x: T = { ... }`. Use compound-literal initializers (`T { field = ..., }`, trailing comma) instead of field-by-field assignment. Re-init with `x = { ... }`.
- Design types so the zero value is valid; rely on Odin's zero-initialization instead of redundant init.
- Data-oriented and procedural: no OOP patterns, no inheritance, no RAII, no constructors. Structs + free procedures. Prefer concrete types over speculative generics.
- Errors are values, not exceptions. Define error types per package (enum or union); there is no universal error type.
- Propagate errors with `or_return`; supply fallbacks with `or_else`. Use `or_return` freely within a package; be deliberate about propagating errors across library boundaries.
- Use `ensure`/`assert` only for invariants and unrecoverable failures, never for errors a caller could handle.
- Use `defer` ONLY when a scope has multiple exit paths and cleanup must always run. Single-exit scopes: write cleanup inline.
- Iterate read-only with `for x in xs`; mutate elements with `for &x in xs`.
- Procedure parameters: prefer slices `[]T` (slicing with `xs[:]` is free and works for dynamic/fixed/slice). Pass `^[dynamic]T` only when you append/resize the container. Mutating elements does not need a pointer.
- Allocating procedures take `allocator := context.allocator` and pass it through (e.g. `make([]T, n, allocator)`). Match allocation to lifetime; group shared-lifetime allocations in an arena (`core:mem/virtual`) and free once.
- Use `context.temp_allocator` for scratch allocations; reset with `free_all(context.temp_allocator)` at a natural boundary. Pair every `make`/`new` with `delete`/`free` (or a `destroy_*` proc).
- Don't repurpose `context` fields for convenience; the `context` exists to let callers intercept third-party allocation/logging/assert/rng, not to avoid passing parameters.
- No package manager: vendor/copy dependencies into the repo and pin versions. Prefer `core:`/`vendor:`; copying is usually better than adding a dependency.
