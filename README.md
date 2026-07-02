# Odin Code Style Guide

A practical style and idiom guide for writing Odin, distilled from:

- The official **Naming and style convention** in the `odin-lang/examples` wiki
- The idiomatic code in the `odin-lang/examples` repository
- Ginger Bill's articles on the language's philosophy, error handling (the *Value Propagation Experiment*, parts 1 & 2), the *implicit `context` system*, and *why Odin has no package manager*

Where the sources give a rule, this guide states it. Where they give rationale, it summarizes the "why" so the rules are memorable rather than arbitrary. Full source links are listed at the end. Guidance on configuring AI coding agents to follow this style lives in its own section (§13) so the rest of the document stays language-focused.

---

## 1. Design principles: how to approach Odin

Most friction people feel in Odin comes from importing habits from other languages and fighting the grain of this one. Odin is a small, explicit, **data-oriented procedural** language. It is *not* object-oriented, it has no garbage collector, no exceptions, no RAII, and no package manager — and each of those is a deliberate choice, not a missing feature. The fastest way to become productive is to stop reaching for the constructs you'd use elsewhere and do things "the Odin way."

Ginger Bill's *Pragmatism in Programming Proverbs* captures the mindset the language is built around. A few load-bearing ideas, paraphrased (with one of his own phrasings kept intact):

- **Programs transform data into other data.** Design around the data and its layout first; the algorithms tend to follow. Don't model your program around real-world "objects."
- **Solve the specific problem you have, not a general one you might have.** Generality throws away information about the specific case; reach for it only when a concrete need appears. Prefer concrete types and procedures over speculative abstraction.
- **"Make the zero value useful."** Design types so the all-zero state is valid and meaningful, then lean on Odin's automatic zero-initialization instead of writing constructors that *must* run.
- **Errors are nothing special** — they're ordinary values handled with ordinary code (see §7), not a separate control-flow mechanism.
- **Copying is usually better than dependency.** A little duplication is often cheaper than taking on a dependency you must now maintain and trust (this underpins §11).
- **Clear is better than clever; simplicity is worth the effort; be kind to your future self.** Favor the least surprising construct.

### Coming from another language

| If you're coming from… | Drop this habit | Do this in Odin instead |
| ---------------------- | --------------- | ----------------------- |
| C++, Java, C# | Classes, inheritance, methods, constructors/destructors, RAII | Plain `struct`s + free `proc`s; explicit init via compound literals; `defer` or explicit cleanup; the `context` allocator for interception |
| C++, Rust, Python | Exceptions / `try`/`catch` | Errors are values; return them and handle with `if err != nil`, `or_return`, `or_else` (§7) |
| Rust | Borrow checker, lifetimes, `?`, heavy trait generics | You manage lifetimes explicitly with allocators/arenas (§8); use `or_return`; use parametric polymorphism sparingly |
| Go | Built-in `error` interface, GC, `go`/channels-first mindset | Per-package error types (no universal `error`); manual memory + allocators; `context` is for *interception*, not cancellation |
| Python, JavaScript | `pip`/`npm`, pulling many small dependencies | Manual vendoring; a strong `core`/`vendor` library; copy small things (§11) |

The golden rule: **if the compiler's vet/style checks (§2) or the language are pushing back, that's usually a signal to write it the idiomatic way rather than to work around them.**

---

## 2. The one non-negotiable: compile clean under the vet flags

All idiomatic Odin (and everything accepted into the official examples repo) must compile cleanly with:

```
odin build . -vet -strict-style -vet-tabs -disallow-do -warnings-as-errors
```

These flags enforce a large part of "style" mechanically, so you don't have to argue about it:

- `-vet` — flags unused variables, shadowing, and other common mistakes.
- `-strict-style` — enforces the canonical formatting rules (brace placement, spacing).
- `-vet-tabs` — requires tabs for indentation.
- `-disallow-do` — forbids the single-line `do` form of blocks.
- `-warnings-as-errors` — no warnings survive; fix them all.

Treat a warning as a build failure. If the compiler complains, the code is not done. Run `odin build -help` to see what each flag checks.

---

## 3. Naming convention

The rule of thumb: **`Ada_Case` for types, `snake_case` for values.**

| Kind                | Case                                  | Example                       |
| ------------------- | ------------------------------------- | ----------------------------- |
| Types               | `Ada_Case`                            | `Camera`, `Http_Request`      |
| Enum values         | `Ada_Case`                            | `.Running`, `.Not_Found`      |
| Procedures          | `snake_case`                          | `load_sound`, `parse_header`  |
| Local variables     | `snake_case`                          | `window_width`, `cat`         |
| Struct fields       | `snake_case`                          | `position`, `age`             |
| Constants           | `SCREAMING_SNAKE_CASE`                | `MAX_ENTITIES`, `PI`          |
| Package / import name | `snake_case` (prefer a single word) | `package json`, `import vmem` |

Notes:

- **One package per directory.** The package name is `snake_case` and, by convention, matches the directory. Prefer short, single-word package names.
- **Alias long import paths** to a short local name: `import vmem "core:mem/virtual"`. Then reference members as `vmem.Arena`.
- `Ada_Case` means each underscore-separated word is capitalized (`Some_Type`), not `PascalCase` and not `camelCase`.

---

## 4. Formatting

### Indentation and alignment

- **Tabs for indentation. Spaces for alignment.** Indent scopes with tabs; when you align things across lines (e.g. a parameter list broken onto several lines), pad with spaces so the alignment is identical regardless of anyone's tab width. A single aligned line will therefore legitimately contain tabs (for indentation) followed by spaces (for alignment).

```odin
some_proc :: proc(a: int, lot: f32, of: string, parameters: f64,
                  is: f32, fun: string) {
	fmt.println(fun)
}
```

### Braces

- **Opening brace at end-of-line** (K&R style), for procedures, types, and control flow alike:

```odin
some_proc :: proc() {
}

Some_Type :: struct {
}
```

### Declaration spacing

Write:

```odin
val: int
val := 5
```

Not `val : int`, not `val:= 5`, not `val: = 5`. The colon hugs the name; the space goes after it.

### `do` blocks

Disallowed (`-disallow-do`). Always use braces.

---

## 5. Declarations and initialization

### Prefer type inference

Let the value determine the type; don't restate it.

```odin
sound := load_sound(filename)   // good
sound: Sound = load_sound(filename)   // avoid
```

Be explicit only when it genuinely aids clarity. Two equally acceptable forms exist for simple literals: `val: f32 = 5` and `val := f32(5)`.

### Prefer the `T { ... }` literal form over an explicitly typed `= { ... }`

```odin
cam := Camera {              // good
	position = { 50, 50, 10 },
}

cam: Camera = {              // avoid
	position = { 50, 50, 10 },
}
```

Exception: when assigning a specific union variant on one line you do need the explicit type, e.g. `var: Some_Union = Some_Union_Variant {}`.

### Use initializers instead of field-by-field assignment

```odin
cam := Camera {              // good
	position = { 50, 50, 10 },
	offset   = { 10, 20 },
	zoom     = 2,
}

cam: Camera                  // avoid
cam.position = { 50, 50, 10 }
cam.offset   = { 10, 20 }
cam.zoom     = 2
```

Note the compound-literal syntax uses `=` for fields, and a trailing comma on the last field is idiomatic. To re-initialize an existing value, assign with `=` and an untyped literal: `cam = { position = ..., zoom = ... }`.

### Lean on the zero value

Odin zero-initializes by default. A freshly declared `cat: Cat` has every field zeroed (`""`, `0`, `nil`, etc.). Design types so the zero value is a valid, useful state (see §1), and you can often skip explicit initialization entirely.

---

## 6. Control flow and `defer`

### Don't overuse `defer`

Use `defer` when a scope has **multiple exit paths** and some cleanup must run regardless of which path is taken. If a scope has only one way out, just write the cleanup at the end — linear code is easier to read. `defer` has a real readability cost because it moves code away from where it appears to run.

```odin
data, err := os.read_entire_file(path, context.allocator)
if err != nil {
	return
}
defer delete(data)   // justified: several later returns, one cleanup
```

### Iteration

- Read-only loop: `for x in xs { ... }`.
- Mutating loop: take the element by reference with `&`: `for &x in xs { x.field = ... }`.

---

## 7. Error handling

Odin's philosophy: **errors are ordinary values, not a special mechanism.** There are no exceptions and there will never be any. This shapes the idioms.

### Errors are values, defined per package

Model errors as a plain value type owned by the package — usually an `enum` or a (discriminated) `union`. There is no universal `error` base type by design. A distinct type per package keeps error information specific instead of collapsing everything into one "error or not" boolean.

```odin
if err != nil {
	// handle, wrap, or return
}
// or, for enum-based errors:
if err != .None {
	return
}
```

### `or_return` — propagate early

`or_return` is a suffix operator that returns early if the trailing value is an error (non-`nil` / non-`false`). It replaces the `x, err := f(); if err != nil { return }` boilerplate and is heavily used in `core:` packages that need it.

```odin
foo() or_return
x := bar() or_return
```

Use it freely *within* a package or library. Be deliberate about propagating errors *across* library boundaries — pushing every error up the stack unhandled turns rich error values back into a glorified boolean and loses the specific information that made them valuable.

### `or_else` — supply a fallback

`or_else` is a binary operator that provides a default for optional-ok expressions (map lookups, type assertions, etc.).

```odin
i := m["hellope"] or_else 123
v := maybe_value.? or_else default_value
```

### `ensure` / `assert` — for invariants, not for recoverable errors

For conditions that must hold (programmer errors, unrecoverable setup failures), use `ensure` (checked in release too) or `assert`. Don't use them for errors a caller could reasonably handle.

```odin
arena_err := vmem.arena_init_growing(&arena)
ensure(arena_err == nil)
```

---

## 8. Memory, allocators, and `context`

### Two allocators live on the `context`

Every scope has an implicit `context`. It carries, among other things:

- `context.allocator` — the general-purpose allocator (defaults to a heap-like allocator on most platforms).
- `context.temp_allocator` — a **growing arena**, ideal for short-lived scratch allocations. Reset it with `free_all(context.temp_allocator)` at a natural boundary (e.g. per frame, per request) instead of freeing individual allocations.

The `context` also carries the `logger`, `assertion_failure_proc`, `random_generator`, and `user_ptr`/`user_index`. Its real purpose is **intercepting third-party code** — overriding how a library allocates, logs, asserts, or generates randomness without editing it — not saving keystrokes.

### Design procedures to take an allocator

APIs that allocate should accept an allocator parameter defaulting to the context allocator:

```odin
make_thing :: proc(allocator := context.allocator) -> Thing {
	// ...
}
```

This lets callers redirect allocation (e.g. to an arena) without you hardcoding anything. `core:` procedures like `os.read_entire_file(path, allocator)` and `make([]T, n, allocator)` follow this pattern — pass the allocator explicitly when you have one.

### Match allocation to lifetime; prefer arenas for grouped lifetimes

An allocator encodes a lifetime for a set of allocations. When several allocations share a lifetime, group them in an arena and free them in one shot rather than tracking each individually:

```odin
arena: vmem.Arena
ensure(vmem.arena_init_growing(&arena) == nil)
arena_alloc := vmem.arena_allocator(&arena)

data := os.read_entire_file(path, arena_alloc)
// ... more allocations on arena_alloc ...

vmem.arena_destroy(&arena)   // frees everything at once
```

### Free what you allocate

Pair allocations with their cleanup: `make`/`delete`, `new`/`free`, and library `destroy_*` procedures. Use `defer` for the cleanup only when the scope has multiple exit paths (see §6).

```odin
data, err := os.read_entire_file(path, context.allocator)
if err != nil { return }
defer delete(data)

json_data, jerr := json.parse(data)
if jerr != .None { return }
defer json.destroy_value(json_data)
```

### Optional: enforce explicit allocators per file

If you want to forbid the implicit `allocator := context.allocator` default in a file and force every allocating call to name its allocator, add the file tag:

```odin
#+vet explicit-allocators
```

---

## 9. Data structures and procedure parameters

### Prefer slices (`[]T`) for parameters

Accept `[]T` rather than `[dynamic]T` or a fixed array wherever possible. Slicing (`arr[:]`) is free — a slice is just a `{data, len}` pair, no allocation — and a slice parameter works with dynamic arrays, fixed arrays, and other slices alike, making the procedure more reusable.

```odin
print_cats :: proc(cats: []Cat)          { for c in cats { ... } }        // read
mutate_cats :: proc(cats: []Cat)         { for &c in cats { c.age = ... } } // mutate elements
```

You can mutate the *elements* through a plain `[]T` slice (the elements are addressable); you only need a pointer when you change the container itself.

### Pass `^[dynamic]T` only when you change the container's length

Appending or otherwise resizing requires the dynamic array itself, so pass a pointer:

```odin
add_cat :: proc(cats: ^[dynamic]Cat, name: string) {
	append(cats, Cat { name = name, age = 0 })
}
```

Call it with `add_cat(&all_the_cats, "Klucke")`, and pass the read/mutate procedures a slice with `all_the_cats[:]`.

### Type assertions and unions

Use the `.(T)` assertion to extract a variant from a union or `any`-like value; combine with `or_else` for a fallback.

```odin
root := json_data.(json.Object)
w    := root["window_width"].(json.Float)
```

---

## 10. File and package layout

- One directory = one package; `package snake_case` at the top of every file in it.
- Group imports at the top, `core:` and `vendor:` libraries together; alias long paths to short names.
- Most runnable examples are a single package built with `odin run .`. Keep example/program packages small and focused.

---

## 11. Package management (there isn't one — by design)

Odin ships **no package manager**, and this is intentional. Bill draws a sharp distinction between four things people conflate: *packages* (Odin has them, built into the language), *package repositories* (fine — that's just discovery/search), *build systems* (Odin minimizes the need; most projects build with `odin build .` because linking info lives in source via the `foreign` system), and *package managers* (the part he objects to).

The core objection: a package manager automates pulling a dependency, then its dependencies, then theirs, recursively — which he calls **"the automation of dependency hell."** The argument isn't that dependencies are bad but that automating their acquisition removes the friction that makes you *think* about each one. Doing it manually forces the question "do I actually want this?" and makes you careful when updating.

Related points Bill (and the guests he quotes) make:

- **Each dependency is a liability** — not only a security risk but a bug and maintenance liability. When something you depend on breaks, *you* are on the hook. Owning your code means you can fix it.
- **A strong standard library removes most of the need.** Languages like Go avoid dependency sprawl largely because "batteries included" means you rarely need third-party code. Odin follows the same instinct with its `core` and `vendor` libraries.
- **"Copying is usually better than dependency."** For small needs, vendor or copy the code rather than taking on an external, versioned dependency.
- Programmers tend to be **too high-trust** with random internet code, vetting little of what they pull in.

### How to actually manage dependencies

Per the Odin FAQ, the recommended approach is **manual dependency management**: copy/vendor each dependency into your project and pin it to a specific version. This keeps a codebase stable, reliable, and maintainable, and keeps the real complexity visible instead of hidden. As the FAQ puts it: *"Not everything that can be automated ought to be automated."*

Practical guidance:

- Vendor third-party Odin code into your repository (e.g. a `shared/` or vendored collection) and commit it, rather than fetching it at build time.
- Pin exact versions/commits; update deliberately and review what changed.
- Prefer `core:` and `vendor:` first; reach for third-party code only when there's a real, specific need.
- Keep the dependency count low enough that you could audit each one.

---

## 12. Tooling: OLS and odinfmt

Use the community language server, **OLS (Odin Language Server)** — <https://github.com/DanielGavin/ols>. It's the standard editor tooling for Odin and is strongly recommended for any project. Note that OLS tracks the **master** branch of Odin, so keep it reasonably in sync with your compiler.

What it gives you: completion, go-to-definition, hover, document symbols, find-references, rename, signature help, and semantic tokens. Editor support includes VS Code (Marketplace extension `DanielGavin.ols`), Neovim (`nvim-lspconfig`'s `ols`), Vim (Coc), Sublime, Emacs (lsp-mode / eglot), Helix (enabled by default), Micro, and Kate.

### Configure it with `ols.json`

Put an `ols.json` at the workspace root so the server can index your collections and check the right packages:

```json
{
	"$schema": "https://raw.githubusercontent.com/DanielGavin/ols/master/misc/ols.schema.json",
	"collections": [
		{ "name": "shared", "path": "/path/to/shared" }
	],
	"enable_hover": true,
	"enable_snippets": true,
	"enable_document_symbols": true,
	"profile": "default",
	"profiles": [
		{ "name": "default", "checker_path": ["src"], "defines": { "ODIN_DEBUG": "false" } }
	]
}
```

You can pass checker flags through OLS to keep the editor honest with the project's style — e.g. `checker_args` / init options set to `-strict-style` so you see style violations as you type.

### Formatting with `odinfmt`

OLS bundles **odinfmt**, the formatter (enable with `enable_format`, on by default). Configure it via an `odinfmt.json` at the repo root and, ideally, run it on save so formatting is never a manual chore:

```json
{
	"$schema": "https://raw.githubusercontent.com/DanielGavin/ols/master/misc/odinfmt.schema.json",
	"character_width": 80,
	"tabs": true,
	"tabs_width": 4
}
```

Keep `"tabs": true` to match the tabs-for-indentation rule (§4). Other useful options include `sort_imports`, `brace_style` (`K_And_R` matches §4), `indent_cases`, and `align_struct_fields`. A shared `odinfmt.json` in the repo means every contributor formats identically.

---

## 13. Configuring AI coding agents

To make an AI coding assistant follow this style, drop a rules file at the repository root. The common conventions are **`CLAUDE.md`** (Claude Code / Claude) and **`AGENTS.md`** (a cross-tool convention many other agents read); the content below works for either — some teams keep one file and symlink or copy it to the other name. Keep the rules short, imperative, and specific; agents follow tight directives better than prose.

Also point the agent at the project's tooling so its output matches everyone else's: have it build with the vet flags (§2) and run `odinfmt` (§12) before considering a change done.

Copy the block below into `CLAUDE.md` (or `AGENTS.md`):

```md
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
```

---

### Sources

- Naming and style convention — `odin-lang/examples` wiki: <https://github.com/odin-lang/examples/wiki/Naming-and-style-convention>
- Idiomatic code — `odin-lang/examples`: <https://github.com/odin-lang/examples>
- Pragmatism in Programming Proverbs — <https://www.gingerbill.org/article/2020/05/31/programming-pragmatist-proverbs/>
- The Value Propagation Experiment (parts 1 & 2) — <https://www.gingerbill.org/article/2021/07/05/value-propagation-experiment/> and <https://www.gingerbill.org/article/2021/09/06/value-propagation-experiment-part-2/>
- context — Odin's Most Misunderstood Feature — <https://www.gingerbill.org/article/2025/12/15/odins-most-misunderstood-feature-context/>
- Exceptions — And Why Odin Will Never Have Them — <https://www.gingerbill.org/article/2018/09/05/exceptions-and-why-odin-will-never-have-them/>
- Package Managers are Evil — <https://www.gingerbill.org/article/2025/09/08/package-managers-are-evil/> (and the Odin FAQ: <https://odin-lang.org/docs/faq/>)
- OLS — Odin Language Server — <https://github.com/DanielGavin/ols>
