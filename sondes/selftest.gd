extends SceneTree

# Assertions de coherence sur les donnees. Elles repondent a une question que
# les tests unitaires ne posent pas : une essence dont le drapeau n'est lu par
# aucun script est inerte, donc le joueur ne verra aucune difference.

func _initialize() -> void:
	var code := 0
	code = maxi(code, _tout_compile())
	code = maxi(code, _drapeaux_lus())
	code = maxi(code, _effets_lus())
	code = maxi(code, _recettes_coherentes())
	if code == 0:
		print("selftest : tout compile, donnees coherentes, aucun drapeau inerte.")
	quit(code)

# Une erreur de compilation dans un script qu'aucune suite ne sollicite laisse
# le harnais vert : c'est arrive avec une carte d'interface. On charge donc
# tout, scripts comme scenes, et on lit les erreurs.
func _tout_compile() -> int:
	var code := 0
	for chemin in _fichiers("res://", [".gd", ".tscn"]):
		if chemin.begins_with("res://sondes/") or chemin == "res://tests/lanceur.gd":
			continue
		var ressource := load(chemin)
		if ressource == null:
			print("ECHEC  %s ne se charge pas" % chemin)
			code = 1
		elif ressource is Script and not (ressource as Script).can_instantiate():
			# Un script mal parse revient parfois non nul mais inutilisable :
			# le test du null seul laisserait passer l'erreur.
			print("ECHEC  %s ne compile pas" % chemin)
			code = 1
	return code

func _fichiers(racine: String, extensions: Array) -> Array[String]:
	var trouves: Array[String] = []
	var dossier := DirAccess.open(racine)
	if dossier == null:
		return trouves
	for fichier in dossier.get_files():
		for extension in extensions:
			if fichier.ends_with(extension):
				trouves.append(racine.path_join(fichier))
	for sous in dossier.get_directories():
		if sous.begins_with("."):
			continue
		trouves.append_array(_fichiers(racine.path_join(sous), extensions))
	return trouves

func _drapeaux_lus() -> int:
	var code := 0
	for d in _valeurs_de_liste("drapeaux"):
		if not _cite_dans_les_scripts(d):
			print("ECHEC  le drapeau %s n'est lu par aucun script : l'essence est inerte" % d)
			code = 1
	return code

func _effets_lus() -> int:
	var code := 0
	for e in _valeurs_de_liste("effets"):
		if not _cite_dans_les_scripts(e):
			print("ECHEC  l'effet %s n'est lu par aucun script" % e)
			code = 1
	return code

func _recettes_coherentes() -> int:
	var code := 0
	var vues: Array[String] = []
	for cle in Recettes.TABLE:
		var morceaux: PackedStringArray = (cle as String).split("+")
		if morceaux.size() != 2:
			print("ECHEC  la cle %s n'est pas une paire" % cle)
			code = 1
			continue
		var normale := Recettes.cle(morceaux[0], morceaux[1])
		if normale != cle:
			print("ECHEC  la cle %s n'est pas normalisee (attendu %s)" % [cle, normale])
			code = 1
		if normale in vues:
			print("ECHEC  la paire %s apparait deux fois dans la table" % normale)
			code = 1
		vues.append(normale)
		for id in morceaux:
			if not CatalogueReactifs.TOUS.has(id):
				print("ECHEC  le composant %s de %s n'existe pas" % [id, cle])
				code = 1
		if not CatalogueEssences.TOUS.has(Recettes.TABLE[cle]):
			print("ECHEC  l'essence %s de %s n'existe pas" % [Recettes.TABLE[cle], cle])
			code = 1
	for id in CatalogueReactifs.ids():
		if CatalogueReactifs.par_id(id).mods.is_empty():
			print("ECHEC  le reactif %s ne porte aucun effet" % id)
			code = 1
	return code

func _valeurs_de_liste(champ: String) -> Array[String]:
	var trouvees: Array[String] = []
	for source in [CatalogueReactifs.TOUS, CatalogueEssences.TOUS]:
		for id in source:
			for valeur in source[id].mods.get(champ, []):
				if not valeur in trouvees:
					trouvees.append(valeur)
	return trouvees

func _cite_dans_les_scripts(nom: String) -> bool:
	for dossier in ["res://scripts/", "res://ui/", "res://autoload/"]:
		for fichier in DirAccess.get_files_at(dossier):
			if not fichier.ends_with(".gd"):
				continue
			var texte := FileAccess.get_file_as_string(dossier + fichier)
			if texte.contains('"%s"' % nom):
				return true
	return false
