extends BaseRewardButton

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	reward_kind = "artifact"
	super(_action_on_click, _reward_group)
	
	var artifact_id: String = _action_on_click.values.get("artifact_id", "")
	var artifact_data: ArtifactData = Global.get_artifact_data(artifact_id)
	if artifact_data != null:
		reward_rarity = artifact_data.artifact_rarity
		text = artifact_data.artifact_name
		icon = CardArtRegistry.resolve_artifact_texture(artifact_data)
	_apply_visual_style()
