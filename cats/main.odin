package cats

import "core:fmt"
import vmem "core:mem/virtual"
import "core:os"
import "core:strconv"

// The roster file used when the caller doesn't pass one. Constants are
// SCREAMING_SNAKE_CASE (§3).
DEFAULT_ROSTER_PATH :: "cats.json"

// Command is the sub-command the user asked for. Enum values are Ada_Case (§3).
Command :: enum {
	List,
	Add,
	Oldest,
	Birthday,
}

main :: proc() {
	// All parsed data lives in one arena tied to the whole run and freed in a
	// single shot at exit (§8). ensure() guards an unrecoverable setup
	// failure — not something a caller could handle, so it is an assertion,
	// not an Error value (§7).
	arena: vmem.Arena
	ensure(vmem.arena_init_growing(&arena) == nil)
	defer vmem.arena_destroy(&arena)
	arena_alloc := vmem.arena_allocator(&arena)

	// json.marshal uses the temp allocator for scratch; reset it on the way
	// out rather than freeing piecemeal (§8).
	defer free_all(context.temp_allocator)

	if err := run(os.args, arena_alloc); err != nil {
		// Errors are values: a type switch turns each variant into a
		// specific, actionable message instead of one catch-all string (§7).
		switch e in err {
		case File_Error:
			fmt.eprintfln("error: %s (%s)", e.reason, e.path)
		case Parse_Error:
			fmt.eprintfln("error: %s is not valid roster JSON", e.path)
		}
		os.exit(1)
	}
}

// run does the real work so main stays about process concerns (arena, exit
// code). It returns this package's Error type; `or_return` propagates
// failures from the helpers without boilerplate (§7).
run :: proc(args: []string, allocator := context.allocator) -> Error {
	command, path := parse_args(args)

	roster := load_roster(path, allocator) or_return

	switch command {
	case .List:
		print_cats(roster.cats[:])
	case .Oldest:
		// find_oldest reports "no cats" with ok=false; or_else supplies the
		// zero-value Cat, which is itself a valid empty record (§5).
		oldest := find_oldest(roster.cats[:]) or_else Cat{}
		print_cats([]Cat{oldest})
	case .Add:
		name, age, ok := parse_add(args)
		if !ok {
			fmt.eprintln("usage: cats add <name> <age> [file]")
			os.exit(2)
		}
		add_cat(&roster.cats, name, age)
		save_roster(path, roster, allocator) or_return
		fmt.printfln("added %s (age %d)", name, age)
	case .Birthday:
		birthday_all(roster.cats[:])
		save_roster(path, roster, allocator) or_return
		fmt.println("everyone is a year older")
	}
	return nil
}

// parse_args picks the command and the roster file path out of the argument
// vector. It never fails: unknown or missing commands fall back to listing
// the default file, keeping the happy path simple.
parse_args :: proc(args: []string) -> (command: Command, path: string) {
	command = .List
	path = DEFAULT_ROSTER_PATH
	if len(args) < 2 {
		return command, path
	}

	switch args[1] {
	case "add":
		command = .Add
	case "oldest":
		command = .Oldest
	case "birthday":
		command = .Birthday
	case:
		command = .List
	}

	// The optional file path is the last positional argument. For `add` it
	// only appears once name and age are also present.
	if command == .Add {
		if len(args) >= 5 {
			path = args[len(args) - 1]
		}
	} else if len(args) >= 3 {
		path = args[len(args) - 1]
	}
	return command, path
}

// parse_add extracts the name and age operands for the `add` command.
parse_add :: proc(args: []string) -> (name: string, age: int, ok: bool) {
	if len(args) < 4 {
		return "", 0, false
	}
	name = args[2]
	// or_else supplies a fallback so a bad age becomes a plain -1 we can
	// reject, instead of two-value juggling (§7).
	age = strconv.parse_int(args[3], 10) or_else -1
	if age < 0 {
		return "", 0, false
	}
	return name, age, true
}
