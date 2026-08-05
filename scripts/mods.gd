class_name Mods
extends RefCounted

# Un reactif ne contient pas de logique : il decrit ce qu'il change.
#
# Les multiplicateurs s'additionnent au lieu de se composer : deux fois +45 %
# donnent +90 %, pas +110 %. En produit, quatre reactifs de degats faisaient
# une main six fois plus forte que la moyenne — c'est la definition d'une
# combinaison cassee. La somme reste commutative, donc l'ordre d'acquisition
# ne change toujours rien au resultat.

const CHAMPS_ADD := {
	"nb_projectiles_add": "nb_projectiles",
	"rebonds_add": "rebonds",
	"perforations_add": "perforations",
	"fragments_add": "fragments",
	"angle_eventail_add": "angle_eventail",
	"ecart_lateral_add": "ecart_lateral",
}

const CHAMPS_MULT := {
	"degats_mult": "degats",
	"cadence_mult": "cadence",
	"vitesse_mult": "vitesse",
	"portee_mult": "portee",
}

# Rendement decroissant : la deuxieme copie d'un reactif vaut moins que la
# premiere, la troisieme encore moins. Sans cela, empiler trois fois le meme
# reactif rendait le heros seize fois plus fort que ce que la page pouvait
# opposer — mesure a la page 50 du premier chapitre.
const RENDEMENT_COPIES := [1.0, 0.60, 0.40]

static func rendement(copie: int) -> float:
	if copie < RENDEMENT_COPIES.size():
		return RENDEMENT_COPIES[copie]
	return RENDEMENT_COPIES[RENDEMENT_COPIES.size() - 1] * 0.7

# Les champs entiers ne se ponderent pas : un demi-projectile n'existe pas.
# Les reactifs qui en donnent sont plafonnes plus bas, dans leur catalogue.
static func pondere(mod: Dictionary, facteur: float) -> Dictionary:
	if facteur >= 0.999:
		return mod
	var resultat := {}
	for cle in mod:
		if CHAMPS_MULT.has(cle):
			resultat[cle] = 1.0 + (float(mod[cle]) - 1.0) * facteur
		elif cle in ["angle_eventail_add", "ecart_lateral_add"]:
			resultat[cle] = float(mod[cle]) * facteur
		else:
			resultat[cle] = mod[cle]
	return resultat

# La liste de mods d'un inventaire, doublons compris et ponderes.
static func depuis_l_inventaire(inventaire: Array) -> Array:
	var vus := {}
	var liste: Array = []
	for id in inventaire:
		var reactif := CatalogueReactifs.par_id(id)
		if reactif == null:
			reactif = CatalogueEssences.par_id(id)
		if reactif == null:
			continue
		var deja: int = vus.get(id, 0)
		vus[id] = deja + 1
		liste.append(pondere(reactif.mods, rendement(deja)))
	return liste

static func appliquer(base: Tir, mods_liste: Array) -> Tir:
	var t := base.copie()
	var cumuls := {}
	for mod in mods_liste:
		for cle in CHAMPS_ADD:
			if mod.has(cle):
				t.set(CHAMPS_ADD[cle], t.get(CHAMPS_ADD[cle]) + mod[cle])
		for cle in CHAMPS_MULT:
			if mod.has(cle):
				var champ: String = CHAMPS_MULT[cle]
				cumuls[champ] = cumuls.get(champ, 0.0) + (float(mod[cle]) - 1.0)
		for liste in ["effets", "drapeaux"]:
			if mod.has(liste):
				for valeur in mod[liste]:
					if not valeur in t.get(liste):
						t.get(liste).append(valeur)
	for champ in cumuls:
		# Le plancher evite qu'un empilement de malus annule le tir : un
		# projectile a zero degat ou a vitesse nulle n'est plus un projectile.
		t.set(champ, t.get(champ) * maxf(0.15, 1.0 + cumuls[champ]))
	return t
