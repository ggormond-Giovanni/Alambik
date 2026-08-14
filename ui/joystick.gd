extends Control

# Joystick flottant : le pouce se pose n'importe ou sur la moitie basse, le
# joystick nait sous lui. Aucune zone a viser, donc jouable d'une main sans
# regarder ses doigts.

signal intention_changee(direction: Vector2, intensite: float)
# Nombre de tapes rapides enchainees au meme endroit. Le combat decide de ce
# qu'il en fait : l'ecran de reglages choisit le mode, pas le joystick.
signal tape_rapide(nombre: int)

var _logique := JoystickLogique.new()
var _raccourci := RaccourciTactile.new()
var _doigt := -1
var _anim := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	_anim += delta
	if _doigt != -1:
		queue_redraw()

func _zone_valide(position: Vector2) -> bool:
	var taille := get_viewport_rect().size
	return position.y > taille.y * 0.42 and position.x < taille.x * 0.78

func annuler() -> void:
	_doigt = -1
	_logique.relacher()
	_raccourci.annuler()
	intention_changee.emit(Vector2.ZERO, 0.0)
	queue_redraw()

func consommer_raccourci() -> void:
	_raccourci.consommer()

func _temps() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _input(evenement: InputEvent) -> void:
	var tapes := 0
	if evenement is InputEventScreenTouch:
		if evenement.pressed and _doigt == -1:
			if not _zone_valide(evenement.position):
				return
			_doigt = evenement.index
			_logique.appuyer(evenement.position)
			_raccourci.appuyer(evenement.position, _temps())
		elif not evenement.pressed and evenement.index == _doigt:
			_doigt = -1
			_logique.relacher()
			tapes = _raccourci.relacher(_temps())
		else:
			return
	elif evenement is InputEventScreenDrag and evenement.index == _doigt:
		_logique.deplacer(evenement.position)
		_raccourci.deplacer(evenement.position)
	else:
		return
	intention_changee.emit(_logique.direction(), _logique.intensite())
	if tapes > 0:
		tape_rapide.emit(tapes)
	queue_redraw()

func _draw() -> void:
	# Repli geometrique : le joystick se dessine, il n'a pas de sprite.
	if _doigt == -1:
		return
	var origine := _logique.origine
	var pouce := origine + _logique.direction() * _logique.intensite() * JoystickLogique.RAYON
	var hexagone := Dessin.polygone_regulier(origine, JoystickLogique.RAYON + 8.0, 12, PI / 12.0)
	Dessin.contour(self, hexagone, Color(0.01, 0.02, 0.05, 0.72), 10.0)
	Dessin.contour(self, hexagone, Color(Palette.ESSENCE, 0.30), 2.0)
	draw_circle(origine, JoystickLogique.RAYON, Color(1, 1, 1, 0.06))
	draw_circle(origine, JoystickLogique.RAYON * 0.72, Color(0.025, 0.018, 0.050, 0.36))
	draw_arc(origine, JoystickLogique.RAYON, -PI * 0.5, -PI * 0.5 + TAU * maxf(0.04, _logique.intensite()), 48, Color(Palette.OR, 0.72), 5.0, true)
	draw_arc(origine, JoystickLogique.RAYON, 0.0, TAU, 48, Color(1, 1, 1, 0.14), 2.0, true)
	for index in 8:
		var angle := float(index) * TAU / 8.0
		var debut := origine + Vector2.RIGHT.rotated(angle) * (JoystickLogique.RAYON - 13.0)
		var fin := origine + Vector2.RIGHT.rotated(angle) * (JoystickLogique.RAYON - 3.0)
		draw_line(debut, fin, Color(Palette.ESSENCE if index % 2 == 0 else Palette.OR, 0.40), 3.0, true)
	draw_arc(origine, JoystickLogique.RAYON * 0.28, 0.0, TAU, 24, Color(1, 1, 1, 0.12), 2.0, true)
	if _logique.intensite() > 0.0:
		draw_line(origine, pouce, Color(Palette.OR, 0.35), 4.0, true)
	Dessin.halo(self, pouce, JoystickLogique.RAYON * 0.7, Color(Palette.ESSENCE, 0.42), 3)
	draw_circle(pouce, JoystickLogique.RAYON * 0.32, Color(0.02, 0.08, 0.12, 0.88))
	draw_arc(pouce, JoystickLogique.RAYON * 0.32, 0.0, TAU, 24, Color(Palette.OR, 0.82), 3.0, true)
	draw_circle(pouce, JoystickLogique.RAYON * 0.16, Color(Palette.ESSENCE, 0.72))
