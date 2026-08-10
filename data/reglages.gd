class_name Reglages
extends RefCounted

# Source unique de l'equilibrage. Aucune de ces valeurs ne doit reapparaitre
# en dur ailleurs : les regler ne doit jamais demander de relire le combat.
#
# Ecart assume par rapport au plan : classe globale de constantes plutot
# qu'autoload. Un autoload n'existe que dans une SceneTree ; les suites de
# tests headless doivent pouvoir lire l'equilibrage sans en monter une.

const HEROS_PV := 100.0
const HEROS_VITESSE := 500.0
const HEROS_ACCELERATION := 3100.0
const HEROS_FREINAGE := 4200.0
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
# Un eclat qui frappe presque aussi fort que le tir d'origine transforme
# Eclat de verre en multiplicateur : c'etait la moitie des mains cassees.
const FRAGMENT_PART_DEGATS := 0.28
const FRAGMENT_PORTEE := 260.0
# Un trait qui traverse quatre ennemis en frappant chacun a pleine puissance
# est un multiplicateur deguise : il perd de la force a chaque cible, et a
# chaque rebond. C'est ce qui separe une bonne main d'une main cassee.
const PERFORATION_PERTE := 0.35
const REBOND_PERTE := 0.25

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

const ARENE_MARGE_LATERALE := 32.0
const ARENE_HAUT := 240.0            # sous le HUD
const ARENE_BAS := 160.0             # garde la zone principale du pouce libre

# La longueur d'un chapitre et la place de ses alambics vivent dans
# data/chapitres.gd : ces constantes ne servent plus qu'au repli, quand aucun
# chapitre n'est charge.
const SALLES_PAR_RUN := 50

# Montee en puissance sur la longueur d'un chapitre. Cinquante pages a
# difficulte plate seraient cinquante fois la meme page.
# Facteurs atteints a la derniere page d'un chapitre : les PV sont multiplies
# par 1 + MONTEE_PV, les degats par 1 + MONTEE_DEGATS, suivant une courbe
# geometrique. Cales sur la puissance mesuree du heros au meme endroit.
const MONTEE_PV := 15.0
const MONTEE_DEGATS := 1.00
const MI_BOSS_PART_PV := 0.45

# Un reactif se reprend, mais pas indefiniment : sans plafond, une descente de
# cinquante pages se termine en empilant quinze fois le meme.
# Une recompense a chaque page rendait chaque draft insignifiant et le heros
# intouchable des la page 30 : une page sur deux, et le choix reprend du poids.
const COPIES_MAX := 3
const SOIN_REPOS := 0.30     # part des PV max rendue par une page de repos
const SOIN_ALAMBIC := 0.20   # respiration garantie deux fois par chapitre

# Les augments suivent le niveau du heros, pas les portes franchies. Le cout
# croissant donne beaucoup de choix au debut puis espace progressivement les
# evolutions, comme la courbe d'une run d'action.
const EXPERIENCE_PREMIER_NIVEAU := 10
const EXPERIENCE_PAR_NIVEAU := 12

const DELAI_ENTRE_VAGUES := 0.7
# Un invocateur qui produit plus vite qu'on ne tue rend la salle infinie : la
# sonde a bloque deux fois dessus. Le plafond est une regle de jeu, pas un
# pansement — il borne aussi ce que l'ecran doit rester capable d'afficher.
const PLAFOND_ENNEMIS := 10
