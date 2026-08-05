extends SceneTree

const DOSSIER := "res://tests/"

var _termine := false

func _initialize() -> void:
	var verif := Verif.new()
	var suites := 0
	for fichier in _fichiers_de_test():
		var script: GDScript = load(DOSSIER + fichier)
		if script == null:
			verif.total += 1
			verif.echecs.append("la suite %s ne se charge pas (erreur de parse)" % fichier)
			continue
		var suite: RefCounted = script.new()
		suites += 1
		for methode in suite.get_method_list():
			if methode.name.begins_with("test_"):
				suite.call(methode.name, verif)
	print("Suites : %d   Assertions : %d   Echecs : %d" % [suites, verif.total, verif.echecs.size()])
	for echec in verif.echecs:
		print("  ECHEC  " + echec)
	_termine = true
	quit(1 if not verif.echecs.is_empty() else 0)

# Ceinture de securite : une erreur d'execution interrompt _initialize sans
# atteindre quit(), et le harnais tournerait alors indefiniment en silence.
func _process(_delta: float) -> bool:
	if not _termine:
		print("ECHEC  le harnais s'est interrompu avant la fin (voir les SCRIPT ERROR ci-dessus)")
		quit(1)
	return true

func _fichiers_de_test() -> Array[String]:
	var trouves: Array[String] = []
	var dossier := DirAccess.open(DOSSIER)
	if dossier == null:
		push_error("Dossier de tests introuvable : " + DOSSIER)
		return trouves
	for fichier in dossier.get_files():
		if fichier.begins_with("test_") and fichier.ends_with(".gd"):
			trouves.append(fichier)
	trouves.sort()
	return trouves
