extends GutTest

var mech: Mech


func before_each() -> void:
	mech = Mech.new()
	mech.is_enemy = true
	add_child_autofree(mech)


func test_first_barrel_is_left() -> void:
	assert_eq(mech.take_next_barrel_offset(), Mech.BARREL_LOCAL_LEFT)


func test_barrel_offsets_alternate() -> void:
	var first := mech.take_next_barrel_offset()
	var second := mech.take_next_barrel_offset()
	var third := mech.take_next_barrel_offset()
	assert_ne(first, second)
	assert_eq(first, third)
