extends Node
func _ready() -> void:
	get_window().size = Vector2i(1244, 700)
	for i in 60: await get_tree().process_frame
	var root := get_tree().root
	var rest := root.find_child("RestOverlay", true, false)
	if rest == null: print("[CHK] no RestOverlay"); get_tree().quit(); return
	Global.run_fu_deck = ["fu_po_sha", "fu_po_sha", "fu_chi"]
	rest.call("populate_rest_actions")
	await get_tree().process_frame
	var cont := rest.find_child("RestActionContainer", true, false)
	var names := []
	var enabled := "n/a"
	if cont:
		for c in cont.get_children():
			names.append(c.name)
			if c.name == "FuMergeButton": enabled = str(not c.disabled)
	print("[CHK] FuMergeButton present=", names.has("FuMergeButton"), " enabled(mergeable deck)=", enabled, " total=", names.size())
	get_tree().quit()
