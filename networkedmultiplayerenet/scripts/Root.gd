extends Control

const PORT = 8076

var _mouse_start: Vector2
var _last_color: int = -1
var _color: int

func _ready():
	$Menu.show()
	$Connecting.hide()
	$Game.hide()


func _on_Host_clicked():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT)
	get_tree().set_network_peer(peer)
	get_tree().connect("network_peer_connected", self, "_player_connected")
	
	_last_color = (_last_color + 1) % 8
	_set_color(_last_color)

	
	
	$Menu.hide()
	$Game.show()


func _on_Join_clicked():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client("127.0.0.1", PORT)
	get_tree().set_network_peer(peer)
	
	$Menu.hide()
	$Connecting.show()
	yield(get_tree(), "connected_to_server")
	$Connecting.hide()
	$Game.show()

func _player_connected(id):
	_last_color = (_last_color + 1) % 8
	rpc_id(id, "_set_color", _last_color)
	for color in range(8):
		rpc_id(id, "_init_canvas_color", $Game/Center/Canvas.get_used_cells_by_id(color), color)


remotesync func _init_canvas_color(positions, color):
	for position in positions:
		$Game/Center/Canvas.set_cellv(position, color)


remotesync func _set_color(color):
	_color = color


# http://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm#C
remotesync func _rasterize_line(x0: int, y0: int, x1: int, y1: int, color: int) -> void:
	var dx: int = abs(x1 - x0)
	var dy: int = abs(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = (dx if dx > dy else -dy) / 2
	var e2: int
	while true:
		$Game/Center/Canvas.set_cell(x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		e2 = err
		if e2 > -dx:
			err -= dy
			x0 += sx
		if e2 < dy:
			err += dx
			y0 += sy


func _on_Game_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_MASK_LEFT:
			_mouse_start = event.position
	
	elif event is InputEventMouseMotion:
		if event.button_mask & BUTTON_MASK_LEFT:
			var scale = $Game/Center/Canvas.scale
			var v0 = (_mouse_start - $Game/Center.rect_position) / scale
			var v1 = (event.position - $Game/Center.rect_position) / scale
			var x0: int = int(v0.x)
			var y0: int = int(v0.y)
			var x1: int = int(v1.x)
			var y1: int = int(v1.y)
			rpc("_rasterize_line", x0, y0, x1, y1, _color)
			_mouse_start = event.position
			