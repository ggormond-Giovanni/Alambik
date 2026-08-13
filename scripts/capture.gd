class_name Capture
extends RefCounted

# Outillage : --capture=<fichier> --capture-apres=<secondes> prend une image de
# l'ecran et quitte. Sert a regarder le rendu sans lancer une session a la main,
# et a comparer avant/apres quand on touche au dessin.

static var _programmee := false

static func demandee() -> bool:
	return not _argument("--capture=").is_empty()

static func programmer(noeud: Node) -> void:
	if not demandee() or _programmee:
		return
	_programmee = true
	var fichier := _argument("--capture=")
	var delai := float(_argument("--capture-apres=") if not _argument("--capture-apres=").is_empty() else "2.0")
	await noeud.get_tree().create_timer(delai).timeout
	await RenderingServer.frame_post_draw
	var image := noeud.get_viewport().get_texture().get_image()
	image.save_png(fichier)
	print("capture ecrite : " + fichier)
	noeud.get_tree().quit()

static func _argument(prefixe: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefixe):
			return argument.substr(prefixe.length())
	return ""
