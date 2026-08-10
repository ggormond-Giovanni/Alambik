class_name CatalogueEssences
extends RefCounted

# Une essence est un reactif comme un autre, simplement inaccessible au draft
# tant que le joueur ne possede pas ses deux composants.

static var TOUS := {
	"trainee_etincelles": Reactif.creer("trainee_etincelles", "Traînée d'étincelles",
		"Chaque rebond laisse une flaque de feu.",
		{"rebonds_add": 2, "effets": ["braise"], "drapeaux": ["flaque_au_rebond"]},
		true, Color(1.00, 0.62, 0.28), "flamme"),
	"volee_echardes": Reactif.creer("volee_echardes", "Volée d'échardes",
		"L'impact projette cinq fragments ; chaque projectile inflige moins de dégâts.",
		{"nb_projectiles_add": 1, "fragments_add": 5, "angle_eventail_add": deg_to_rad(6.0), "ecart_lateral_add": 34.0, "degats_mult": 0.62},
		true, Color(0.88, 0.98, 0.92), "eclats"),
	"marteau_de_glace": Reactif.creer("marteau_de_glace", "Marteau de glace",
		"Projectile lent et lourd qui gèle brièvement.",
		{"degats_mult": 2.2, "vitesse_mult": 0.55, "effets": ["givre"], "drapeaux": ["gel_bref"]},
		true, Color(0.70, 0.88, 1.00), "masse"),
	"circuit_corrosif": Reactif.creer("circuit_corrosif", "Circuit corrosif",
		"La chaîne applique l'acide et porte plus loin.",
		{"effets": ["foudre", "acide"], "drapeaux": ["chaine_longue"]},
		true, Color(0.78, 0.98, 0.44), "eclair"),
	"lance_orage": Reactif.creer("lance_orage", "Lance d'orage",
		"Un trait traversant qui électrise toute la ligne.",
		{"perforations_add": 3, "effets": ["foudre"], "vitesse_mult": 1.4},
		true, Color(0.94, 0.92, 0.58), "lance"),
	"vapeur_mordante": Reactif.creer("vapeur_mordante", "Vapeur mordante",
		"Un nuage persistant naît de chaque ennemi abattu.",
		{"effets": ["braise", "acide"], "drapeaux": ["nuage_a_la_mort"]},
		true, Color(0.82, 0.92, 0.40), "nuage"),
	"piste_de_gel": Reactif.creer("piste_de_gel", "Piste de gel",
		"La traînée laissée derrière soi gèle au lieu de ralentir.",
		{"drapeaux": ["sillage", "sillage_gelant"], "effets": ["givre"], "cadence_mult": 1.15, "degats_mult": 1.25},
		true, Color(0.62, 0.94, 1.00), "vague"),
	"rafale_alambic": Reactif.creer("rafale_alambic", "Rafale d'alambic",
		"Chaque tir part en rafale de trois, avec une cadence et des dégâts réduits.",
		{"cadence_mult": 0.82, "drapeaux": ["rafale"], "nb_projectiles_add": 1, "ecart_lateral_add": 26.0, "degats_mult": 0.62},
		true, Color(1.00, 0.86, 0.50), "triple_barre"),
	"aura_de_cristal": Reactif.creer("aura_de_cristal", "Aura de cristal",
		"Le bouclier brisé explose en éclats gelants.",
		{"drapeaux": ["bouclier_de_sel", "bouclier_explosif"], "effets": ["givre"]},
		true, Color(0.78, 0.94, 1.00), "hexagone"),
	"tir_en_course": Reactif.creer("tir_en_course", "Tir en course",
		"On tire en se déplaçant, à cadence réduite.",
		{"drapeaux": ["tir_en_course", "pas_de_chat"], "cadence_mult": 0.9, "vitesse_mult": 1.25, "portee_mult": 1.2},
		true, Color(0.86, 1.00, 0.86), "patte"),
	"paradoxe_balistique": Reactif.creer("paradoxe_balistique", "Paradoxe balistique",
		"Traverse tous les ennemis. Sur un mur, le trait repart sans perdre de puissance et peut rebondir indéfiniment.",
		{"perforations_add": 999, "degats_mult": 0.82,
			"drapeaux": ["perfore_tout", "rebond_murs_infini"]},
		true, Color(0.76, 0.92, 1.00), "zigzag"),
}

static func par_id(id: String) -> Reactif:
	var essence: Reactif = TOUS.get(id)
	return essence if essence != null else Recettes.creer_amalgame(id)

static func ids() -> Array[String]:
	var liste: Array[String] = []
	for cle in TOUS:
		liste.append(cle)
	liste.sort()
	return liste
