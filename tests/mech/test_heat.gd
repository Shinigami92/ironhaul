extends GutTest

var mech: Mech


func before_each() -> void:
	mech = Mech.new()
	# Skip camera + movement + weapon attachment by pretending this is an enemy.
	# Heat and damage logic still runs; we just avoid side-effects unrelated to these tests.
	mech.is_enemy = true
	mech.max_heat = 100.0
	mech.heat_decay_per_sec = 10.0
	mech.overheat_cool_threshold = 30.0
	add_child_autofree(mech)


func test_apply_heat_increments_current_heat() -> void:
	mech.apply_heat(30.0)
	assert_eq(mech.current_heat, 30.0)


func test_apply_heat_clamps_at_max() -> void:
	mech.apply_heat(200.0)
	assert_eq(mech.current_heat, mech.max_heat)


func test_overheat_emits_signal_and_sets_flag() -> void:
	watch_signals(mech)
	mech.apply_heat(mech.max_heat)
	assert_signal_emitted(mech, "overheated")
	assert_true(mech.is_overheated)


func test_cannot_fire_when_overheated() -> void:
	mech.apply_heat(mech.max_heat)
	assert_false(mech.can_fire())


func test_can_fire_when_healthy() -> void:
	assert_true(mech.can_fire())


func test_cooled_emits_after_decay_past_threshold() -> void:
	watch_signals(mech)
	mech.apply_heat(mech.max_heat)
	# Heat decays at 10/sec; threshold is 30; max 100 => need > 7s to dip below 30.
	mech._process(8.0)
	assert_signal_emitted(mech, "cooled")
	assert_false(mech.is_overheated)
	assert_true(mech.can_fire())


func test_heat_does_not_go_negative() -> void:
	mech.apply_heat(10.0)
	mech._process(5.0)  # would decay by 50; clamps at 0
	assert_eq(mech.current_heat, 0.0)
