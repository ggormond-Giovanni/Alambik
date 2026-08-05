class_name Reglages
extends RefCounted

# Source unique de l'equilibrage. Aucune de ces valeurs ne doit reapparaitre
# en dur ailleurs : les regler ne doit jamais demander de relire le combat.
#
# Ecart assume par rapport au plan : classe globale de constantes plutot
# qu'autoload. Un autoload n'existe que dans une SceneTree ; les suites de
# tests headless doivent pouvoir lire l'equilibrage sans en monter une.

const HEROS_PV := 100.0
const HEROS_VITESSE := 420.0
const HEROS_CADENCE := 2.4          # tirs par seconde
const HEROS_INVULNERABILITE := 0.6  # secondes apres un coup recu
const HEROS_RAYON := 34.0

const TIR_DEGATS := 10.0
const TIR_VITESSE := 900.0
const TIR_PORTEE := 1400.0
const TIR_DELAI_ARRET := 0.12       # temps d'arret avant que le tir reprenne

const BRAISE_DEGATS_PAR_SECONDE := 6.0
const BRAISE_DUREE := 3.0
const GIVRE_RALENTISSEMENT := 0.45  # facteur de vitesse applique
const GIVRE_DUREE := 2.0
const ACIDE_VULNERABILITE := 1.35   # multiplicateur de degats subis
const ACIDE_DUREE := 4.0
const FOUDRE_PORTEE_CHAINE := 260.0
const FOUDRE_PART_DEGATS := 0.6     # la chaine frappe moins fort que l'impact
const FRAGMENT_PART_DEGATS := 0.45
const FRAGMENT_PORTEE := 260.0

const PAS_DE_CHAT_FACTEUR := 1.25
const FIOLE_PV := 40.0
const SILLAGE_INTERVALLE := 0.12
const SILLAGE_DUREE := 1.6
const SILLAGE_RAYON := 46.0
const FLAQUE_DUREE := 3.0
const FLAQUE_RAYON := 70.0
const NUAGE_DUREE := 3.5
const NUAGE_RAYON := 130.0
const GEL_BREF_DUREE := 0.7
const RAFALE_NOMBRE := 3
const RAFALE_INTERVALLE := 0.07
const BOUCLIER_EXPLOSION_RAYON := 260.0

const ARENE_MARGE_LATERALE := 40.0
const ARENE_HAUT := 260.0            # sous le HUD
const ARENE_BAS := 220.0             # au-dessus de la zone du pouce

const SALLES_PAR_RUN := 10
const SALLE_ALAMBIC_A := 5
const SALLE_ALAMBIC_B := 9
const SALLE_BOSS := 10

const DELAI_ENTRE_VAGUES := 0.7
# Un invocateur qui produit plus vite qu'on ne tue rend la salle infinie : la
# sonde a bloque deux fois dessus. Le plafond est une regle de jeu, pas un
# pansement — il borne aussi ce que l'ecran doit rester capable d'afficher.
const PLAFOND_ENNEMIS := 10
