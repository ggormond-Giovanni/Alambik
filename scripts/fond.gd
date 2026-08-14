extends Node2D

# Le terrain peint correspond aux limites physiques existantes : la zone claire
# reste jouable et les decors detailles demeurent hors collision.

const PEINTURE_ARENE_CLASSIQUE := preload("res://assets/visual/arene_atelier_verdoyant_v2.png")
const PEINTURE_ARENE_HAUTE := preload("res://assets/visual/arene_atelier_verdoyant_v3_haute.png")

var limites := Rect2()
var numero := 1
var _anim := 0.0

func preparer(limites_: Rect2, numero_: int) -> void:
	limites = limites_
	numero = numero_
	queue_redraw()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	var taille := get_viewport_rect().size
	# La Mine recule la camera pour montrer davantage de terrain. Le fond doit
	# donc couvrir la meme surface de monde que les limites physiques ; sinon la
	# camera revele le clear color et donne l'impression que les entites sortent
	# de l'arene.
	if Jeu.mode_run == "mine":
		taille /= Reglages.MINE_CAMERA_ZOOM
	var peinture := PEINTURE_ARENE_HAUTE if taille.y / maxf(1.0, taille.x) >= 2.02 \
		else PEINTURE_ARENE_CLASSIQUE
	var haut_fixe := 520.0 if peinture == PEINTURE_ARENE_HAUTE else 620.0
	var bas_fixe := 520.0 if peinture == PEINTURE_ARENE_HAUTE else 560.0
	FondAdaptatif.dessiner(self, peinture, taille, haut_fixe, bas_fixe)
	# Quelques lumieres vivantes suffisent a animer une peinture fixe sans bruit.
	for index in 6:
		var angle := _anim * (0.10 + index * 0.012) + float(index)
		var centre := limites.get_center() + Vector2(cos(angle), sin(angle * 1.3)) \
			* Vector2(limites.size.x * 0.43, limites.size.y * 0.43)
		draw_circle(Retro16.pixel(centre), 2.0 + float(index % 2) * 2.0,
			Color(Palette.ESSENCE, 0.22 + 0.12 * sin(_anim * 2.0 + index)))
