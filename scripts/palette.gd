class_name Palette
extends RefCounted

# Contrainte de lisibilite de la spec : ce que le joueur doit eviter est
# toujours plus clair et plus sature que le fond. Toutes les couleurs du jeu
# passent par ici, sinon la contrainte se perd fichier par fichier.

const FOND = Color(0.030, 0.022, 0.052)
const PARCHEMIN_SOMBRE = Color(0.105, 0.075, 0.155)
const PARCHEMIN_VEINE = Color(0.245, 0.175, 0.330)
const BORD_PAGE = Color(0.455, 0.315, 0.590)
const SOL_ARENE = Color(0.105, 0.185, 0.175)
const SOL_ARENE_ALT = Color(0.125, 0.215, 0.190)
const BORD_ARENE = Color(0.075, 0.105, 0.115)
const MOUSSE_MAGIQUE = Color(0.205, 0.390, 0.285)

const HEROS_ROBE = Color(0.925, 0.880, 0.745)
const HEROS_OMBRE = Color(0.72, 0.66, 0.55)
const HEROS_ACCENT = Color(1.00, 0.82, 0.42)

const TIR_NOYAU = Color(1.00, 0.93, 0.72)
const TIR_HALO = Color(1.00, 0.72, 0.28)
const TIR_ENNEMI_NOYAU = Color(1.00, 0.86, 0.90)
const TIR_ENNEMI_HALO = Color(0.95, 0.32, 0.46)

const BRAISE = Color(1.00, 0.48, 0.22)
const GIVRE = Color(0.56, 0.90, 1.00)
const FOUDRE = Color(0.98, 0.94, 0.45)
const ACIDE = Color(0.62, 0.98, 0.42)

const TEXTE = Color(0.94, 0.91, 0.84)
const TEXTE_ATTENUE = Color(0.72, 0.67, 0.70)
const OR = Color(1.00, 0.74, 0.24)
const ESSENCE = Color(0.78, 0.58, 1.00)
const DANGER = Color(0.98, 0.36, 0.42)

static func effet(nom: String) -> Color:
	match nom:
		"braise": return BRAISE
		"givre": return GIVRE
		"foudre": return FOUDRE
		"acide": return ACIDE
	return TEXTE

# Teinte du tir a partir de ses effets : le joueur voit ce qu'il a construit.
# On garde la composante la plus forte de chaque canal au lieu de moyenner :
# la moyenne de trois effets donnait un brun terne, illisible sur le parchemin.
static func teinte_du_tir(effets: Array) -> Color:
	if effets.is_empty():
		return TIR_HALO
	var vive := Color(0, 0, 0)
	for nom in effets:
		var c := effet(nom)
		vive = Color(maxf(vive.r, c.r), maxf(vive.g, c.g), maxf(vive.b, c.b))
	return vive
