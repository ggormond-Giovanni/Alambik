class_name Palette
extends RefCounted

# Contrainte de lisibilite de la spec : ce que le joueur doit eviter est
# toujours plus clair et plus sature que le fond. Toutes les couleurs du jeu
# passent par ici, sinon la contrainte se perd fichier par fichier.

const FOND = Color(0.075, 0.105, 0.190)
const CIEL_HAUT = Color(0.105, 0.145, 0.285)
const CIEL_BAS = Color(0.245, 0.190, 0.390)
const PARCHEMIN_SOMBRE = Color(0.145, 0.165, 0.290)
const PARCHEMIN_VEINE = Color(0.480, 0.420, 0.720)
const BORD_PAGE = Color(0.620, 0.570, 0.920)
const SOL_ARENE = Color(0.245, 0.485, 0.430)
const SOL_ARENE_ALT = Color(0.295, 0.555, 0.470)
const BORD_ARENE = Color(0.155, 0.315, 0.345)
const MOUSSE_MAGIQUE = Color(0.430, 0.850, 0.525)
const LUMIERE_AMBIANTE = Color(0.475, 0.910, 1.000)

const HEROS_ROBE = Color(0.965, 0.900, 0.740)
const HEROS_OMBRE = Color(0.48, 0.34, 0.67)
const HEROS_ACCENT = Color(1.00, 0.78, 0.28)

const TIR_NOYAU = Color(1.00, 0.93, 0.72)
const TIR_HALO = Color(1.00, 0.72, 0.28)
const TIR_ENNEMI_NOYAU = Color(1.00, 0.86, 0.90)
const TIR_ENNEMI_HALO = Color(0.95, 0.32, 0.46)

const BRAISE = Color(1.00, 0.48, 0.22)
const GIVRE = Color(0.56, 0.90, 1.00)
const ACIDE = Color(0.62, 0.98, 0.42)

const TEXTE = Color(0.985, 0.955, 0.865)
const TEXTE_ATTENUE = Color(0.790, 0.800, 0.880)
const OR = Color(1.00, 0.72, 0.20)
const ESSENCE = Color(0.690, 0.660, 1.00)
const DANGER = Color(0.98, 0.36, 0.42)

static func effet(nom: String) -> Color:
	match nom:
		"feu": return BRAISE
		"eau": return GIVRE
		"braise": return BRAISE
		"givre": return GIVRE
		"acide": return ACIDE
		"terre": return Color(0.66, 0.50, 0.28)
		"lumiere": return Color(1.00, 0.92, 0.58)
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
