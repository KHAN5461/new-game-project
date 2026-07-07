extends Node

func _ready() -> void:
    get_tree().node_added.connect(_on_node_added)
    _hook_existing_nodes(get_tree().root)

func _hook_existing_nodes(node: Node) -> void:
    if node is Button:
        _hook_button(node)
    for child in node.get_children():
        _hook_existing_nodes(child)

func _on_node_added(node: Node) -> void:
    if node is Button:
        _hook_button(node)

func _hook_button(btn: Button) -> void:
    btn.pivot_offset = btn.size / 2.0
    btn.item_rect_changed.connect(func(): btn.pivot_offset = btn.size / 2.0)
    
    pass
