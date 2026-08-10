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
	"perforation+ricochet": "paradoxe_balistique",
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

# Les recettes majeures gardent une essence dessinée à la main. Les autres
# paires reçoivent une signature de comportement : aucune fusion ne se réduit
# à la simple addition de deux colonnes de statistiques.
static func creer_amalgame(id: String) -> Reactif:
	var composants := composants_de(id)
	if composants.size() != 2:
		return null
	var a := CatalogueReactifs.par_id(composants[0])
	var b := CatalogueReactifs.par_id(composants[1])
	if a == null or b == null:
		return null
	var mods := _fusionner_mods(a.mods, b.mods)
	var signature := _signature(composants[0], composants[1])
	_appliquer_signature(mods, signature)
	return Reactif.creer(id, "Amalgame : %s + %s" % [a.nom, b.nom],
		_description_signature(signature), mods,
		true, a.teinte.lerp(b.teinte, 0.5), a.glyphe, 1)

static func _signature(a: String, b: String) -> String:
	var ids := CatalogueReactifs.ids()
	var valeur := ids.find(a) * 17 + ids.find(b) * 31
	return ["fusion_predatrice", "fusion_surcharge", "fusion_instable", "fusion_fragile", "fusion_capricieuse"][posmod(valeur, 5)]

static func _appliquer_signature(mods: Dictionary, signature: String) -> void:
	if not mods.has("drapeaux"):
		mods["drapeaux"] = []
	mods["drapeaux"].append(signature)
	match signature:
		"fusion_predatrice":
			# Excellente et fiable, mais le virage coûte de la vitesse.
			mods["vitesse_mult"] = _combiner_mult(mods.get("vitesse_mult", 1.0), 0.78)
		"fusion_surcharge":
			# Faible au départ, monstrueuse si le joueur garde ses distances.
			mods["degats_mult"] = _combiner_mult(mods.get("degats_mult", 1.0), 0.72)
		"fusion_instable":
			mods["degats_mult"] = _combiner_mult(mods.get("degats_mult", 1.0), 1.75)
			mods["portee_mult"] = _combiner_mult(mods.get("portee_mult", 1.0), 0.68)
		"fusion_fragile":
			mods["fragments_add"] = int(mods.get("fragments_add", 0)) + 7
			mods["degats_mult"] = _combiner_mult(mods.get("degats_mult", 1.0), 0.58)
		"fusion_capricieuse":
			# Mauvaise fusion assumée : énorme potentiel, trajectoire peu fiable.
			mods["degats_mult"] = _combiner_mult(mods.get("degats_mult", 1.0), 2.15)
			mods["cadence_mult"] = _combiner_mult(mods.get("cadence_mult", 1.0), 0.62)

static func _combiner_mult(existant: Variant, ajoute: float) -> float:
	return 1.0 + (float(existant) - 1.0) + (ajoute - 1.0)

static func _description_signature(signature: String) -> String:
	match signature:
		"fusion_predatrice": return "Le projectile chasse sa cible et corrige sa trajectoire, mais vole moins vite."
		"fusion_surcharge": return "Le tir commence faible puis accélère et gagne énormément de puissance en voyageant."
		"fusion_instable": return "Fusion risquée : trajectoire ondulante et portée courte, mais dégâts fortement augmentés."
		"fusion_fragile": return "Le projectile éclate au premier impact en une pluie de fragments peu puissants."
		_: return "Mauvaise fusion volontaire : tir très lent et capricieux, capable d'un impact dévastateur."

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
