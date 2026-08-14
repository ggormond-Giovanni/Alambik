extends RefCounted

const LARGEUR := 1080.0

func _seuil() -> float:
	return maxf(BalayagePages.DISTANCE_MINIMALE, LARGEUR * BalayagePages.PART_LARGEUR)

func test_un_balayage_vers_la_gauche_avance_d_une_page(v: Verif) -> void:
	var b := BalayagePages.new()
	b.appuyer(Vector2(700, 1300))
	v.egal(b.deplacer(Vector2(700 - _seuil() - 10.0, 1300), LARGEUR), 1,
		"tirer vers la gauche montre la page suivante")

func test_un_balayage_vers_la_droite_revient_en_arriere(v: Verif) -> void:
	var b := BalayagePages.new()
	b.appuyer(Vector2(300, 1300))
	v.egal(b.deplacer(Vector2(300 + _seuil() + 10.0, 1300), LARGEUR), -1,
		"tirer vers la droite revient a la page precedente")

func test_un_geste_trop_court_ne_tourne_pas(v: Verif) -> void:
	var b := BalayagePages.new()
	b.appuyer(Vector2(500, 1300))
	v.egal(b.deplacer(Vector2(500 - _seuil() * 0.5, 1300), LARGEUR), 0,
		"un simple tremblement du doigt ne change pas de page")
	v.vrai(not b.a_balaye(), "le bouton relache reste valide apres un geste avorte")

func test_un_geste_vertical_ne_tourne_pas(v: Verif) -> void:
	var b := BalayagePages.new()
	b.appuyer(Vector2(500, 1300))
	v.egal(b.deplacer(Vector2(500 + _seuil() + 10.0, 1300 + _seuil() * 3.0), LARGEUR), 0,
		"un geste plus vertical qu'horizontal vise autre chose")

# Un doigt qui continue sa course apres le seuil ne doit pas defiler tout
# l'inventaire d'un coup.
func test_un_seul_appui_ne_tourne_qu_une_page(v: Verif) -> void:
	var b := BalayagePages.new()
	b.appuyer(Vector2(900, 1300))
	v.egal(b.deplacer(Vector2(900 - _seuil() - 10.0, 1300), LARGEUR), 1, "la page tourne une fois")
	v.egal(b.deplacer(Vector2(100, 1300), LARGEUR), 0, "la suite du geste ne tourne plus rien")
	v.egal(b.deplacer(Vector2(20, 1300), LARGEUR), 0, "meme en allant jusqu'au bord")

func test_le_balayage_neutralise_le_bouton_relache(v: Verif) -> void:
	var b := BalayagePages.new()
	b.appuyer(Vector2(900, 1300))
	b.deplacer(Vector2(900 - _seuil() - 10.0, 1300), LARGEUR)
	b.relacher()
	v.vrai(b.a_balaye(), "le doigt relache sur une case ne doit pas la selectionner")
	b.appuyer(Vector2(500, 1300))
	v.vrai(not b.a_balaye(), "l'appui suivant redevient un vrai appui")
