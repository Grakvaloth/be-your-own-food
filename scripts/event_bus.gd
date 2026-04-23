extends Node

# Globaler Event-Bus. Als Autoload "EventBus" registriert.
# Konsumenten (Sound, UI, Savegame) subscriben hier, ohne main.gd zu kennen.

signal score_changed(new_score: int)
signal guest_served(guest: Node, points: int)
signal guest_left_early(guest: Node)
signal guest_died(guest: Node)
signal upgrade_purchased(kind: String, index: int)
signal item_picked_up(item: String)
