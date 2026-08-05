extends RefCounted

# Deux regles d'equilibrage qu'on ne veut plus jamais reperdre :
# une fusion doit valoir mieux que ses deux composants gardes separement, et
# aucune main ne doit ecraser toutes les autres.

const MARGE_FUSION := 1.15   # une essence doit depasser ses composants d'au moins 15 %
const ECART_MAXIMAL := 2.2   # rapport tolere entre la meilleure main et la mediane

func test_toute_fusion_bat_ses_composants(v: Verif) -> void:
	for cle in Recettes.TABLE:
		var morceaux: PackedStringArray = (cle as String).split("+")
		var a := CatalogueReactifs.par_id(morceaux[0])
		var b := CatalogueReactifs.par_id(morceaux[1])
		var essence := CatalogueEssences.par_id(Recettes.TABLE[cle])
		var couple := Puissance.score_des_mods([a.mods, b.mods])
		var seule := Puissance.score_des_mods([essence.mods])
		v.vrai(seule >= couple * MARGE_FUSION,
			"%s (%.2f) doit valoir au moins %.0f %% de %s + %s (%.2f)" % [
				essence.nom, seule, MARGE_FUSION * 100.0, a.nom, b.nom, couple])

func test_une_fusion_vaut_mieux_que_chacun_des_composants(v: Verif) -> void:
	for cle in Recettes.TABLE:
		var morceaux: PackedStringArray = (cle as String).split("+")
		var essence := CatalogueEssences.par_id(Recettes.TABLE[cle])
		var seule := Puissance.score_des_mods([essence.mods])
		for id in morceaux:
			var composant := CatalogueReactifs.par_id(id)
			v.vrai(seule > Puissance.score_des_mods([composant.mods]),
				"%s doit valoir mieux que %s seul" % [essence.nom, composant.nom])

func test_aucune_main_n_ecrase_les_autres(v: Verif) -> void:
	var ids := CatalogueReactifs.ids()
	var scores: Array[float] = []
	var alea := RandomNumberGenerator.new()
	alea.seed = 12345
	for essai in 1500:
		var pioche := ids.duplicate()
		var choisis: Array[String] = []
		for i in 5:
			choisis.append(pioche.pop_at(alea.randi_range(0, pioche.size() - 1)))
		scores.append(Puissance.score_total_de_l_inventaire(choisis))
	scores.sort()
	var median := scores[scores.size() / 2]
	var maximum := scores[scores.size() - 1]
	v.vrai(maximum / median <= ECART_MAXIMAL,
		"la meilleure main sur cinq reactifs vaut x%.2f la mediane, plafond x%.2f" % [
			maximum / median, ECART_MAXIMAL])

func test_les_reactifs_defensifs_ne_sont_pas_des_pieges(v: Verif) -> void:
	# Un reactif purement defensif ne fait pas de degats : c'est normal. Mais il
	# doit apporter quelque chose, sinon le proposer au draft est une punition.
	var base := Puissance.score_total_de_l_inventaire([])
	for id in ["fiole_de_vie", "bouclier_de_sel", "pas_de_chat", "sillage"]:
		v.vrai(Puissance.score_total_de_l_inventaire([id]) > base,
			"%s doit valoir mieux que rien" % id)

func test_le_score_ne_depend_pas_de_l_ordre(v: Verif) -> void:
	var a := Puissance.score_de_l_inventaire(["braise", "perforation", "main_leste"])
	var b := Puissance.score_de_l_inventaire(["main_leste", "braise", "perforation"])
	v.presque(a, b, "l'ordre d'acquisition ne change pas la puissance", 0.0001)
