extends RefCounted

# Les Passifs ne portaient aucun effet permanent : la moitie d'entre eux ne se
# remarquait jamais en combat. Chacun doit maintenant changer quelque chose de
# mesurable, sans quoi son emplacement — il n'y en a qu'un ou deux — ne vaut
# pas d'etre occupe.

func _tous_les_passifs() -> Array[String]:
	var ids: Array[String] = []
	for id in Sorts.PASSIFS:
		ids.append(str(id))
	return ids

func test_chaque_passif_a_un_effet_mesurable(v: Verif) -> void:
	for id in _tous_les_passifs():
		var equipe := {id: 1.0}
		var change := Sorts.multiplicateur_degats_recus(equipe) != 1.0 \
			or Sorts.multiplicateur_recharge_active(equipe) != 1.0 \
			or Sorts.multiplicateur_charge_ultime(equipe) != 1.0 \
			or Sorts.donne_bouclier(equipe) \
			or Sorts.multiplicateur_degats_conditionnel(equipe, 0.1) != 1.0 \
			or Sorts.multiplicateur_degats_recus_conditionnel(equipe, 0.1) != 1.0 \
			or id in ["heritage_reactif", "moisson_vitale", "riposte_alchimique",
				"seconde_chance", "echo_alchimique"]
		v.vrai(change, "le Passif %s doit produire un effet" % id)

func test_les_passifs_permanents_sont_reellement_branches(v: Verif) -> void:
	v.vrai(Sorts.multiplicateur_degats_recus({"rempart_initial": 1.0}) < 1.0,
		"Rempart initial reduit les degats subis en permanence")
	v.vrai(Sorts.multiplicateur_recharge_active({"sang_froid": 1.0}) < 1.0,
		"Sang-froid raccourcit la recharge du Sort en permanence")
	v.vrai(Sorts.multiplicateur_charge_ultime({"reserve_ultime": 1.0}) < 1.0,
		"Réserve d'ultime abaisse la charge requise")
	v.presque(Sorts.multiplicateur_degats_recus({}), 1.0,
		"sans Passif equipe, rien ne change")

# Un Passif pousse au rang maximal ne doit jamais rendre le heros intouchable
# ni son Sort permanent.
func test_les_effets_permanents_restent_bornes(v: Verif) -> void:
	var maximal := Reglages.CAPACITE_BONUS_PAR_RANG * float(Reglages.CAPACITE_RANG_MAX - 1) + 1.0
	v.vrai(Sorts.multiplicateur_degats_recus({"rempart_initial": maximal}) >= 0.30,
		"la reduction permanente garde un plancher")
	v.vrai(Sorts.multiplicateur_recharge_active({"sang_froid": maximal}) >= 0.25,
		"la recharge du Sort garde un plancher")
	v.vrai(Sorts.multiplicateur_charge_ultime({"reserve_ultime": maximal}) >= 0.35,
		"la charge d'ultime garde un plancher")

# Un Sort doit peser face au tir automatique, sinon son emplacement ne sert a
# rien. On compare ce qu'il ajoute au tir soutenu pendant sa propre recharge.
func test_un_sort_pese_face_au_tir_soutenu(v: Verif) -> void:
	for id in Sorts.ACTIFS:
		var sort: Dictionary = Sorts.ACTIFS[id]
		var tirs_pendant_la_recharge := float(sort["recharge"]) * Reglages.HEROS_CADENCE
		var part := float(sort["degats"]) / tirs_pendant_la_recharge
		v.vrai(part >= 0.15, "%s doit ajouter au moins 15 pour cent de la puissance soutenue" % id)
		v.vrai(part <= 0.80, "%s ne doit pas remplacer le tir automatique" % id)

func test_un_ultime_efface_une_rencontre(v: Verif) -> void:
	for id in Sorts.ULTIMES:
		var ultime: Dictionary = Sorts.ULTIMES[id]
		v.vrai(float(ultime["degats"]) >= 20.0,
			"%s doit valoir ses eliminations accumulees" % id)
		v.vrai(int(ultime["charge"]) >= 20,
			"%s garde un prix en eliminations" % id)

func test_les_capacites_montent_avec_leur_rang(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.rangs_sorts = {"rempart_initial": 1}
	var faible := Sorts.multiplicateur_degats_recus({"rempart_initial": r.efficacite_sort("rempart_initial")})
	r.rangs_sorts = {"rempart_initial": Reglages.CAPACITE_RANG_MAX}
	var fort := Sorts.multiplicateur_degats_recus({"rempart_initial": r.efficacite_sort("rempart_initial")})
	v.vrai(fort < faible, "monter le rang d'un Passif renforce son effet permanent")
	r.free()
