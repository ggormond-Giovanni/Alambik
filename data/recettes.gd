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

const PREFIXE_AMALGAME := "amalgame__"

static func cle(a: String, b: String) -> String:
	var ids := [a, b]
	ids.sort()
	return "%s+%s" % [ids[0], ids[1]]

static func essence_pour(a: String, b: String) -> String:
	if a == b or not CatalogueReactifs.TOUS.has(a) or not CatalogueReactifs.TOUS.has(b):
		return ""
	var paire := cle(a, b)
	return TABLE.get(paire, PREFIXE_AMALGAME + paire.replace("+", "__"))

# Les deux composants d'une essence, pour l'afficher au draft et a l'alambic.
static func composants_de(essence: String) -> Array[String]:
	for c in TABLE:
		if TABLE[c] == essence:
			var morceaux: PackedStringArray = (c as String).split("+")
			return [morceaux[0], morceaux[1]]
	if essence.begins_with(PREFIXE_AMALGAME):
		var morceaux: PackedStringArray = essence.trim_prefix(PREFIXE_AMALGAME).split("__")
		if morceaux.size() == 2:
			return [morceaux[0], morceaux[1]]
	return []

# Les dix recettes majeures gardent une essence dessinee a la main. Toutes les
# autres paires donnent un amalgame qui conserve exactement les deux familles
# de bonus : aucune combinaison n'est un cul-de-sac.
static func creer_amalgame(id: String) -> Reactif:
	var composants := composants_de(id)
	if composants.size() != 2:
		return null
	var a := CatalogueReactifs.par_id(composants[0])
	var b := CatalogueReactifs.par_id(composants[1])
	if a == null or b == null:
		return null
	return Reactif.creer(id, "Amalgame : %s + %s" % [a.nom, b.nom],
		"Réunit les propriétés des deux augments.", _fusionner_mods(a.mods, b.mods),
		true, a.teinte.lerp(b.teinte, 0.5), a.glyphe, 1)

static func _fusionner_mods(a: Dictionary, b: Dictionary) -> Dictionary:
	var resultat := a.duplicate(true)
	for cle_mod in b:
		if not resultat.has(cle_mod):
			resultat[cle_mod] = b[cle_mod]
		elif cle_mod in ["effets", "drapeaux"]:
			for valeur in b[cle_mod]:
				if not valeur in resultat[cle_mod]:
					resultat[cle_mod].append(valeur)
		elif Mods.CHAMPS_MULT.has(cle_mod):
			resultat[cle_mod] = 1.0 + (float(resultat[cle_mod]) - 1.0) + (float(b[cle_mod]) - 1.0)
		else:
			resultat[cle_mod] = resultat[cle_mod] + b[cle_mod]
	return resultat
