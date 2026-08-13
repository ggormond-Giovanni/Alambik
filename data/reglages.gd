class_name Reglages
extends RefCounted

# Source unique de l'equilibrage. Aucune de ces valeurs ne doit reapparaitre
# en dur ailleurs : les regler ne doit jamais demander de relire le combat.
#
# Ecart assume par rapport au plan : classe globale de constantes plutot
# qu'autoload. Un autoload n'existe que dans une SceneTree ; les suites de
# tests headless doivent pouvoir lire l'equilibrage sans en monter une.

const HEROS_PV := 100.0
const HEROS_VITESSE := 560.0
const HEROS_ACCELERATION := 3100.0
const HEROS_FREINAGE := 4200.0
const HEROS_CADENCE := 2.4          # tirs par seconde
const HEROS_INVULNERABILITE := 0.6  # secondes apres un coup recu
const HEROS_RAYON := 31.0

const TIR_DEGATS := 10.0
const TIR_VITESSE := 900.0
const TIR_PORTEE := 1400.0
const TIR_DELAI_ARRET := 0.12       # temps d'arret avant que le tir reprenne

const BRAISE_DEGATS_PAR_SECONDE := 6.0
const BRAISE_DUREE := 4.0
const GIVRE_RALENTISSEMENT := 0.45  # facteur de vitesse applique
const GIVRE_DUREE := 2.0
const ACIDE_VULNERABILITE := 1.35   # multiplicateur de degats subis
const ACIDE_DUREE := 4.0
const TERRE_DEGATS_MULT := 1.70
const TERRE_VITESSE_MULT := 0.68
const TERRE_RETARD_ATTAQUE := 2.0
const LUMIERE_VOL_DE_VIE := 0.035
const TENEBRES_CHANCE_SURCHARGE := 0.22
const TENEBRES_SURCHARGE_MULT := 3.2
const REGENERATION_PART := 0.06
const AVIDITE_XP_MULT := 1.20
const AVIDITE_GOUTTES_MULT := 1.20
const COURAGEUX_BONUS_MAX := 0.70
const MANNEQUIN_DELAI := 1.2
const MANNEQUIN_DEGATS_MULT := 1.35
const MANNEQUIN_CADENCE_MULT := 1.25
const FAMILIER_TIR_INTERVALLE := 0.85
const FAMILIER_TIR_PART_DEGATS := 0.42
const METEORE_INTERVALLE := 4.0
const METEORE_PART_DEGATS := 2.6
const METEORE_RAYON := 150.0
const ZONE_HEROS_INTERVALLE := 0.45
const ZONE_HEROS_PART_DEGATS := 0.32
const ZONE_HEROS_RAYON := 145.0
const GARDIEN_INTERVALLE := 0.75
const GARDIEN_PART_DEGATS := 0.55
const GARDIEN_PV := 55.0
const GARDIEN_REAPPARITION := 6.0
const ORBE_INTERVALLE := 2.0
const ORBE_MAX := 3
const ORBE_PART_DEGATS := 0.55
const PHENOMENE_AIR_INTERVALLE_MULT := 0.75
const FEU_DOT_PART_PAR_SECONDE := 0.18
const PHENIX_RESURRECTIONS := 3
const PHENIX_PV_PART := 0.38
const EAU_RESURRECTIONS := 1
const AIR_RESURRECTIONS := 1
const AIR_RESURRECTION_PV_PART := 0.55
const TERRE_RESURRECTIONS := 1
const TERRE_RESURRECTION_PV_PART := 0.50
const TERRE_PROTECTION_DUREE := 6.0
const TERRE_PROTECTION_MULT := 0.45
const LUMIERE_RESURRECTIONS := 1
const LUMIERE_RESURRECTION_PV_PART := 0.55
const LUMIERE_AUREOLE_DUREE := 8.0
const LUMIERE_AUREOLE_DEGATS_MULT := 1.65
const TENEBRES_HEROS_DEGATS_MULT := 1.55
# Un eclat qui frappe presque aussi fort que le tir d'origine transforme
# Eclat de verre en multiplicateur : c'etait la moitie des mains cassees.
const FRAGMENT_PART_DEGATS := 0.28
const FRAGMENT_PORTEE := 260.0
# Un trait qui traverse quatre ennemis en frappant chacun a pleine puissance
# est un multiplicateur deguise : il perd de la force a chaque cible, et a
# chaque rebond. C'est ce qui separe une bonne main d'une main cassee.
const PERFORATION_PERTE := 0.35
const REBOND_PERTE := 0.25

const FLAQUE_DUREE := 3.0
const FLAQUE_RAYON := 70.0
const NUAGE_DUREE := 3.5
const NUAGE_RAYON := 130.0
const GEL_BREF_DUREE := 0.7
const RAFALE_NOMBRE := 2
const RAFALE_INTERVALLE := 0.07

const ARENE_MARGE_LATERALE := 32.0
const ARENE_HAUT := 128.0            # une seule barre compacte sous la safe area
const ARENE_BAS := 64.0              # le joystick flotte par-dessus l'arene

# La longueur d'un chapitre et la place de ses alambics vivent dans
# data/chapitres.gd : ces constantes ne servent plus qu'au repli, quand aucun
# chapitre n'est charge.
const SALLES_PAR_RUN := 20

# Montee en puissance sur la longueur d'un chapitre. Vingt salles a difficulte
# plate seraient vingt fois la meme salle.
# Facteurs atteints a la derniere salle d'un chapitre : les PV sont multiplies
# par 1 + MONTEE_PV, les degats par 1 + MONTEE_DEGATS, suivant une courbe
# geometrique. Cales sur la puissance mesuree du heros au meme endroit.
const MONTEE_PV := 7.0
const MONTEE_DEGATS := 0.75
const DEFI_MONTEE_PV := 3.0       # x4 entre la premiere et la derniere rencontre
const DEFI_MONTEE_DEGATS := 1.0   # x2 sur les degats, en plus de la densite
const DEFI_PV_BASE := 1.25
const DEFI_DEGATS_BASE := 1.15

# Un Augment se reprend, mais pas indefiniment : six choix doivent construire
# un build, pas empiler automatiquement la meme carte.
const COPIES_MAX := 3
const SOIN_ALAMBIC := 0.20   # respiration garantie avant chaque boss

# Seuils provisoires d'XP de run. Ils visent la courbe 2/4/5/6 avant les salles
# 5/10/15/20 et doivent etre recalibres avec les rencontres definitives.
const XP_RUN_SEUILS := [9, 25, 50, 78, 130, 195]

# Premier jet d'economie longue : trente acquisitions reparties sur les trente
# chapitres. Les couts sont partages par les trois branches pour rester lisibles.
const MAITRISE_COUTS := [60, 100, 170, 280, 460, 760, 1250, 2050, 3400, 5600]
const GOUTTES_MULT_PAR_CHAPITRE := 1.11

# Progression provisoire des capacites d'Epreuve : obtenir reste le gros
# deblocage, les exemplaires suivants apportent une amelioration mesuree.
const CAPACITE_RANG_MAX := 5
const CAPACITE_BONUS_PAR_RANG := 0.15

# Valeurs de prototype centralisees : l'economie exacte de Forge reste a
# equilibrer, mais la progression appartient deja au slot et non a l'objet.
const FORGE_DEGATS_PAR_NIVEAU := 0.025
const FORGE_PV_PAR_NIVEAU := 4.0
const FORGE_COUT_BASE := 10
const FORGE_COUT_PAR_NIVEAU := 4
const MINE_PIERRES_RECOMPENSE := 25
# La Mine est une survie complete : peu de pression au depart, une horde qui
# monte pendant cinq minutes, puis un boss. Les multiplicateurs s'appliquent
# progressivement aux ennemis apparus, pas retroactivement a ceux deja presents.
const MINE_DUREE := 300.0
const MINE_INTERVALLE_DEBUT := 1.40
const MINE_INTERVALLE_FIN := 0.45
const MINE_PLAFOND_DEBUT := 4
const MINE_PLAFOND_FIN := 14
const MINE_PV_MULT := 0.50
const MINE_DEGATS_MULT := 0.12
const MINE_MONTEE_PV := 2.0
const MINE_MONTEE_DEGATS := 1.0
const MINE_BOSS_PV_MULT := 1.50
const MINE_BOSS_DEGATS_MULT := 0.50
const MINE_SOIN_NIVEAU := 0.30
const MINE_CAMERA_ZOOM := 0.68

const DELAI_VAGUE_FORCE := 5.0
# Un invocateur qui produit plus vite qu'on ne tue rend la salle infinie : la
# sonde a bloque deux fois dessus. Le plafond est une regle de jeu, pas un
# pansement — il borne aussi ce que l'ecran doit rester capable d'afficher.
const PLAFOND_ENNEMIS := 10

# Le rythme des adversaires majeurs est regle ici pour que leurs telegraphes
# puissent etre ajustes ensemble sans fouiller le moteur de motifs.
const BOSS_APPARITION_DUREE := 0.85
const BOSS_TELEGRAPHE_SIGNATURE := 0.42
const BOSS_CADENCES_SIGNATURE := {
	"griffure": 0.58, "echo_errata": 0.72, "quadrillage": 0.68,
	"machoire": 0.76, "calligraphie": 0.15, "indexation": 0.48,
	"onde_marge": 0.74, "rosace": 0.88, "estampille": 0.82,
	"copie_double": 0.52,
}
const BOSS_DUREES_MOTIFS := {
	"barrage_horizontal": 3.0, "eventail_lent": 3.2, "barrage_croise": 3.4,
	"invocation": 1.2, "charge": 2.6, "spirale": 3.1, "anneau_breche": 3.2,
	"pluie": 3.0, "poursuite": 2.8, "griffure": 2.9, "echo_errata": 3.0,
	"quadrillage": 3.1, "machoire": 3.0, "calligraphie": 3.1, "indexation": 2.9,
	"onde_marge": 3.0, "rosace": 3.1, "estampille": 3.0, "copie_double": 3.0,
	"pause_phase_1": 1.8, "pause_phase_2": 1.4,
}

const PORTAIL_RAYON := 82.0

# Le prototype retro doit se laisser parcourir avant de juger son style. Il
# presente tout son bestiaire en une salle sans reprendre la courbe de campagne.
const RETRO_PV_MULT := 0.62
const RETRO_DEGATS_MULT := 0.48
