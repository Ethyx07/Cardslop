extends SubViewport

@onready var value_label : Label = $CardVisual/Label


func generate(item_data : ItemData, override_data : Dictionary) -> Texture2D:
	var value = override_data.get("item_value", item_data.item_value)
	value_label.text = "$" + str(value)

	await RenderingServer.frame_post_draw

	var image := get_texture().get_image()
	return ImageTexture.create_from_image(image)
