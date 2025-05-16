# Quest item

extends Area2D

# NPC node reference
@onready var npc = get_tree().root.get_node("%s/SpawnedNPC/NPC" % Global.current_scene_name)

# If the player enters the collision body, destroy item and update quest
func _on_body_entered(body):
	if body.name == "Player":
		print("Quest item obtained!")
		get_tree().queue_delete(self)
		npc.quest_complete = true
