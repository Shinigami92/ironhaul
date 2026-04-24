extends GutTest

var health: Health


func before_each() -> void:
	health = Health.new(100.0)


func test_starts_at_maximum() -> void:
	assert_eq(health.current, 100.0)
	assert_eq(health.maximum, 100.0)
	assert_false(health.is_depleted())


func test_take_damage_reduces_current() -> void:
	health.take_damage(30.0)
	assert_eq(health.current, 70.0)


func test_take_damage_clamps_at_zero() -> void:
	health.take_damage(200.0)
	assert_eq(health.current, 0.0)
	assert_true(health.is_depleted())


func test_changed_emits_on_damage() -> void:
	watch_signals(health)
	health.take_damage(20.0)
	assert_signal_emitted(health, "changed")


func test_depleted_emits_when_health_reaches_zero() -> void:
	watch_signals(health)
	health.take_damage(150.0)
	assert_signal_emitted(health, "depleted")


func test_damage_after_depletion_is_noop() -> void:
	health.take_damage(100.0)
	watch_signals(health)
	health.take_damage(50.0)
	assert_signal_not_emitted(health, "changed")
	assert_signal_not_emitted(health, "depleted")
