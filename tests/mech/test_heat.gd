extends GutTest

var heat: Heat


func before_each() -> void:
	# maximum=100, decay=10/sec, cool_threshold=30
	heat = Heat.new(100.0, 10.0, 30.0)


func test_starts_at_zero() -> void:
	assert_eq(heat.current, 0.0)
	assert_eq(heat.maximum, 100.0)
	assert_false(heat.is_overheated)


func test_apply_increments_current() -> void:
	heat.apply(30.0)
	assert_eq(heat.current, 30.0)


func test_apply_clamps_at_maximum() -> void:
	heat.apply(200.0)
	assert_eq(heat.current, heat.maximum)


func test_overheat_emits_signal_and_sets_flag() -> void:
	watch_signals(heat)
	heat.apply(heat.maximum)
	assert_signal_emitted(heat, "overheated")
	assert_true(heat.is_overheated)


func test_cooled_emits_after_decay_past_threshold() -> void:
	watch_signals(heat)
	heat.apply(heat.maximum)
	# Decays at 10/sec; threshold=30; max=100 → need >7 seconds to drop below 30.
	heat.decay(8.0)
	assert_signal_emitted(heat, "cooled")
	assert_false(heat.is_overheated)


func test_decay_does_not_go_negative() -> void:
	heat.apply(10.0)
	heat.decay(5.0)  # would decay by 50; clamps at 0
	assert_eq(heat.current, 0.0)
