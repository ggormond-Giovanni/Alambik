extends Node

# 112 unités sur notre viewport de 1080 correspondent à une cible confortable
# sur un téléphone courant. Aucun bouton essentiel ne doit passer dessous.
const CIBLE_TACTILE := 112.0

# L'encoche et la barre de navigation mangent le haut et le bas de l'ecran.
# Tout ce qui est tactile doit rester dans la zone sure, sinon le pouce tape
# le systeme au lieu du jeu. Les marges sont exprimees dans le viewport de
# reference (1080 de large), pas en pixels physiques.

func _facteur() -> float:
	var ecran := DisplayServer.screen_get_size()
	if ecran.x <= 0:
		return 1.0
	return float(ProjectSettings.get_setting("display/window/size/viewport_width")) / float(ecran.x)

func marge_haute() -> float:
	if OS.get_name() != "Android":
		return 24.0
	var sure := DisplayServer.get_display_safe_area()
	return maxf(24.0, float(sure.position.y) * _facteur())

func marge_basse() -> float:
	if OS.get_name() != "Android":
		return 24.0
	var sure := DisplayServer.get_display_safe_area()
	var ecran := DisplayServer.screen_get_size()
	return maxf(24.0, float(ecran.y - sure.end.y) * _facteur())

# Hauteur reellement visible dans le viewport de reference : l'etirement est
# keep_width, donc la largeur est garantie et la hauteur varie avec l'appareil.
func hauteur_visible() -> float:
	var taille := get_viewport().get_visible_rect().size
	return taille.y

func largeur_visible() -> float:
	return get_viewport().get_visible_rect().size.x
