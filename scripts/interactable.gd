class_name Interactable
extends StaticBody2D

# Virtuelle Standardimplementierungen — Subklassen überschreiben nach Bedarf.
# Spieler nutzt duck-typing (has_method), daher reicht die Existenz der
# Signaturen aus, damit Player.gd konsistent fragen kann.

func can_interact(_player: CharacterBody2D) -> bool:
	return false

func on_player_interact(_player: CharacterBody2D) -> void:
	pass

func can_interact_alt(_player: CharacterBody2D) -> bool:
	return false

func on_player_interact_alt(_player: CharacterBody2D) -> void:
	pass

func can_open(_player: CharacterBody2D) -> bool:
	return false

func on_player_open(_player: CharacterBody2D) -> void:
	pass
