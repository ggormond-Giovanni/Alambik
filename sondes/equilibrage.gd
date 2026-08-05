extends SceneTree

# Etat de l'equilibrage, chiffre. Deux questions : une fusion vaut-elle mieux
# que ses deux composants gardes separement, et quelles combinaisons explosent.

func _initialize() -> void:
	var base := Puissance.score_de_base()
	print("--- fusions : essence contre ses deux composants ---")
	var perdantes := 0
	for cle in Recettes.TABLE:
		var morceaux: PackedStringArray = (cle as String).split("+")
		var essence: String = Recettes.TABLE[cle]
		var a := CatalogueReactifs.par_id(morceaux[0])
		var b := CatalogueReactifs.par_id(morceaux[1])
		var e := CatalogueEssences.par_id(essence)
		var couple := Puissance.score_des_mods([a.mods, b.mods]) / base
		var seule := Puissance.score_des_mods([e.mods]) / base
		var verdict := "OK  " if seule > couple else "PERD"
		if seule <= couple:
			perdantes += 1
		print("%s  %-22s %5.2f  contre  %s + %s = %5.2f  (rapport %4.2f)" % [
			verdict, e.nom, seule, a.nom, b.nom, couple, seule / couple])
	print("Fusions plus faibles que leurs composants : %d / %d" % [perdantes, Recettes.TABLE.size()])

	print("")
	print("--- combinaisons de reactifs les plus fortes (sur 5 pris, offense x survie) ---")
	var ids := CatalogueReactifs.ids()
	var resultats: Array = []
	var alea := RandomNumberGenerator.new()
	alea.seed = 12345
	for essai in 4000:
		var pioche := ids.duplicate()
		var choisis: Array[String] = []
		for i in 5:
			choisis.append(pioche.pop_at(alea.randi_range(0, pioche.size() - 1)))
		resultats.append([Puissance.score_total_de_l_inventaire(choisis) / base, choisis])
	resultats.sort_custom(func(x, y): return x[0] > y[0])
	for i in 6:
		print("  x%6.2f  %s" % [resultats[i][0], str(resultats[i][1])])
	print("  ...")
	for i in range(resultats.size() - 3, resultats.size()):
		print("  x%6.2f  %s" % [resultats[i][0], str(resultats[i][1])])
	var median: float = resultats[resultats.size() / 2][0]
	print("Mediane sur 5 reactifs : x%.2f   Ecart max/median : x%.2f" % [median, resultats[0][0] / median])

	print("")
	print("--- course entre le heros et les creatures, sur un chapitre ---")
	print("page   reactifs   heros   creatures   rapport")
	for chapitre in Chapitres.nombre():
		print("  chapitre %d : %s" % [chapitre + 1, Chapitres.par_index(chapitre)["nom"]])
		for page in [1, 10, 20, 30, 40, 50]:
			var inventaire := _inventaire_typique(page, chapitre)
			var heros := Puissance.score_total_de_l_inventaire(inventaire) / base
			var creatures := Chapitres.facteur_pv(chapitre, page) * Chapitres.facteur_degats(chapitre, page)
			print("  %3d   %5d      x%5.2f   x%6.2f     %5.2f" % [
				page, inventaire.size(), heros, creatures, heros / creatures])
	quit(0)

# Ce qu'un joueur possede vers cette page : un reactif par draft, tirage moyen.
func _inventaire_typique(page: int, chapitre: int) -> Array:
	var alea := RandomNumberGenerator.new()
	alea.seed = 4242
	var inventaire: Array[String] = []
	for numero in range(1, page + 1):
		if Chapitres.est_alambic(chapitre, numero) or Chapitres.est_boss(chapitre, numero):
			continue
		if numero % Reglages.DRAFT_TOUTES_LES != 0:
			continue
		var propositions := DraftLogique.proposer(inventaire, alea)
		if propositions.is_empty() or propositions[0] == DraftLogique.REPOS:
			continue
		inventaire.append(propositions[alea.randi_range(0, propositions.size() - 1)])
	return inventaire
