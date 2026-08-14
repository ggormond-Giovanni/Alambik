extends Control

signal terminee

const DUREE := 1.45

var _livre := {}
var _temps := 0.0
var _terminee := false

func configurer(livre: Dictionary) -> void:
	_livre = livre

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()
	Capture.programmer(self)

func _process(delta: float) -> void:
	_temps += delta
	queue_redraw()
	if not _terminee and _temps >= DUREE:
		_terminee = true
		terminee.emit()

func _draw() -> void:
	var taille := size
	var progression := clampf(_temps / DUREE, 0.0, 1.0)
	StyleInterface.dessiner_fond(self, taille, Palette.ESSENCE, _temps)
	for i in 9:
		var part := float(i) / 8.0
		var entree_bande := clampf(progression * 1.7 - part * 0.25, 0.0, 1.0)
		var largeur := taille.x * ease(entree_bande, 0.45)
		var depuis_droite := i % 2 == 1
		var x := taille.x - largeur if depuis_droite else 0.0
		var couleur := Color(Palette.OR.lerp(Palette.ESSENCE, part), 0.035 + part * 0.025)
		draw_rect(Rect2(x, taille.y * part, largeur, taille.y / 8.0 + 2.0), couleur)
	var centre := Vector2(taille.x * 0.5, taille.y * 0.53)
	var ouverture := sin(PI * clampf(progression * 1.25, 0.0, 1.0))
	Dessin.halo(self, centre, 330.0 * (0.65 + ouverture * 0.35), Color(Palette.ESSENCE, 0.72), 8)
	Dessin.halo(self, centre, 220.0, Color(Palette.OR, 0.46), 6)
	for i in 3:
		draw_arc(centre, 150.0 + float(i) * 44.0, -PI * 0.82 + _temps * (0.7 + i * 0.15),
			PI * 0.82 + _temps * (0.7 + i * 0.15), 48, Color(Palette.OR.lerp(Palette.ESSENCE, float(i) / 2.0), 0.72), 4.0, true)
	for i in 12:
		var angle := float(i) * TAU / 12.0 + _temps * 0.24
		var distance := 190.0 + sin(_temps * 2.0 + i) * 32.0
		var p := centre + Vector2.RIGHT.rotated(angle) * distance
		draw_circle(p, 2.0 + float(i % 3), Color(Palette.ESSENCE, 0.28 + ouverture * 0.28))
	var position_heros := centre + Vector2(0.0, lerpf(120.0, 18.0, ease(progression, 0.35)))
	_dessiner_heros(position_heros, 0.82 + progression * 0.18)
	var police := Polices.CORPS
	var nom := str(_livre.get("nom", "GRIMOIRE"))
	draw_string(police, Vector2(0.0, taille.y * 0.18), "OUVERTURE DU GRIMOIRE",
		HORIZONTAL_ALIGNMENT_CENTER, taille.x, 42, Palette.TEXTE)
	draw_string(police, Vector2(0.0, taille.y * 0.18 + 62.0), nom.to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER, taille.x, 31, Palette.OR)
	draw_string(police, Vector2(0.0, taille.y * 0.82), "L’alchimiste entre dans la salle…",
		HORIZONTAL_ALIGNMENT_CENTER, taille.x, 25, Palette.TEXTE_ATTENUE)
	var rail := Rect2(taille.x * 0.22, taille.y * 0.88, taille.x * 0.56, 5.0)
	draw_rect(rail, Color(Palette.TEXTE_ATTENUE, 0.16))
	draw_rect(Rect2(rail.position, Vector2(rail.size.x * progression, rail.size.y)), Palette.ESSENCE)

func _dessiner_heros(position: Vector2, echelle: float) -> void:
	draw_set_transform(position, 0.0, Vector2.ONE * (2.05 * echelle))
	Retro16.dessiner_heros(self, _temps, false, Vector2.UP, Palette.OR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
