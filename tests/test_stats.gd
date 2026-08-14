extends RefCounted

func test_valeurs_de_depart(v: Verif) -> void:
	var s := Stats.depuis_reglages()
	v.presque(s.pv, Reglages.HEROS_PV, "le heros commence a ses PV max")
	v.presque(s.pv_max, Reglages.HEROS_PV, "PV max lus dans les reglages")

# Monter de niveau ne changeait rien au combat : le niveau de compte n'apportait
# aucune statistique. Il porte maintenant le socle que tout le reste multiplie.
func test_le_niveau_porte_les_statistiques_de_base(v: Verif) -> void:
	v.presque(Stats.base_degats(1), Reglages.TIR_DEGATS, "le niveau un est la reference")
	v.presque(Stats.base_pv(1), Reglages.HEROS_PV, "le niveau un est la reference")
	for niveau in [2, 10, 30]:
		v.vrai(Stats.base_degats(niveau) > Stats.base_degats(niveau - 1),
			"le niveau %d frappe plus fort que le precedent" % niveau)
		v.vrai(Stats.base_pv(niveau) > Stats.base_pv(niveau - 1),
			"le niveau %d encaisse mieux que le precedent" % niveau)
	var haut := Stats.depuis_reglages({}, {}, {}, Reglages.NIVEAU_REFERENCE_FIN)
	var bas := Stats.depuis_reglages({}, {}, {}, 1)
	v.vrai(haut.degats > bas.degats * 1.4,
		"un compte de fin de campagne frappe nettement plus fort qu'un compte neuf")
	v.vrai(haut.pv_max > bas.pv_max * 1.5, "et encaisse nettement mieux")

# Le socle et les multiplicateurs doivent se composer, pas se remplacer.
func test_les_bonus_multiplient_le_socle_du_niveau(v: Verif) -> void:
	var rangs := {"force": ArbreCompetences.rangs("force")}
	var sans_niveau := Stats.depuis_reglages(rangs, {}, {}, 1)
	var avec_niveau := Stats.depuis_reglages(rangs, {}, {}, Reglages.NIVEAU_REFERENCE_FIN)
	var rapport_attendu := Stats.base_degats(Reglages.NIVEAU_REFERENCE_FIN) / Reglages.TIR_DEGATS
	v.presque(avec_niveau.degats / sans_niveau.degats, rapport_attendu,
		"les Maitrises multiplient le socle du niveau au lieu de s'y substituer")

func test_blesser_retire_des_pv(v: Verif) -> void:
	var s := Stats.depuis_reglages()
	s.blesser(10.0)
	v.presque(s.pv, Reglages.HEROS_PV - 10.0, "la blessure retire des PV")

func test_pv_ne_descendent_pas_sous_zero(v: Verif) -> void:
	var s := Stats.depuis_reglages()
	s.blesser(Reglages.HEROS_PV * 10.0)
	v.presque(s.pv, 0.0, "les PV plafonnent a zero")
	v.vrai(s.est_mort(), "a zero PV le heros est mort")

func test_soigner_ne_depasse_pas_le_max(v: Verif) -> void:
	var s := Stats.depuis_reglages()
	s.blesser(5.0)
	s.soigner(50.0)
	v.presque(s.pv, s.pv_max, "le soin plafonne aux PV max")

func test_un_objet_apporte_son_profil_multiplie_par_la_forge(v: Verif) -> void:
	# Anneau I du premier Monde : son facteur de Monde vaut un, donc le bonus
	# lisible est exactement son profil multiplie par la Forge.
	var id := CatalogueObjets.objet_du_chapitre(0)
	var profil: Dictionary = CatalogueObjets.OBJETS[id]["profil"]
	var forge := 1.0 + 2.0 * Reglages.FORGE_BONUS_PAR_NIVEAU
	var bonus := CatalogueObjets.bonus_effectifs({"anneau_gauche": id}, {id: 2})
	v.presque(float(bonus["degats"]), float(profil["degats"]) * forge,
		"l'objet apporte son profil, la Forge le multiplie")
	var s := Stats.depuis_reglages({}, {}, bonus)
	v.presque(s.degats, Reglages.TIR_DEGATS * (1.0 + float(profil["degats"]) * forge),
		"le bonus d'objet est applique en combat")

func test_un_objet_non_forge_vaut_deja_quelque_chose(v: Verif) -> void:
	var id := CatalogueObjets.objet_du_chapitre(0)
	var bonus := CatalogueObjets.bonus_effectifs({"anneau_gauche": id}, {})
	v.vrai(float(bonus["degats"]) > 0.0,
		"trouver un objet apporte un gain immediat, avant toute Pierre de forge")

func test_le_collier_defend_et_l_anneau_attaque(v: Verif) -> void:
	var collier := CatalogueObjets.objet_du_chapitre(2)
	var bonus := CatalogueObjets.bonus_effectifs({"collier": collier}, {})
	v.vrai(float(bonus["pv"]) > float(bonus["degats"]),
		"le Collier est d'abord un objet defensif")
	var anneau := CatalogueObjets.objet_du_chapitre(0)
	var offensif := CatalogueObjets.bonus_effectifs({"anneau_gauche": anneau}, {})
	v.presque(float(offensif["pv"]), 0.0, "l'Anneau I ne donne pas de PV")

# Trente objets rigoureusement identiques ne donnaient aucune raison de chercher
# l'equipement tardif : seul le niveau de Forge comptait.
func test_un_objet_tardif_vaut_mieux_qu_un_objet_du_premier_monde(v: Verif) -> void:
	var premier := CatalogueObjets.objet_du_chapitre(0)
	var dernier := CatalogueObjets.objet_du_chapitre((Chapitres.MONDES.size() - 1) * 3)
	var tot := CatalogueObjets.bonus_objet(premier, 0)
	var tard := CatalogueObjets.bonus_objet(dernier, 0)
	v.vrai(float(tard["degats"]) > float(tot["degats"]) * 5.0,
		"l'Anneau du dernier Monde ecrase celui du premier a Forge egale")
