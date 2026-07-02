# cats — a worked example of the Odin style guide

`cats` is a small command-line tool that manages a JSON roster of cats. It is
deliberately tiny, but it is written to exercise **every** section of the
[Odin Code Style Guide](../README.md) so you can see the rules applied in
real code rather than in isolated snippets.

It uses only the Odin standard library (`core:`) — no third-party
dependencies — matching the guide's "no package manager" stance (§11).

## Layout

```
cats
├── main.odin        # entry point, arg parsing, command dispatch
├── roster.odin      # the Cat/Roster types, load/save, and operations
├── roster_test.odin # `odin test` unit tests
├── cats.json        # sample data
├── CLAUDE.md        # AI-agent rules (canonical)
├── AGENTS.md        # copy of CLAUDE.md for tools that read this name
├── odinfmt.json     # odinfmt configuration
├── ols.json         # OLS (language server) configuration
└── mise.toml        # common commands (build/run/check/test/fmt)
```

Everything is one package (`package cats`) in one directory — one directory,
one package (§10).

## Build and run

Install the Odin compiler (<https://odin-lang.org/docs/install/>) so `odin`
and `odinfmt` are on your PATH. Then, from this directory:

```sh
# With mise (recommended — the vet flags are baked into the tasks):
mise run build            # build ./cats
mise run run -- list      # build and run: list the roster
mise run check            # type-check only
mise run test             # run the unit tests
mise run fmt              # format with odinfmt

# Or directly, always with the style-guide vet flags (§2):
odin run . -vet -strict-style -vet-tabs -disallow-do -warnings-as-errors -- list
```

### Commands

```sh
cats list [file]              # print every cat (default: cats.json)
cats oldest [file]            # print the oldest cat
cats add <name> <age> [file]  # add a cat and write the file back
cats birthday [file]          # age every cat by one year and write back
```

Example session:

```sh
$ mise run run -- list
Klucke (age 3)
Mittens (age 7)
Sylvester (age 5)

$ mise run run -- oldest
Mittens (age 7)

$ mise run run -- add Whiskers 1
added Whiskers (age 1)
```

## Where each rule shows up

| Guide section | Where to look |
| --- | --- |
| §2 Vet flags | `mise.toml` bakes `-vet -strict-style -vet-tabs -disallow-do -warnings-as-errors` into every task |
| §3 Naming | `Cat`, `Roster`, `Command` (Ada_Case types); `.List` (Ada_Case enum values); `load_roster`, `add_cat` (snake_case procs); `DEFAULT_ROSTER_PATH` (SCREAMING_SNAKE_CASE) |
| §4 Formatting | tabs for indentation throughout; K&R braces; `import vmem "core:mem/virtual"` aliasing |
| §5 Declarations | type inference (`arena_alloc := ...`), compound-literal init (`Cat{name = ..., age = ...}`), useful zero value (`Cat{}` as the empty record) |
| §6 Control flow / `defer` | `defer` used in `main` where the scope has several exit paths; `for cat in cats` (read) vs `for &cat in cats` (mutate) in `roster.odin` |
| §7 Error handling | the per-package `Error` union (`File_Error`/`Parse_Error`), `or_return` in `run`, `or_else` for fallbacks, `ensure` for the arena invariant, a type `switch` to render each variant |
| §8 Memory / allocators / `context` | a growing arena in `main` frees everything at once; procs take `allocator := context.allocator`; `free_all(context.temp_allocator)` for scratch |
| §9 Data structures / params | `[]Cat` slice params for read/mutate; `^[dynamic]Cat` for `add_cat` (which appends); `roster.cats[:]` slicing |
| §10 File / package layout | one directory, one `package cats`, grouped/sorted imports |
| §11 No package manager | `core:`-only; no vendored or fetched dependencies |
| §12 Tooling | `odinfmt.json` and `ols.json` in this directory; `mise run fmt` |
| §13 AI agents | `CLAUDE.md` / `AGENTS.md` / `odin-rules.md` |

## Copying this into your own project

The `odinfmt.json`, `ols.json`, and `odin-rules.md` files here are ready to
drop into any Odin project's root. Copy `odin-rules.md` to `CLAUDE.md` and/or
`AGENTS.md` for your agent of choice, and adapt `mise.toml` to your layout.
