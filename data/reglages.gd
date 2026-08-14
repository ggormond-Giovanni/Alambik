class_name Reglages
extends RefCounted

# Source unique de l'equilibrage. Aucune de ces valeurs ne doit reapparaitre
# en dur ailleurs : les regler ne doit jamais demander de relire le combat.
#
# Ecart assume par rapport au plan : classe globale de constantes plutot
# qu'autoload. Un autoload n'existe que dans une SceneTree ; les suites de
# tests headless doivent pouvoir lire l'equilibrage sans en monter une.

# Le niveau de compte porte les statistiques de base du heros. Tout le reste —
# Maitrises, equipement, Passifs — multiplie ce socle. Le niveau ne donnait
# auparavant aucune statistique : monter de niveau ne changeait rien au combat.
const NIVEAU_DEGATS_PAR_NIVEAU := 0.025
const NIVEAU_PV_PAR_NIVEAU := 0.035
const NIVEAU_CADENCE_PAR_NIVEAU := 0.005
# Niveau de compte servant de reference aux mesures d'equilibrage : c'est
# l'ordre de grandeur atteint par un compte qui a termine la campagne.
const NIVEAU_REFERENCE_FIN := 30

const HEROS_PV := 100.0
const HEROS_VITESSE := 560.0
const HEROS_ACCELERATION := 3100.0
const HEROS_FREINAGE := 4200.0
const HEROS_CADENCE := 2.4          # tirs par seconde
const HEROS_INVULNERABILITE := 0.6  # secondes apres un coup recu
const HEROS_RAYON := 24.0
const ENNEMI_VITESSE_MULT := 1.10
const ENNEMI_HITBOX_MULT := 0.72
const BOSS_HITBOX_MULT := 0.74

const TIR_DEGATS := 10.0
# Mesure : la creature la plus rapide file a 704 px/s. A 900, le projectile
# n'allait qu'a 1,28 fois sa vitesse et se faisait esquiver systematiquement ;
# un tir doit devancer sa cible d'un facteur deux au minimum.
const TIR_VITESSE := 1550.0
const TIR_RAYON := 10.0
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
# Le familier tire depuis ce decalage, pas depuis le heros. Sa visee doit donc
# partir de la aussi : calculee depuis le heros, elle ratait de tout l'angle
# separant les deux points, d'autant plus visiblement que la cible etait proche.
const FAMILIER_DECALAGE := Vector2(72.0, -36.0)

# Viser ou la cible sera, pas ou elle est. Partage par le heros et le familier :
# une cible qui recule en ligne droite n'etait presque jamais touchee.
const ANTICIPATION_DUREE_MAX := 0.8
const ANTICIPATION_PART := 0.9
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

# Ameliorations ajoutees au pool. Leurs valeurs pures vivent dans le catalogue ;
# seules celles que la logique doit lire sont ici.
const PEAU_DE_PIERRE_REDUCTION := 0.24
const SOIF_DE_SANG_PART := 0.012      # part des PV max rendue par elimination
const CHAINE_INTERVALLE := 1.6
const CHAINE_PART_DEGATS := 0.52
const CHAINE_CIBLES := 4
const CHAINE_PORTEE := 340.0          # distance maximale entre deux maillons

# Passifs. On n'en equipe qu'un, deux avec la Maitrise Utilitaire : un Passif
# doit donc changer une facon de jouer, pas ajouter un pourcentage anecdotique.
# Chacun porte en plus un effet permanent, faute de quoi la moitie d'entre eux
# ne se remarquait jamais en combat.
const MOISSON_SEUIL := 6
const MOISSON_PART := 0.12
const SANG_FROID_SEUIL := 8
const SANG_FROID_RECHARGE := 0.30      # recharge du Sort en moins, en permanence
const REMPART_REDUCTION := 0.18        # degats recus en moins, en permanence
const RIPOSTE_RAYON := 320.0
const RIPOSTE_PART_DEGATS := 2.80
const RIPOSTE_REPOUSSEE := 420.0
const SECONDE_CHANCE_PART := 0.50      # une fois par salle, plus par grimoire
const RESERVE_ULTIME_CHARGES := 8
const RESERVE_ULTIME_REMISE := 0.20    # charge requise en moins
const HERITAGE_AMELIORATIONS := 2
const ECHO_CHANCE := 0.40
const ECHO_PART_DEGATS := 0.70
const AUDACE_SEUIL_PV := 0.60
const AUDACE_BONUS := 0.45
const DERNIER_REMPART_SEUIL_PV := 0.40
const DERNIER_REMPART_REDUCTION := 0.45

# Equipement. Un objet ne vaut plus seulement ses niveaux de Forge : il porte un
# profil propre a son emplacement, multiplie par le Monde dont il provient. Sans
# cette croissance, un anneau du Monde I valait un anneau du Monde X et rien ne
# poussait a chercher les objets tardifs.
const OBJET_CROISSANCE_PAR_MONDE := 1.30

# Sceaux. L'aura ne fait aucun degat : elle marque, ce qui la rend lisible face
# aux Phenomenes qui, eux, frappent.
const SCEAU_GARDE_REDUCTION := 0.22
const SCEAU_RUINE_VULNERABILITE := 1.30
const SCEAU_AURA_INTERVALLE := 0.55
const SCEAU_AURA_RAYON := 240.0
const SCEAU_AURA_RAYON_AIR_MULT := 1.85
const SCEAU_AURA_SOIN := 0.004      # part des PV max par creature marquee, Lumiere
const SCEAU_AURA_DEGATS := 0.02     # trace symbolique : l'aura marque, elle ne tue pas

const ONDE_CHOC_INTERVALLE := 3.2
const ONDE_CHOC_RAYON := 300.0
const ONDE_CHOC_PART_DEGATS := 1.15
const ONDE_CHOC_REPOUSSEE := 300.0

# Elan vital : l'inverse de Mannequin, il recompense le deplacement.
const ELAN_VITAL_DEGATS_MULT := 1.45
const ELAN_VITAL_DUREE := 1.1       # secondes de bonus apres s'etre deplace

const FLAQUE_DUREE := 3.0
const FLAQUE_RAYON := 70.0
const NUAGE_DUREE := 3.5
const NUAGE_RAYON := 130.0
const GEL_BREF_DUREE := 0.7
const RAFALE_NOMBRE := 2
const RAFALE_INTERVALLE := 0.07

# La zone praticable suit le bord interieur de la peinture. L'ancienne limite
# englobait les remparts : les personnages semblaient traverser la pierre.
const ARENE_MARGE_LATERALE := 78.0
const ARENE_HAUT := 244.0
const ARENE_BAS := 220.0
const ARENE_MUR_EPAISSEUR := 72.0
const ARENE_HAUTEUR_MAX := 1540.0
const ECHELLE_VISUELLE_COMBAT := 1.08

# La longueur d'un chapitre et la place de ses alambics vivent dans
# data/chapitres.gd : ces constantes ne servent plus qu'au repli, quand aucun
# chapitre n'est charge.
const SALLES_PAR_RUN := 20

# Difficulte de campagne. Elle ne vit plus dans une table de dix Mondes mais
# dans une progression continue par palier, un palier valant un chapitre. Un
# Monde qui s'ouvrait sur une marche de +50 % franchie en une salle devient une
# montee lissee sur ses trois chapitres, et la formule reste definie au-dela du
# trentieme palier : ajouter des Mondes ne demande plus de recalculer la table.
const COURBE_PV_PAR_PALIER := 1.132      # x1.45 par Monde une fois ses trois chapitres franchis
# Les degats montent bien moins vite que les PV : un ennemi de fin de campagne
# doit rester encaissable deux ou trois fois, sinon toute la defense se resume a
# ne jamais etre touche.
const COURBE_DEGATS_PAR_PALIER := 1.060  # x1.19 par Monde
# Les premiers paliers sont adoucis puis rejoignent la courbe. Un compte neuf
# n'a ni Maitrise ni objet : mesure faite, il mourait salle 3 du premier
# chapitre, donc sans jamais atteindre le premier coffre de la salle 5. Une
# campagne qui ne finance pas sa propre progression n'a pas de premiere heure.
const COURBE_DOUCEUR_DEBUT := 0.62
const COURBE_PALIERS_DOUCEUR := 6   # deux Mondes pour rejoindre la courbe pleine

# Montee en puissance sur la longueur d'un chapitre. Vingt salles a difficulte
# plate seraient vingt fois la meme salle.
# Facteurs atteints a la derniere salle d'un chapitre : les PV sont multiplies
# par 1 + MONTEE_PV, les degats par 1 + MONTEE_DEGATS, suivant une courbe
# geometrique. Cales sur la puissance mesuree du heros au meme endroit.
const MONTEE_PV := 2.6
const MONTEE_DEGATS := 0.75
const DEFI_MONTEE_PV := 3.0       # x4 entre la premiere et la derniere rencontre
const DEFI_MONTEE_DEGATS := 1.0   # x2 sur les degats, en plus de la densite
const DEFI_PV_BASE := 1.25
const DEFI_DEGATS_BASE := 1.15

# Un Amélioration se reprend, mais pas indefiniment : six choix doivent construire
# un build, pas empiler automatiquement la meme carte.
const COPIES_MAX := 3
const SOIN_ALAMBIC := 0.20   # respiration garantie avant chaque boss

# Seuils provisoires d'XP de run. Ils visent la courbe 2/4/5/6 avant les salles
# 5/10/15/20 et doivent etre recalibres avec les rencontres definitives.
const XP_RUN_SEUILS := [9, 25, 50, 78, 130, 195]

# Economie longue : le premier rang des trente Maitrises accompagne les trente
# chapitres, les rangs suivants sont la matiere du farm. Les couts sont partages
# par les trois branches pour rester lisibles.
const MAITRISE_COUTS := [60, 100, 170, 280, 460, 760, 1250, 2050, 3400, 5600]
const MAITRISE_RANG_MAX := 5
# Un rang supplementaire coute nettement plus que le precedent : sans cela, la
# fin de campagne achete l'arbre entier en deux descentes.
const MAITRISE_COUT_PAR_RANG := 1.85
const GOUTTES_MULT_PAR_CHAPITRE := 1.11

# Capacites d'Epreuve : obtenir reste le gros deblocage, les neuf exemplaires
# suivants doublent la capacite sans jamais la rendre auto-suffisante.
const CAPACITE_RANG_MAX := 10
const CAPACITE_BONUS_PAR_RANG := 0.12

# La Forge appartient a l'objet. Son cout croit geometriquement pour que les
# derniers niveaux restent un objectif de farm et non une formalite.
# La Forge multiplie le profil de l'objet : un seul facteur, quel que soit le
# champ, sinon deux constantes devraient rester egales sans que rien ne le dise.
const FORGE_BONUS_PAR_NIVEAU := 0.015
const FORGE_NIVEAU_MAX := 60
const FORGE_COUT_BASE := 8
const FORGE_COUT_CROISSANCE := 1.055
const MINE_PIERRES_RECOMPENSE := 25
# La Mine doit rester la source de Pierres apres le dernier Monde : sa
# recompense suit le palier atteint, comme les Gouttes suivent le chapitre.
const MINE_PIERRES_MULT_PAR_PALIER := 1.09

static func cout_maitrise(cout_base: int, rang_acquis: int) -> int:
	return maxi(1, roundi(float(cout_base) * pow(MAITRISE_COUT_PAR_RANG, float(rang_acquis))))

static func cout_forge(niveau_acquis: int) -> int:
	return maxi(1, roundi(float(FORGE_COUT_BASE) * pow(FORGE_COUT_CROISSANCE, float(niveau_acquis))))

static func pierres_mine(palier: int) -> int:
	return maxi(1, roundi(float(MINE_PIERRES_RECOMPENSE) \
		* pow(MINE_PIERRES_MULT_PAR_PALIER, float(maxi(0, palier)))))
# La Mine est une survie complete : peu de pression au depart, une horde qui
# monte pendant cinq minutes, puis un boss. Les multiplicateurs s'appliquent
# progressivement aux ennemis apparus, pas retroactivement a ceux deja presents.
const MINE_DUREE := 300.0
const MINE_INTERVALLE_DEBUT := 1.40
const MINE_INTERVALLE_FIN := 0.45
const MINE_PLAFOND_DEBUT := 4
const MINE_PLAFOND_FIN := 14
const MINE_PV_MULT := 0.75
const MINE_DEGATS_MULT := 0.30
const MINE_MONTEE_PV := 2.0
const MINE_MONTEE_DEGATS := 1.0
const MINE_BOSS_PV_MULT := 2.00
const MINE_BOSS_DEGATS_MULT := 0.80
const MINE_SOIN_NIVEAU := 0.30
const MINE_CAMERA_ZOOM := 0.74

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
