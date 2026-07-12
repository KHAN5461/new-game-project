extends Node

@warning_ignore("unused_signal")
signal warrior_died
@warning_ignore("unused_signal")
signal goal_reached
signal debugger_step_requested
@warning_ignore("unused_signal")
signal unit_selected(unit: Node2D)
@warning_ignore("unused_signal")
signal active_unit_changed(unit: Node2D)
@warning_ignore("unused_signal")
signal open_settings()
@warning_ignore("unused_signal")
signal enemy_killed()
@warning_ignore("unused_signal")
signal level_ended(victory: bool, msg: String)
@warning_ignore("unused_signal")
signal show_metrics(loc: int, cycles: int)
