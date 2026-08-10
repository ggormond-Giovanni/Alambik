class_name Puissance
extends RefCounted

# Chiffrer ce que vaut un tir. Sans cette fonction, « trop fort » et « plus
# fort que ses deux composants » restent des impressions, et on regle a vue.
#
# Ce n'est pas une simulation : c'est une estimation de degats par seconde,
# ponderee par ce qui touche plusieurs cibles ou dure dans le temps. Elle sert
# a comparer deux tirs entre eux, pas a predire une run.

# Ce que vaut un effet, en part de degats de base ajoutee sur sa duree.
# La foudre et les fragments tirent leur valeur des reglages : si on change
# leur part de degats, l'instrument doit suivre, sinon il mesure un jeu qui
# n'existe plus.
static func valeur_effet(nom: String) -> float:
	match nom:
		"braise": return Reglages.BRAISE_DEGATS_PAR_SECONDE * Reglages.BRAISE_DUREE / Reglages.TIR_DEGATS * 0.30
		"givre": return 0.30    # ne tue pas, mais reduit les coups recus
		"acide": return (Reglages.ACIDE_VULNERABILITE - 1.0)
		"foudre": return Reglages.FOUDRE_PART_DEGATS * 0.7
	return 0.0

# Ce que vaut un drapeau, en multiplicateur du total.
const VALEUR_DRAPEAUX := {
	"flaque_au_rebond": 1.20,
	"gel_bref": 1.10,
	"chaine_longue": 1.15,
	"nuage_a_la_mort": 1.25,
	"sillage_gelant": 1.08,
	"rafale": 2.40,
	"bouclier_explosif": 1.18,
	"tir_en_course": 1.45,   # tirer en marchant change la facon de jouer
}

# Ce qu'un drapeau vaut en survie, pas en degats. Sans cette moitie, une main
# defensive parait trois fois plus faible qu'une main offensive alors qu'elle
# joue simplement un autre jeu — et on corrigerait un desequilibre imaginaire.
const VALEUR_SURVIE := {
	"fiole_de_vie": 1.0 + Reglages.FIOLE_PV / Reglages.HEROS_PV,
	"bouclier_de_sel": 1.15,
	"bouclier_explosif": 1.05,
	"pas_de_chat": 1.18,
	"sillage": 1.10,
	"sillage_gelant": 1.06,
	"tir_en_course": 1.12,
}

static func score(tir: Tir) -> float:
	var par_projectile := tir.degats
	# Une perforation ou un rebond touche une cible de plus, mais pas toujours,
	# et chaque cible supplementaire est frappee moins fort.
	var cumul := 1.0
	var reste := 1.0
	for i in tir.perforations:
		reste *= 1.0 - Reglages.PERFORATION_PERTE
		cumul += 0.6 * reste
	for i in tir.rebonds:
		reste *= 1.0 - Reglages.REBOND_PERTE
		cumul += 0.45 * reste
	par_projectile *= cumul
	# Un fragment part dans une direction quelconque : la moitie environ trouve
	# une cible, et chacun ne porte qu'une part des degats.
	par_projectile *= 1.0 + 0.5 * Reglages.FRAGMENT_PART_DEGATS * float(tir.fragments)
	var brut := par_projectile * float(tir.nb_projectiles) * tir.cadence

	# Un projectile plus rapide et de plus longue portee rate moins souvent.
	brut *= 1.0 + 0.15 * (tir.vitesse / maxf(1.0, Reglages.TIR_VITESSE) - 1.0)
	brut *= 1.0 + 0.10 * (tir.portee / maxf(1.0, Reglages.TIR_PORTEE) - 1.0)

	var part_effets := 0.0
	for nom in tir.effets:
		part_effets += valeur_effet(nom)
	brut *= 1.0 + part_effets

	for nom in tir.drapeaux:
		brut *= VALEUR_DRAPEAUX.get(nom, 1.0)
	return brut

# Ce que la main permet d'encaisser. Le givre compte aussi : un ennemi ralenti
# frappe moins souvent.
static func survie(tir: Tir) -> float:
	var facteur := 1.0
	for nom in tir.drapeaux:
		facteur *= VALEUR_SURVIE.get(nom, 1.0)
	if "givre" in tir.effets:
		facteur *= 1.12
	return facteur

static func survie_de_l_inventaire(inventaire: Array) -> float:
	return survie(Mods.appliquer(Tir.de_base(Stats.depuis_reglages()), _mods_de(inventaire)))

# Offense et survie reunies : c'est ce qui decide d'une run, pas l'une des deux.
static func score_total_de_l_inventaire(inventaire: Array) -> float:
	return score_de_l_inventaire(inventaire) * survie_de_l_inventaire(inventaire)

static func _mods_de(inventaire: Array) -> Array:
	return Mods.depuis_l_inventaire(inventaire)

static func score_des_mods(mods_liste: Array) -> float:
	return score(Mods.appliquer(Tir.de_base(Stats.depuis_reglages()), mods_liste))

static func score_de_l_inventaire(inventaire: Array) -> float:
	return score(Mods.appliquer(Tir.de_base(Stats.depuis_reglages()), _mods_de(inventaire)))

static func score_de_base() -> float:
	return score(Tir.de_base(Stats.depuis_reglages()))
