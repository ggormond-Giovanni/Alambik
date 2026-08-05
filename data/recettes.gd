class_name Recettes
extends RefCounted

# Source unique des fusions. Aucune autre liste ne decrit les recettes :
# deux listes finissent toujours par diverger.
# La cle est la paire triee, ce qui rend la fusion commutative par construction.

const TABLE := {
	"braise+ricochet": "trainee_etincelles",
	"eclat_de_verre+fleche_double": "volee_echardes",
	"encre_lourde+givre": "marteau_de_glace",
	"acide+foudre": "circuit_corrosif",
	"foudre+perforation": "lance_orage",
	"acide+braise": "vapeur_mordante",
	"givre+sillage": "piste_de_gel",
	"fleche_double+main_leste": "rafale_alambic",
	"bouclier_de_sel+givre": "aura_de_cristal",
	"oeil_de_lynx+pas_de_chat": "tir_en_course",
}

static func cle(a: String, b: String) -> String:
	var ids := [a, b]
	ids.sort()
	return "%s+%s" % [ids[0], ids[1]]

static func essence_pour(a: String, b: String) -> String:
	return TABLE.get(cle(a, b), "")

# Les deux composants d'une essence, pour l'afficher au draft et a l'alambic.
static func composants_de(essence: String) -> Array[String]:
	for c in TABLE:
		if TABLE[c] == essence:
			var morceaux: PackedStringArray = (c as String).split("+")
			return [morceaux[0], morceaux[1]]
	return []
