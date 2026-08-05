class_name CatalogueReactifs
extends RefCounted

# Donnee pure : aucun reactif ne contient de logique, seulement ce qu'il change.
# Les textes affiches gardent leurs accents, les identifiants n'en ont pas.
# La teinte et le glyphe servent a dessiner l'icone : pas de fichier image.

static var TOUS := {
	"fleche_double": Reactif.creer("fleche_double", "Flèche double",
		"Un projectile de plus, en léger éventail.",
		{"nb_projectiles_add": 1, "angle_eventail_add": deg_to_rad(5.0), "ecart_lateral_add": 30.0, "degats_mult": 0.85},
		false, Color(0.98, 0.82, 0.42), "eventail", 2),
	"ricochet": Reactif.creer("ricochet", "Ricochet",
		"Les projectiles rebondissent une fois.",
		{"rebonds_add": 1},
		false, Color(0.62, 0.86, 0.96), "zigzag", 2),
	"perforation": Reactif.creer("perforation", "Perforation",
		"Les projectiles traversent un ennemi.",
		{"perforations_add": 1},
		false, Color(0.86, 0.90, 0.98), "lance", 2),
	"braise": Reactif.creer("braise", "Braise",
		"Les cibles touchées brûlent.",
		{"effets": ["braise"]},
		false, Color(1.00, 0.48, 0.22), "flamme", 1),
	"givre": Reactif.creer("givre", "Givre",
		"Les cibles touchées sont ralenties.",
		{"effets": ["givre"]},
		false, Color(0.56, 0.90, 1.00), "cristal", 1),
	"foudre": Reactif.creer("foudre", "Foudre",
		"L'impact frappe un ennemi voisin.",
		{"effets": ["foudre"]},
		false, Color(0.98, 0.94, 0.45), "eclair", 1),
	"acide": Reactif.creer("acide", "Acide",
		"Les cibles touchées subissent plus de dégâts.",
		{"effets": ["acide"]},
		false, Color(0.62, 0.98, 0.42), "goutte", 1),
	"eclat_de_verre": Reactif.creer("eclat_de_verre", "Éclat de verre",
		"Les projectiles se fragmentent à l'impact.",
		{"fragments_add": 2},
		false, Color(0.80, 0.96, 0.94), "eclats", 2),
	"main_leste": Reactif.creer("main_leste", "Main leste",
		"Cadence de tir augmentée.",
		{"cadence_mult": 1.25},
		false, Color(0.96, 0.86, 0.66), "triple_barre"),
	"encre_lourde": Reactif.creer("encre_lourde", "Encre lourde",
		"Projectiles plus lourds : plus de dégâts, moins de vitesse.",
		{"degats_mult": 1.45, "vitesse_mult": 0.7},
		false, Color(0.58, 0.52, 0.86), "masse"),
	"pas_de_chat": Reactif.creer("pas_de_chat", "Pas de chat",
		"Déplacement plus rapide.",
		{"drapeaux": ["pas_de_chat"]},
		false, Color(0.72, 0.94, 0.78), "patte", 1),
	"fiole_de_vie": Reactif.creer("fiole_de_vie", "Fiole de vie",
		"Points de vie maximum augmentés, et soin immédiat.",
		{"drapeaux": ["fiole_de_vie"]},
		false, Color(0.98, 0.42, 0.52), "fiole", 1),
	"oeil_de_lynx": Reactif.creer("oeil_de_lynx", "Œil de lynx",
		"Projectiles plus rapides et de plus longue portée.",
		{"vitesse_mult": 1.3, "portee_mult": 1.25},
		false, Color(0.94, 0.78, 0.98), "oeil"),
	"bouclier_de_sel": Reactif.creer("bouclier_de_sel", "Bouclier de sel",
		"Absorbe un coup, se reforme à chaque salle.",
		{"drapeaux": ["bouclier_de_sel"]},
		false, Color(0.88, 0.92, 1.00), "hexagone", 1),
	"sillage": Reactif.creer("sillage", "Sillage",
		"Se déplacer laisse une traînée qui ralentit.",
		{"drapeaux": ["sillage"]},
		false, Color(0.66, 0.78, 0.96), "vague", 1),
}

static func par_id(id: String) -> Reactif:
	return TOUS.get(id)

static func ids() -> Array[String]:
	var liste: Array[String] = []
	for cle in TOUS:
		liste.append(cle)
	liste.sort()
	return liste
