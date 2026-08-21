extends SceneTree

# Assertions de coherence sur les donnees. Elles repondent a une question que
# les tests unitaires ne posent pas : une transformation dont le drapeau n'est lu par
# aucun script est inerte, donc le joueur ne verra aucune difference.

func _initialize() -> void:
	var code := 0
	code = maxi(code, _tout_compile())
	code = maxi(code, _drapeaux_lus())
	code = maxi(code, _effets_lus())
	code = maxi(code, _catalogues_coherents())
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
		if d.begins_with("transformation_heros_") or d.begins_with("sceau_element_"):
			continue
		if not _cite_dans_les_scripts(d):
			print("ECHEC  le drapeau %s n'est lu par aucun script : la transformation est inerte" % d)
			code = 1
	return code

func _effets_lus() -> int:
	var code := 0
	for e in _valeurs_de_liste("effets"):
		if not _cite_dans_les_scripts(e):
			print("ECHEC  l'effet %s n'est lu par aucun script" % e)
			code = 1
	return code

func _catalogues_coherents() -> int:
	var code := 0
	if CatalogueReactifs.ids().size() != 30:
		print("ECHEC  le catalogue doit contenir exactement trente Améliorations")
		code = 1
	if CatalogueElements.ids().size() != 6:
		print("ECHEC  le catalogue doit contenir exactement six Elements decides")
		code = 1
	for id in CatalogueReactifs.ids():
		if CatalogueReactifs.par_id(id).mods.is_empty():
			print("ECHEC  l'Amélioration %s ne porte aucun effet" % id)
			code = 1
		for element in CatalogueElements.ids():
			if CatalogueElements.creer_fusion(element, id) == null:
				print("ECHEC  %s ne peut pas recevoir %s" % [id, element])
				code = 1
	return code

func _valeurs_de_liste(champ: String) -> Array[String]:
	var trouvees: Array[String] = []
	for source in [CatalogueReactifs.TOUS]:
		for id in source:
			for valeur in source[id].mods.get(champ, []):
				if not valeur in trouvees:
					trouvees.append(valeur)
	for element in CatalogueElements.ids():
		for augment in CatalogueReactifs.ids():
			for valeur in CatalogueElements.creer_fusion(element, augment).mods.get(champ, []):
				if not valeur in trouvees:
					trouvees.append(valeur)
	return trouvees

# Les scripts sont maintenant ranges dans des sous-dossiers. Reutiliser le
# parcours recursif evite qu'un drapeau paraisse inerte uniquement parce que son
# lecteur n'est plus directement a la racine de scripts/.
func _cite_dans_les_scripts(nom: String) -> bool:
	for dossier in ["res://scripts/", "res://ui/", "res://autoload/"]:
		for chemin in _fichiers(dossier, [".gd"]):
			var texte := FileAccess.get_file_as_string(chemin)
			if texte.contains('"%s"' % nom):
				return true
	return false
