class_name CatalogueReactifs
extends RefCounted

# Catalogue exact des seize Augments actuellement decides. Les Elements vivent
# dans leur propre catalogue et ne peuvent donc jamais polluer les level-ups.

const PROJECTILE := "projectile"
const HEROS := "heros"
const PHENOMENE := "phenomene"

static var TOUS := {
	"tir_multiple": Reactif.creer("tir_multiple", "Tir multiple",
		"Ajoute un projectile simultané. Chaque trait inflige moins de dégâts.",
		{"nb_projectiles_add": 1, "ecart_lateral_add": 30.0, "degats_mult": 0.72},
		false, Color(0.98, 0.82, 0.42), "eventail", 1, PROJECTILE),
	"salve": Reactif.creer("salve", "Salve",
		"Chaque attaque devient une salve de deux tirs rapides moins puissants.",
		{"drapeaux": ["rafale"], "degats_mult": 0.72},
		false, Color(1.00, 0.72, 0.34), "triple_barre", 1, PROJECTILE),
	"ricochet": Reactif.creer("ricochet", "Ricochet",
		"Les projectiles rebondissent d'un ennemi vers un autre. Les murs les arrêtent.",
		{"rebonds_add": 1}, false, Color(0.62, 0.86, 0.96), "zigzag", 1, PROJECTILE),
	"perforation": Reactif.creer("perforation", "Perforation",
		"Les projectiles traversent un ennemi et poursuivent leur trajectoire.",
		{"perforations_add": 1}, false, Color(0.86, 0.90, 0.98), "lance", 1, PROJECTILE),
	"fragmentation": Reactif.creer("fragmentation", "Fragmentation",
		"L'impact libère plusieurs projectiles secondaires.",
		{"fragments_add": 3, "degats_mult": 0.88}, false, Color(0.80, 0.96, 0.94), "eclats", 1, PROJECTILE),
	"homing": Reactif.creer("homing", "Homing",
		"Les projectiles recherchent leur cible et corrigent leur trajectoire.",
		{"drapeaux": ["homing"], "vitesse_mult": 0.88}, false, Color(0.72, 0.88, 1.00), "oeil", 1, PROJECTILE),

	"egide": Reactif.creer("egide", "Égide",
		"Annule la première attaque subie dans chaque salle.",
		{"drapeaux": ["egide"]}, false, Color(0.88, 0.92, 1.00), "hexagone", 1, HEROS),
	"regeneration": Reactif.creer("regeneration", "Régénération",
		"Récupère une part des PV entre les salles.",
		{"drapeaux": ["regeneration"]}, false, Color(0.54, 0.92, 0.62), "goutte", 1, HEROS),
	"avidite": Reactif.creer("avidite", "Avidité",
		"Augmente l'XP de run et les Gouttes obtenues pendant cette tentative.",
		{"drapeaux": ["avidite"]}, false, Color(1.00, 0.78, 0.30), "fiole", 1, HEROS),
	"courageux": Reactif.creer("courageux", "Courageux",
		"Les dégâts augmentent progressivement à mesure que les PV diminuent.",
		{"drapeaux": ["courageux"]}, false, Color(0.98, 0.42, 0.40), "flamme", 1, HEROS),
	"mannequin": Reactif.creer("mannequin", "Mannequin",
		"Rester immobile assez longtemps augmente la puissance et la cadence.",
		{"drapeaux": ["mannequin"]}, false, Color(0.82, 0.72, 0.54), "masse", 1, HEROS),

	"familier_tireur": Reactif.creer("familier_tireur", "Familier tireur",
		"Un familier à distance attaque automatiquement les ennemis.",
		{"drapeaux": ["familier_tireur"]}, false, Color(0.66, 0.86, 1.00), "oeil", 1, PHENOMENE),
	"meteores": Reactif.creer("meteores", "Météores",
		"Un impact de zone puissant tombe périodiquement sur un ennemi.",
		{"drapeaux": ["meteores"]}, false, Color(1.00, 0.52, 0.28), "etoile", 1, PHENOMENE),
	"zone_heros": Reactif.creer("zone_heros", "Zone alchimique",
		"Une zone offensive entoure le héros et récompense le jeu à courte portée.",
		{"drapeaux": ["zone_heros"]}, false, Color(0.68, 0.94, 0.66), "hexagone", 1, PHENOMENE),
	"familier_gardien": Reactif.creer("familier_gardien", "Familier gardien",
		"Un gardien de mêlée attaque, intercepte les menaces et revient après sa mort.",
		{"drapeaux": ["familier_gardien"]}, false, Color(0.78, 0.72, 0.94), "patte", 1, PHENOMENE),
	"orbes_chargees": Reactif.creer("orbes_chargees", "Orbes chargées",
		"Des orbes s'accumulent pendant le mouvement puis partent avec la prochaine attaque.",
		{"drapeaux": ["orbes_chargees"]}, false, Color(0.94, 0.72, 1.00), "cristal", 1, PHENOMENE),
}

static func par_id(id: String) -> Reactif:
	return TOUS.get(id)

static func ids() -> Array[String]:
	var liste: Array[String] = []
	for id in TOUS:
		liste.append(id)
	liste.sort()
	return liste

static func ids_de_famille(famille: String) -> Array[String]:
	var liste: Array[String] = []
	for id in ids():
		if par_id(id).famille == famille:
			liste.append(id)
	return liste
