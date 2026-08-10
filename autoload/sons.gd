extends Node

# Tout l'audio est synthetise au demarrage : aucun fichier venu d'ailleurs.
# Les effets restent courts et discrets ; trois couches musicales synchrones
# portent le menu, le combat et le boss sans couvrir les informations de jeu.

const TAUX := 22050
const TAUX_MUSIQUE := 11025
const VOIX := 8
const DUREE_FONDU := 1.8

var _banque := {}
var _voix: Array[AudioStreamPlayer] = []
var _prochaine := 0
var actif := true
var _musiques: Array[AudioStreamPlayer] = []
var _volumes_vises := PackedFloat32Array([-80.0, -80.0, -80.0])

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	if actif:
		# Les trois couches ont exactement la meme longueur. Elles restent donc
		# synchrones pendant les fondus, sans rupture quand le combat s'intensifie.
		for ambiance in 3:
			var musique := AudioStreamPlayer.new()
			musique.bus = "Master"
			musique.stream = _composer_boucle(ambiance)
			musique.volume_db = -80.0
			add_child(musique)
			_musiques.append(musique)
		# Demarrer apres la synthese garde les trois pistes alignees a l'echantillon.
		for musique in _musiques:
			musique.play()
		musique_menu()

func _process(delta: float) -> void:
	for i in _musiques.size():
		_musiques[i].volume_db = move_toward(_musiques[i].volume_db, _volumes_vises[i],
			80.0 * delta / DUREE_FONDU)

func musique_menu() -> void:
	_regler_musique(-17.0, -80.0, -80.0)

func musique_calme() -> void:
	_regler_musique(-22.0, -80.0, -80.0)

func musique_combat(intensite := 0.5) -> void:
	var niveau := clampf(intensite, 0.0, 1.0)
	_regler_musique(-24.0, lerpf(-24.0, -15.0, niveau), -80.0)

func musique_boss() -> void:
	_regler_musique(-27.0, -22.0, -13.0)

func _regler_musique(ambiante: float, combat: float, boss: float) -> void:
	_volumes_vises = PackedFloat32Array([ambiante, combat, boss])

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

# Une boucle originale en re mineur, construite note par note. L'ambiance porte
# l'harmonie, le combat ajoute pulsation et percussions, le boss une basse plus
# sombre. Les motifs partagent la meme grille pour permettre les fondus.
func _composer_boucle(couche: int) -> AudioStreamWAV:
	var tempo := 96.0
	var battements := 16.0
	var duree := battements * 60.0 / tempo
	var echantillons := int(duree * TAUX_MUSIQUE)
	var donnees := PackedByteArray()
	donnees.resize(echantillons * 4)
	var accords := [
		[50, 53, 57], [46, 50, 53], [53, 57, 60], [48, 52, 55],
	]
	var melodie := [62, 65, 69, 65, 60, 65, 69, 72, 57, 60, 65, 60, 55, 60, 64, 67]
	for i in echantillons:
		var temps := float(i) / float(TAUX_MUSIQUE)
		var battement := temps * tempo / 60.0
		var index_accord := int(battement / 4.0) % accords.size()
		var accord: Array = accords[index_accord]
		var local := fmod(battement, 1.0)
		var valeur_g := 0.0
		var valeur_d := 0.0
		if couche == 0:
			# Un pad doux et legerement desaccorde evite le timbre de bip pur.
			for n in accord:
				var frequence := _frequence(float(n))
				valeur_g += sin(TAU * frequence * temps) * 0.055
				valeur_d += sin(TAU * frequence * 1.003 * temps + 0.35) * 0.055
			var pas_arp := int(battement * 2.0)
			var note_arp: int = accord[pas_arp % 3] + 12
			var enveloppe_arp := pow(1.0 - fmod(battement * 2.0, 1.0), 3.0)
			var arp := sin(TAU * _frequence(note_arp) * temps) * enveloppe_arp * 0.10
			valeur_g += arp * (0.75 if pas_arp % 2 == 0 else 0.35)
			valeur_d += arp * (0.35 if pas_arp % 2 == 0 else 0.75)
			# Une note haute et lente fait respirer l'ambiance au-dessus de l'arpege.
			var phrase := fmod(battement, 4.0)
			var enveloppe_air := pow(sin(PI * clampf(phrase / 4.0, 0.0, 1.0)), 2.0)
			var note_air: int = accord[2] + 24
			var air := sin(TAU * _frequence(note_air) * temps + 0.6) * enveloppe_air * 0.035
			valeur_g += air * 0.55
			valeur_d += air
		elif couche == 1:
			var basse: int = accord[0] - 12
			var enveloppe_basse := pow(1.0 - local, 2.2)
			var onde_basse := sin(TAU * _frequence(basse) * temps)
			valeur_g += onde_basse * enveloppe_basse * 0.22
			valeur_d += onde_basse * enveloppe_basse * 0.22
			var pas := int(battement * 2.0) % melodie.size()
			var enveloppe := pow(1.0 - fmod(battement * 2.0, 1.0), 4.0)
			var note := sin(TAU * _frequence(melodie[pas]) * temps) * enveloppe * 0.12
			valeur_g += note * (0.85 if pas % 4 < 2 else 0.45)
			valeur_d += note * (0.45 if pas % 4 < 2 else 0.85)
			var percussion := _percussion(temps, battement, false)
			valeur_g += percussion
			valeur_d += percussion * 0.92
		else:
			var fondamentale: int = accord[0] - 24
			var basse_lourde := sin(TAU * _frequence(fondamentale) * temps)
			basse_lourde += sin(TAU * _frequence(fondamentale) * 2.0 * temps) * 0.35
			var pompe := pow(1.0 - fmod(battement * 2.0, 1.0), 2.5)
			valeur_g += basse_lourde * pompe * 0.22
			valeur_d += basse_lourde * pompe * 0.22
			var percussion_boss := _percussion(temps, battement, true)
			valeur_g += percussion_boss
			valeur_d += percussion_boss
		var fondu_bord := minf(1.0, minf(temps * 30.0, (duree - temps) * 30.0))
		_ecrire_stereo(donnees, i, valeur_g * fondu_bord, valeur_d * fondu_bord)
	var flux := AudioStreamWAV.new()
	flux.format = AudioStreamWAV.FORMAT_16_BITS
	flux.mix_rate = TAUX_MUSIQUE
	flux.stereo = true
	flux.loop_mode = AudioStreamWAV.LOOP_FORWARD
	flux.loop_begin = 0
	flux.loop_end = echantillons
	flux.data = donnees
	return flux

func _percussion(temps: float, battement: float, lourde: bool) -> float:
	var phase := fmod(battement, 1.0)
	var coup := sin(TAU * lerpf(72.0 if lourde else 92.0, 42.0, phase) * temps)
	coup *= pow(1.0 - phase, 8.0) * (0.28 if lourde else 0.18)
	var demi := fmod(battement * 2.0, 1.0)
	var bruit := sin(float(int(temps * 17011.0) % 97) * 12.9898)
	var charley := bruit * pow(1.0 - demi, 18.0) * (0.055 if lourde else 0.035)
	return coup + charley

func _frequence(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)

func _ecrire_stereo(donnees: PackedByteArray, index: int, gauche: float, droite: float) -> void:
	donnees.encode_s16(index * 4, int(clampf(gauche, -0.95, 0.95) * 32767.0))
	donnees.encode_s16(index * 4 + 2, int(clampf(droite, -0.95, 0.95) * 32767.0))
