extends SubViewport

@onready var value_label : Label = $CardVisual/Label


func generate(item_data : ItemData) -> Texture2D:
	value_label.text = "$" + str(item_data.item_value)

	await RenderingServer.frame_post_draw

	var image := get_texture().get_image()
	return ImageTexture.create_from_image(image)
