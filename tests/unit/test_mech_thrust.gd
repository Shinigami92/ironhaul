extends GutTest

var mech: Mech


func before_each() -> void:
	mech = Mech.new()
	mech.is_enemy = true
	mech.max_thrust = 100.0
	mech.thrust_regen_per_sec = 40.0
	mech.thrust_regen_delay_sec = 0.15
	add_child_autofree(mech)


func test_starts_at_max_thrust() -> void:
	assert_eq(mech.current_thrust, mech.max_thrust)


func test_consume_thrust_decrements_current_thrust() -> void:
	var ok := mech.consume_thrust(25.0)
	assert_true(ok)
	assert_eq(mech.current_thrust, 75.0)


func test_consume_thrust_returns_false_when_insufficient() -> void:
	mech.current_thrust = 5.0
	var ok := mech.consume_thrust(10.0)
	assert_false(ok)
	assert_eq(mech.current_thrust, 5.0)


func test_regen_paused_during_delay() -> void:
	mech.consume_thrust(50.0)
	mech._process(0.1)  # within the 0.15s regen delay window
	assert_eq(mech.current_thrust, 50.0)


func test_regen_resumes_after_delay() -> void:
	mech.consume_thrust(50.0)
	# 0.15s covers the delay; remaining 0.05s regens at 40/s = 2.0
	mech._process(0.2)
	assert_almost_eq(mech.current_thrust, 52.0, 0.01)


func test_continuous_consumption_keeps_regen_paused() -> void:
	mech.consume_thrust(20.0)
	mech._process(0.1)
	mech.consume_thrust(20.0)
	mech._process(0.1)
	mech.consume_thrust(20.0)
	assert_eq(mech.current_thrust, 40.0)


func test_regen_clamps_at_max_thrust() -> void:
	mech.consume_thrust(10.0)
	mech._process(10.0)  # way more than needed to fill
	assert_eq(mech.current_thrust, mech.max_thrust)


func test_failed_consume_still_pauses_regen() -> void:
	# Empty tank; player keeps holding thrust: each failed consume must reset
	# the regen delay, otherwise regen sneaks in between failed attempts.
	mech.current_thrust = 5.0
	var ok := mech.consume_thrust(10.0)
	assert_false(ok)
	mech._process(0.1)  # within the 0.15s delay
	assert_eq(mech.current_thrust, 5.0)


func test_failed_consume_allows_regen_after_delay() -> void:
	# Once the player stops trying (no further consume calls), regen resumes.
	mech.current_thrust = 5.0
	mech.consume_thrust(10.0)  # fails, resets delay
	mech._process(0.2)  # 0.15s delay + 0.05s of regen
	assert_almost_eq(mech.current_thrust, 7.0, 0.01)  # 5 + 40 * 0.05
