package cats

import "core:encoding/json"
import "core:fmt"
import "core:os"

// Cat is the core record this tool manages. Its zero value — an empty name
// and an age of 0 — is a valid "unknown cat", so no constructor is needed
// (see §1/§5 of the style guide: make the zero value useful).
Cat :: struct {
	name: string,
	age:  int,
}

// Roster is the on-disk shape of the JSON file: a single object with a
// "cats" array. json.unmarshal fills this struct in directly, so the file
// format and the in-memory type stay in sync (§9).
Roster :: struct {
	cats: [dynamic]Cat,
}

// Error is this package's error type. Odin has no universal error type by
// design (§7); each package models its own as a plain value. A union's zero
// value is nil, so `return nil` means success and `if err != nil` fails.
Error :: union {
	File_Error,
	Parse_Error,
}

File_Error :: struct {
	path:   string,
	reason: string,
}

Parse_Error :: struct {
	path: string,
}

// load_roster reads and parses the roster file. It takes an allocator
// (defaulting to the context allocator, §8) so the caller owns the lifetime
// of everything parsed — the CLI hands it an arena and frees the lot at once.
load_roster :: proc(
	path: string,
	allocator := context.allocator,
) -> (
	roster: Roster,
	err: Error,
) {
	data, ok := os.read_entire_file(path, allocator)
	if !ok {
		// Convert the bare boolean into a rich, specific error value.
		return {}, File_Error{path = path, reason = "could not read file"}
	}

	// Fill `roster` in the caller's allocator. The parsed slice and the
	// strings it points at all live there, so freeing the arena frees them.
	if json.unmarshal(data, &roster, allocator = allocator) != nil {
		return {}, Parse_Error{path = path}
	}
	return roster, nil
}

// save_roster serializes the roster back to disk as pretty JSON.
save_roster :: proc(
	path: string,
	roster: Roster,
	allocator := context.allocator,
) -> Error {
	data, marshal_err := json.marshal(roster, {pretty = true}, allocator)
	if marshal_err != nil {
		return Parse_Error{path = path}
	}
	if !os.write_entire_file(path, data) {
		return File_Error{path = path, reason = "could not write file"}
	}
	return nil
}

// add_cat appends to the roster. It takes ^[dynamic]Cat because appending
// changes the container's length, which needs the dynamic array itself — a
// plain []Cat slice could not grow (§9).
add_cat :: proc(cats: ^[dynamic]Cat, name: string, age: int) {
	append(cats, Cat{name = name, age = age})
}

// print_cats only reads, so it takes a slice (§9). Slicing a dynamic array
// with `xs[:]` is free, and a slice parameter accepts dynamic, fixed, and
// slice sources alike.
print_cats :: proc(cats: []Cat) {
	if len(cats) == 0 {
		fmt.println("(no cats)")
		return
	}
	for cat in cats {
		fmt.printfln("%s (age %d)", cat.name, cat.age)
	}
}

// find_oldest returns the oldest cat and whether one was found. It reports
// "empty" via ok=false rather than a sentinel, so callers can pair it with
// or_else and a useful zero value (§5/§7).
find_oldest :: proc(cats: []Cat) -> (oldest: Cat, ok: bool) {
	for cat in cats {
		if !ok || cat.age > oldest.age {
			oldest = cat
			ok = true
		}
	}
	return oldest, ok
}

// birthday_all mutates the elements in place. Slice elements are
// addressable, so `for &cat` is enough — no pointer to the container is
// needed to change the elements themselves (§6/§9).
birthday_all :: proc(cats: []Cat) {
	for &cat in cats {
		cat.age += 1
	}
}
