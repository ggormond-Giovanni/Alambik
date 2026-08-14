class_name RaccourciTactile
extends RefCounted

# Reconnait une tape rapide dans la zone de deplacement, pour lancer le Sort
# actif sans viser son icone.
#
# Un pouce qui pilote le heros reste pose et parcourt de la distance ; une tape
# volontaire est breve et quasi immobile. Sans ces deux bornes, chaque
# micro-correction de trajectoire declencherait le Sort au milieu d'un combat.
# Le temps est fourni par l'appelant : la detection reste ainsi verifiable en
# headless, sans horloge ni arbre de scene.

const MODES := ["icone", "tape", "double_tape"]
const MODE_DEFAUT := "icone"
const DUREE_MAX := 0.22       # secondes entre l'appui et le relachement
const DISTANCE_MAX := 34.0    # pixels parcourus pendant la tape
const DELAI_ENTRE_TAPES := 0.32

var _pose := false
var _debut := 0.0
var _precedente := Vector2.ZERO
var _distance := 0.0
var _derniere_tape := -1000.0
var _tapes := 0

static func mode_valide(mode: String) -> String:
	return mode if mode in MODES else MODE_DEFAUT

static func nom_mode(mode: String) -> String:
	match mode_valide(mode):
		"tape": return "TAPE RAPIDE"
		"double_tape": return "DOUBLE TAPE RAPIDE"
	return "ICÔNE SEULEMENT"

# Nombre de tapes qu'un mode demande avant de lancer le Sort. Zero signifie que
# seule l'icone du HUD declenche.
static func tapes_requises(mode: String) -> int:
	match mode_valide(mode):
		"tape": return 1
		"double_tape": return 2
	return 0

func appuyer(position: Vector2, temps: float) -> void:
	_pose = true
	_debut = temps
	_precedente = position
	_distance = 0.0

func deplacer(position: Vector2) -> void:
	if not _pose:
		return
	_distance += _precedente.distance_to(position)
	_precedente = position

# Renvoie le nombre de tapes rapides enchainees, ou zero si le geste relache
# n'en est pas une. Une tape lente ou baladeuse casse aussi la serie en cours :
# un deplacement franc ne doit jamais completer un double appui commence avant.
func relacher(temps: float) -> int:
	if not _pose:
		return 0
	_pose = false
	if temps - _debut > DUREE_MAX or _distance > DISTANCE_MAX:
		_tapes = 0
		return 0
	_tapes = _tapes + 1 if temps - _derniere_tape <= DELAI_ENTRE_TAPES else 1
	_derniere_tape = temps
	return _tapes

func annuler() -> void:
	_pose = false
	_tapes = 0

# Appele quand le Sort vient de partir : la serie repart de zero pour que la
# tape suivante ne complete pas un double appui deja consomme.
func consommer() -> void:
	_tapes = 0
	_derniere_tape = -1000.0
