package cats

import "core:testing"

@(test)
test_find_oldest :: proc(t: ^testing.T) {
	cats := []Cat {
		{name = "a", age = 3},
		{name = "b", age = 9},
		{name = "c", age = 5},
	}
	oldest, ok := find_oldest(cats)
	testing.expect(t, ok)
	testing.expect_value(t, oldest.name, "b")
	testing.expect_value(t, oldest.age, 9)
}

@(test)
test_find_oldest_empty :: proc(t: ^testing.T) {
	oldest, ok := find_oldest(nil)
	testing.expect(t, !ok)
	// The zero value is a valid empty Cat (§5).
	testing.expect_value(t, oldest, Cat{})
}

@(test)
test_add_cat :: proc(t: ^testing.T) {
	cats: [dynamic]Cat
	defer delete(cats)

	add_cat(&cats, "Klucke", 2)
	testing.expect_value(t, len(cats), 1)
	testing.expect_value(t, cats[0].name, "Klucke")
	testing.expect_value(t, cats[0].age, 2)
}

@(test)
test_birthday_all :: proc(t: ^testing.T) {
	cats := []Cat{{name = "a", age = 1}, {name = "b", age = 4}}
	birthday_all(cats)
	testing.expect_value(t, cats[0].age, 2)
	testing.expect_value(t, cats[1].age, 5)
}
