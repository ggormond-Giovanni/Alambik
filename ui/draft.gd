extends Control

# Ecran de choix premium. La peinture fournit le chassis ; les trois contenus,
# les zones tactiles et le nombre de tirages restent entierement dynamiques.

signal termine

const FOND := preload("res://assets/visual/choix_amelioration_premium.png")
const HAUT_FIXE := 1500.0
const BAS_FIXE := 420.0
const CARTES := [
	Rect2(18.0, 446.0, 326.0, 850.0),
	Rect2(356.0, 397.0, 366.0, 906.0),
	Rect2(730.0, 443.0, 334.0, 854.0),
]
const CENTRES_ICONES := [Vector2(181.0, 660.0), Vector2(539.0, 626.0), Vector2(897.0, 660.0)]
const COULEURS := [Color("aa55ff"), Color("78dd45"), Color("ffac28")]
const ICONES := {
	"tir_multiple": 9, "salve": 9, "ricochet": 11, "perforation": 4,
	"fragmentation": 8, "homing": 7, "egide": 10, "regeneration": 8,
	"avidite": 13, "courageux": 6, "mannequin": 2, "familier_tireur": 3,
	"meteores": 9, "zone_heros": 8, "familier_gardien": 6, "orbes_chargees": 11,
	"frappe_lourde": 2, "cadence_febrile": 9, "trait_transpercant": 4,
	"peau_de_pierre": 10, "soif_de_sang": 8, "chaine_alchimique": 11,
	"spirale": 9, "elan_vital": 7, "onde_de_choc": 10,
	"sceau_furie": 6, "sceau_celerite": 13, "sceau_garde": 10,
	"sceau_portee": 4, "sceau_ruine": 11,
}

var _choisi := false
var _propositions: Array[String] = []
var _boutons: Array[Button] = []
var _bouton_reroll: Button
var _anim := 0.0
var etage_recompense := 1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_zones()
	_nouveau_tirage()
	StyleInterface.animer_entree(self, 18.0)
	Capture.programmer(self)
	if Jeu.mode_auto:
		_choisir_automatiquement()

func _construire_zones() -> void:
	for index in 3:
		var bouton := StyleInterface.zone_tactile()
		bouton.mouse_entered.connect(func() -> void:
			if not ReglagesJoueur.effets_reduits:
				var t := bouton.create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
				t.tween_property(bouton, "scale", Vector2(1.018, 1.018), 0.12))
		bouton.mouse_exited.connect(func() -> void:
			var t := bouton.create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			t.tween_property(bouton, "scale", Vector2.ONE, 0.15))
		bouton.pressed.connect(func() -> void:
			if index < _propositions.size(): _sur_choix(_propositions[index]))
		add_child(bouton)
		_boutons.append(bouton)
	_bouton_reroll = StyleInterface.zone_tactile(_sur_reroll)
	add_child(_bouton_reroll)
	resized.connect(_replacer_zones)
	_replacer_zones()

func _replacer_zones() -> void:
	var sx := size.x / 1080.0
	for index in mini(3, _boutons.size()):
		var r: Rect2 = CARTES[index]
		var adapte := FondAdaptatif.rect(size, FOND, r, HAUT_FIXE, BAS_FIXE)
		_boutons[index].position = adapte.position
		_boutons[index].size = adapte.size
		_boutons[index].pivot_offset = _boutons[index].size * 0.5
	var reroll := FondAdaptatif.rect(size, FOND, Rect2(276.0, 1600.0, 528.0, 174.0),
		HAUT_FIXE, BAS_FIXE)
	_bouton_reroll.position = reroll.position
	_bouton_reroll.size = reroll.size

func _nouveau_tirage() -> void:
	_propositions = DraftLogique.proposer(Jeu.inventaire, Jeu.rng)
	# Un pool epuise ouvrait un ecran sans aucune carte, donc sans rien a
	# toucher : la descente restait bloquee sur un panneau impossible a fermer.
	if _propositions.is_empty():
		_fermer_sans_choix()
		return
	_rafraichir_reroll()
	queue_redraw()
	if not ReglagesJoueur.effets_reduits:
		for index in mini(_boutons.size(), _propositions.size()):
			var bouton := _boutons[index]
			bouton.scale = Vector2(0.90, 0.90)
			var t := bouton.create_tween().set_parallel(true)
			t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_interval(float(index) * 0.07)
			t.tween_property(bouton, "scale", Vector2.ONE, 0.34)

func _sur_reroll() -> void:
	if _choisi or Jeu.rerolls_restants <= 0:
		return
	_bouton_reroll.disabled = true
	Sons.jouer("choix", -13.0)
	Jeu.rerolls_restants -= 1
	_nouveau_tirage()
	_bouton_reroll.disabled = false

func _rafraichir_reroll() -> void:
	if _bouton_reroll == null:
		return
	_bouton_reroll.disabled = Jeu.rerolls_restants <= 0

func _sur_choix(id: String) -> void:
	if _choisi:
		return
	_choisi = true
	Jeu.ajouter_reactif(id)
	Sons.jouer("choix", -10.0)
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _fermer_sans_choix() -> void:
	if _choisi:
		return
	_choisi = true
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _choisir_automatiquement() -> void:
	await get_tree().create_timer(0.12).timeout
	if not _choisi and not _propositions.is_empty():
		_sur_choix(_propositions[0])

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	FondAdaptatif.dessiner_premium(self, FOND, size, HAUT_FIXE, BAS_FIXE)
	var police := Polices.CORPS
	var sx := size.x / 1080.0
	var sy := sx
	for index in mini(3, _propositions.size()):
		var reactif := CatalogueReactifs.par_id(_propositions[index])
		if reactif == null:
			continue
		var r: Rect2 = CARTES[index]
		var centre := Vector2(CENTRES_ICONES[index].x * sx, CENTRES_ICONES[index].y * sy)
		var couleur: Color = COULEURS[index]
		Dessin.halo(self, centre, 118.0 * sx, Color(couleur, 0.22 + 0.04 * sin(_anim * 2.0 + index)), 6)
		var icone := Rect2(centre - Vector2(88.0, 88.0) * sx, Vector2(176.0, 176.0) * sx)
		Retro16.dessiner_icone_interface(self, int(ICONES.get(reactif.id, 8)), icone,
			Color.WHITE.lerp(couleur, 0.10))
		var gauche := r.position.x * sx + 24.0 * sx
		var largeur := (r.size.x - 48.0) * sx
		_draw_centre(police, Vector2(gauche, 900.0 * sy), largeur, reactif.nom.to_upper(), 25, Palette.TEXTE)
		_draw_centre(police, Vector2(gauche, 973.0 * sy), largeur, _nom_famille(reactif.famille), 22, couleur)
		draw_multiline_string(police, Vector2(gauche + 8.0 * sx, 1060.0 * sy), reactif.description,
			HORIZONTAL_ALIGNMENT_CENTER, largeur - 16.0 * sx, 25, 4, Palette.TEXTE_ATTENUE)
		for etoile in 3:
			var p := Vector2((r.position.x + r.size.x * 0.5 + (etoile - 1) * 52.0) * sx, 1255.0 * sy)
			Dessin.glyphe(self, "cristal", p, 13.0 * sx, couleur)
	var couleur_reroll := Retro16.VIOLET if Jeu.rerolls_restants > 0 else Palette.TEXTE_ATTENUE
	var compteur := FondAdaptatif.point(size, FOND, Vector2(730.0, 1710.0),
		HAUT_FIXE, BAS_FIXE)
	draw_circle(compteur, 9.0 * sx, couleur_reroll)
	draw_string(police, compteur + Vector2(20.0 * sx, 10.0 * sx), str(Jeu.rerolls_restants),
		HORIZONTAL_ALIGNMENT_LEFT, 70.0 * sx, 27, couleur_reroll)
	var pied_y := FondAdaptatif.y(size, FOND, 1818.0, HAUT_FIXE, BAS_FIXE)
	draw_string(police, Vector2(0.0, pied_y), "NIVEAU %d  •  choisissez une carte" % etage_recompense,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 23, Palette.TEXTE_ATTENUE)

func _draw_centre(police: Font, position: Vector2, largeur: float, texte: String,
		taille_police: int, couleur: Color) -> void:
	draw_string(police, position, texte, HORIZONTAL_ALIGNMENT_CENTER, largeur, taille_police, couleur)

func _nom_famille(famille: String) -> String:
	match famille:
		CatalogueReactifs.PROJECTILE: return "PROJECTILE"
		CatalogueReactifs.HEROS: return "SURVIE"
	return "PHÉNOMÈNE"
