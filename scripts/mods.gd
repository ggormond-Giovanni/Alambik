class_name Mods
extends RefCounted

# Un reactif ne contient pas de logique : il decrit ce qu'il change.
# Les additions et les multiplications commutent, donc l'ordre d'acquisition
# des reactifs n'influe jamais sur le resultat.

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

static func appliquer(base: Tir, mods_liste: Array) -> Tir:
	var t := base.copie()
	for mod in mods_liste:
		for cle in CHAMPS_ADD:
			if mod.has(cle):
				t.set(CHAMPS_ADD[cle], t.get(CHAMPS_ADD[cle]) + mod[cle])
		for cle in CHAMPS_MULT:
			if mod.has(cle):
				t.set(CHAMPS_MULT[cle], t.get(CHAMPS_MULT[cle]) * mod[cle])
		for liste in ["effets", "drapeaux"]:
			if mod.has(liste):
				for valeur in mod[liste]:
					if not valeur in t.get(liste):
						t.get(liste).append(valeur)
	return t
