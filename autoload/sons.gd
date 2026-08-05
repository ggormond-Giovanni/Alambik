extends Node

# Les sons sont synthetises au demarrage : aucun fichier audio dans le depot,
# donc rien qui vienne d'ailleurs, et rien a charger. Ce sont des enveloppes
# courtes, volontairement discretes : le tir part plusieurs fois par seconde.

const TAUX := 22050
const VOIX := 8

var _banque := {}
var _voix: Array[AudioStreamPlayer] = []
var _prochaine := 0
var actif := true

func _ready() -> void:
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		actif = false
	_banque["tir"] = _souffle(0.07, 900.0, 420.0, 0.35, 0.25)
	_banque["impact"] = _souffle(0.09, 320.0, 140.0, 0.6, 0.4)
	_banque["mort"] = _souffle(0.22, 240.0, 60.0, 0.8, 0.55)
	_banque["degat"] = _souffle(0.25, 180.0, 70.0, 0.5, 0.7)
	_banque["choix"] = _souffle(0.12, 620.0, 900.0, 0.15, 0.45)
	_banque["fusion"] = _souffle(0.55, 300.0, 1100.0, 0.2, 0.6)
	_banque["porte"] = _souffle(0.35, 420.0, 620.0, 0.25, 0.5)
	_banque["boss"] = _souffle(0.7, 140.0, 70.0, 0.7, 0.7)
	for i in VOIX:
		var lecteur := AudioStreamPlayer.new()
		lecteur.bus = "Master"
		add_child(lecteur)
		_voix.append(lecteur)

func jouer(nom: String, volume_db := -12.0, hauteur := 1.0) -> void:
	if not actif or not _banque.has(nom):
		return
	var lecteur := _voix[_prochaine]
	_prochaine = (_prochaine + 1) % VOIX
	lecteur.stream = _banque[nom]
	lecteur.volume_db = volume_db
	lecteur.pitch_scale = hauteur
	lecteur.play()

# Un balayage de frequence melange a du bruit, sous une enveloppe qui decroit :
# assez pour distinguer un tir d'un impact sans sortir la boite a rythmes.
func _souffle(duree: float, f_debut: float, f_fin: float, part_bruit: float, courbe: float) -> AudioStreamWAV:
	var echantillons := int(duree * TAUX)
	var donnees := PackedByteArray()
	donnees.resize(echantillons * 2)
	var phase := 0.0
	var alea := RandomNumberGenerator.new()
	alea.seed = int(f_debut * 1000.0 + duree * 7919.0)
	for i in echantillons:
		var t := float(i) / float(echantillons)
		var frequence := lerpf(f_debut, f_fin, t)
		phase += TAU * frequence / float(TAUX)
		var onde := sin(phase)
		var bruit := alea.randf_range(-1.0, 1.0)
		var enveloppe := pow(1.0 - t, 1.0 + courbe * 6.0)
		var valeur := lerpf(onde, bruit, part_bruit) * enveloppe * 0.7
		var entier := int(clampf(valeur, -1.0, 1.0) * 32000.0)
		donnees.encode_s16(i * 2, entier)
	var flux := AudioStreamWAV.new()
	flux.format = AudioStreamWAV.FORMAT_16_BITS
	flux.mix_rate = TAUX
	flux.stereo = false
	flux.data = donnees
	return flux
