class_name CatalogueElements
extends RefCounted

# Un Element ne porte aucun effet universel. La famille de l'Amélioration decide si
# la fusion modifie un projectile, un Phenomene ou directement le heros.

const PREFIXE_FUSION := "element__"

static var TOUS := {
	"feu": {"nom": "Feu", "teinte": Color(1.00, 0.38, 0.16), "glyphe": "flamme"},
	"eau": {"nom": "Eau", "teinte": Color(0.30, 0.76, 1.00), "glyphe": "vague"},
	"air": {"nom": "Air", "teinte": Color(0.72, 0.94, 1.00), "glyphe": "sillage"},
	"terre": {"nom": "Terre", "teinte": Color(0.66, 0.50, 0.28), "glyphe": "masse"},
	"lumiere": {"nom": "Lumière", "teinte": Color(1.00, 0.92, 0.58), "glyphe": "etoile"},
	"tenebres": {"nom": "Ténèbres", "teinte": Color(0.56, 0.28, 0.78), "glyphe": "oeil"},
}

static func ids() -> Array[String]:
	var resultat: Array[String] = []
	for id in TOUS:
		resultat.append(id)
	resultat.sort()
	return resultat

static func par_id(id: String) -> Dictionary:
	return TOUS.get(id, {})

static func id_fusion(element: String, augment: String) -> String:
	return "%s%s__%s" % [PREFIXE_FUSION, element, augment]

static func est_fusion(id: String) -> bool:
	return id.begins_with(PREFIXE_FUSION) and id.split("__").size() == 3

static func element_de_fusion(id: String) -> String:
	return id.split("__")[1] if est_fusion(id) else ""

static func augment_de_fusion(id: String) -> String:
	return id.split("__")[2] if est_fusion(id) else ""

static func creer_fusion(element: String, augment: String) -> Reactif:
	var donnees := par_id(element)
	var base := CatalogueReactifs.par_id(augment)
	if donnees.is_empty() or base == null:
		return null
	return Reactif.creer(id_fusion(element, augment), "%s · %s" % [base.nom, donnees["nom"]],
		_description(element, base.famille), _mods(element, base.famille), true,
		donnees["teinte"], donnees["glyphe"], 1, base.famille)

static func _mods(element: String, famille: String) -> Dictionary:
	if famille == CatalogueReactifs.HEROS:
		return {"drapeaux": ["transformation_heros_%s" % element]}
	# Un Sceau scelle son Element dans la salle : une aura permanente marque
	# toute creature qui s'approche, sans lui infliger de degats. C'est la seule
	# famille dont l'Element controle au lieu de frapper.
	if famille == CatalogueReactifs.SCEAU:
		return {"drapeaux": ["sceau_element_%s" % element]}
	if famille == CatalogueReactifs.PHENOMENE:
		# L'identite de l'Amélioration est necessaire pour savoir quel Phenomene porte
		# l'Element ; elle reste encodee dans l'id de fusion, pas dans le Tir.
		return {}
	match element:
		"feu": return {"effets": ["feu"]}
		"eau": return {"effets": ["eau"]}
		"air": return {"vitesse_mult": 1.35}
		"terre": return {"effets": ["terre"], "degats_mult": Reglages.TERRE_DEGATS_MULT,
			"vitesse_mult": Reglages.TERRE_VITESSE_MULT}
		"lumiere": return {"effets": ["lumiere"]}
		"tenebres": return {"drapeaux": ["tenebres"]}
	return {}

static func _description(element: String, famille: String) -> String:
	if famille == CatalogueReactifs.HEROS:
		match element:
			"feu": return "Transformation du héros : Phénix à résurrections multiples. L'Amélioration original reste actif."
			"eau": return "Transformation du héros : une résurrection complète. L'Amélioration original reste actif."
			"air": return "Transformation du héros : résurrection aérienne. L'Amélioration original reste actif."
			"terre": return "Transformation du héros : résurrection renforcée et protection temporaire. L'Amélioration original reste actif."
			"lumiere": return "Transformation du héros : résurrection et auréole de puissance. L'Amélioration original reste actif."
			"tenebres": return "Transformation du héros : la sécurité est sacrifiée contre une forte puissance offensive. L'Amélioration original reste actif."
	if famille == CatalogueReactifs.SCEAU:
		match element:
			"feu": return "Le Sceau embrase l'air : les créatures proches prennent feu d'elles-mêmes. L'Amélioration original reste actif."
			"eau": return "Le Sceau noie l'air : les créatures proches deviennent Mouillées, ralenties et vulnérables. L'Amélioration original reste actif."
			"air": return "Le Sceau soulève l'air : son aura porte bien plus loin autour de vous. L'Amélioration original reste actif."
			"terre": return "Le Sceau alourdit l'air : les créatures proches attaquent plus tard. L'Amélioration original reste actif."
			"lumiere": return "Le Sceau irradie : marquer une créature proche vous rend de la vie. L'Amélioration original reste actif."
			"tenebres": return "Le Sceau ronge : les créatures proches encaissent bien plus mal vos attaques. L'Amélioration original reste actif."
	if famille == CatalogueReactifs.PHENOMENE:
		return "Le Phénomène devient vecteur de %s ; l'intensité est adaptée à sa fréquence. L'Amélioration original reste actif." % par_id(element)["nom"]
	match element:
		"feu": return "Les projectiles appliquent des brûlures cumulatives relatives à l'attaque. L'Amélioration original reste actif."
		"eau": return "Les projectiles rendent les cibles Mouillées : ralenties et vulnérables. L'Amélioration original reste actif."
		"air": return "Les projectiles gagnent fortement en vitesse. L'Amélioration original reste actif."
		"terre": return "Les projectiles deviennent lents et lourds ; le premier proc retarde la prochaine attaque. L'Amélioration original reste actif."
		"lumiere": return "Les impacts rendent une part des dégâts sous forme de vie. L'Amélioration original reste actif."
		"tenebres": return "Certains projectiles deviennent des surcharges dévastatrices. L'Amélioration original reste actif."
	return ""
