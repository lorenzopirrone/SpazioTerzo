@tool
extends EditorScript

func _run() -> void:
	var size: int = 32
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y: int in range(size):
		for x: int in range(size):
			var t: float = float(x + y) / float(size * 2)
			var line_y: float = 21.0 - float(x) * 0.55
			var distance: float = absf(float(y) - line_y)
			var alpha: float = clampf(1.0 - distance / 4.0, 0.0, 1.0)

			if alpha > 0.0:
				var color: Color = Color(1.0, 0.35 + 0.55 * t, 0.05, alpha * 0.8)
				if distance < 1.0:
					color = Color(1.0, 0.95, 0.55, alpha)
				img.set_pixel(x, y, color)

	var error: Error = img.save_png("res://spark_arcade.png")
	if error == OK:
		print("Texture creata correttamente!")
	else:
		push_error("Errore nel salvataggio della texture.")
