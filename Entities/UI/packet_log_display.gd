class_name PacketLogDisplay extends Control

@onready var log_text: RichTextLabel = %LogText
@onready var stats_label: Label = %StatsLabel

var total_packets: int = 0
var dropped_packets: int = 0
var delayed_packets: int = 0
var passed_packets: int = 0

func add_log_entry(action: String, details: String) -> void:
	match action:
		"DROPPED":
			dropped_packets += 1
			log_text.push_color(Color(0.957, 0.365, 0.388, 1))  ## Soft red
		"DELAYED":
			delayed_packets += 1
			log_text.push_color(Color(1.0, 0.784, 0.298, 1))  ## Amber
		"PASSED":
			passed_packets += 1
			log_text.push_color(Color(0.329, 0.816, 0.498, 1))  ## Mint green
		_:
			log_text.push_color(Color(0.702, 0.737, 0.804, 1))  ## Muted blue-white

	total_packets += 1

	var proto := ""
	var src := ""
	var dst := ""
	var delay := ""

	for part in details.split(";"):
		if part.begins_with("proto="): proto = part.substr(6)
		elif part.begins_with("src="): src = part.substr(4)
		elif part.begins_with("dst="): dst = part.substr(4)
		elif part.begins_with("delay="): delay = part.substr(6)

	var time_dict = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d:%02d" % [time_dict.hour, time_dict.minute, time_dict.second]

	var action_str = ("[%s]" % action).rpad(11, " ")
	var formatted_log = "%s - %s;  %s - src =  %s → dst = %s" % [action_str, time_str, proto, src, dst]
	if delay != "":
		formatted_log += " - %sms delay" % delay

	log_text.append_text("%s\n" % formatted_log)
	log_text.pop()
	_update_stats()

	## Auto-scroll to bottom
	await get_tree().process_frame
	log_text.scroll_to_line(log_text.get_line_count() - 1)

func set_final_stats(total: int, dropped: int, delayed: int, passed: int) -> void:
	total_packets = total
	dropped_packets = dropped
	delayed_packets = delayed
	passed_packets = passed
	_update_stats()

func _update_stats() -> void:
	var drop_pct: String = "0"
	var delay_pct: String = "0"
	var pass_pct: String = "0"
	if total_packets > 0:
		drop_pct = "%.1f" % (float(dropped_packets) / float(total_packets) * 100.0)
		delay_pct = "%.1f" % (float(delayed_packets) / float(total_packets) * 100.0)
		pass_pct = "%.1f" % (float(passed_packets) / float(total_packets) * 100.0)

	stats_label.text = "Total: %d  |  Dropped: %d (%s%%)  |  Delayed: %d (%s%%)  |  Passed: %d (%s%%)" % [
		total_packets, dropped_packets, drop_pct, delayed_packets, delay_pct, passed_packets, pass_pct
	]

func clear_log() -> void:
	log_text.clear()
	total_packets = 0
	dropped_packets = 0
	delayed_packets = 0
	passed_packets = 0
	_update_stats()
