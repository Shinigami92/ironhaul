extends GutTest

var thrust: Thrust


func before_each() -> void:
	# maximum=100, regen=40/sec, delay=0.15s
	thrust = Thrust.new(100.0, 40.0, 0.15)


func test_starts_at_maximum() -> void:
	assert_eq(thrust.current, thrust.maximum)


func test_consume_decrements_current() -> void:
	var ok := thrust.consume(25.0)
	assert_true(ok)
	assert_eq(thrust.current, 75.0)


func test_consume_returns_false_when_insufficient() -> void:
	thrust.current = 5.0
	var ok := thrust.consume(10.0)
	assert_false(ok)
	assert_eq(thrust.current, 5.0)


func test_regen_paused_during_delay() -> void:
	thrust.consume(50.0)
	thrust.regen(0.1)  # within the 0.15s regen delay window
	assert_eq(thrust.current, 50.0)


func test_regen_resumes_after_delay() -> void:
	thrust.consume(50.0)
	# 0.15s covers the delay; remaining 0.05s regens at 40/s = 2.0
	thrust.regen(0.2)
	assert_almost_eq(thrust.current, 52.0, 0.01)


func test_continuous_consumption_keeps_regen_paused() -> void:
	thrust.consume(20.0)
	thrust.regen(0.1)
	thrust.consume(20.0)
	thrust.regen(0.1)
	thrust.consume(20.0)
	assert_eq(thrust.current, 40.0)


func test_regen_clamps_at_maximum() -> void:
	thrust.consume(10.0)
	thrust.regen(10.0)  # way more than needed to fill
	assert_eq(thrust.current, thrust.maximum)


func test_failed_consume_still_pauses_regen() -> void:
	# Empty tank; caller keeps trying to consume: each failed attempt must
	# reset the regen delay, otherwise regen sneaks in between failed attempts.
	thrust.current = 5.0
	var ok := thrust.consume(10.0)
	assert_false(ok)
	thrust.regen(0.1)  # within the 0.15s delay
	assert_eq(thrust.current, 5.0)


func test_failed_consume_allows_regen_after_delay() -> void:
	# Once the caller stops trying (no further consume calls), regen resumes.
	thrust.current = 5.0
	thrust.consume(10.0)  # fails, resets delay
	thrust.regen(0.2)  # 0.15s delay + 0.05s of regen
	assert_almost_eq(thrust.current, 7.0, 0.01)
