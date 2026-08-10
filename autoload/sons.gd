extends Node

# Tout l'audio est synthetise au demarrage : aucun fichier venu d'ailleurs.
# Les effets restent courts et discrets ; trois couches musicales synchrones
# portent le menu, le combat et le boss sans couvrir les informations de jeu.

const TAUX := 22050
const TAUX_MUSIQUE := 11025
const VOIX := 8
const DUREE_FONDU := 2.2
const BUS_MUSIQUE := "Musique"
const BUS_EFFETS := "Effets"

var _banque := {}
var _voix: Array[AudioStreamPlayer] = []
var _prochaine := 0
var actif := true
var _musiques: Array[AudioStreamPlayer] = []
var _volumes_vises := PackedFloat32Array([-80.0, -80.0, -80.0])

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preparer_bus(BUS_MUSIQUE)
	_preparer_bus(BUS_EFFETS)
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
		lecteur.bus = BUS_EFFETS
		add_child(lecteur)
		_voix.append(lecteur)
	if actif:
		# Les trois couches ont exactement la meme longueur. Elles restent donc
		# synchrones pendant les fondus, sans rupture quand le combat s'intensifie.
		for ambiance in 3:
			var musique := AudioStreamPlayer.new()
			musique.bus = BUS_MUSIQUE
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
	_regler_musique(-80.0, -25.0, -80.0)

func musique_combat(intensite := 0.5) -> void:
	var niveau := clampf(intensite, 0.0, 1.0)
	# L'harmonie du menu reste audible sous la couche arcade : le lancement d'un
	# grimoire ressemble ainsi à une accélération du même thème, pas à un morceau
	# sans rapport qui commencerait brutalement.
	_regler_musique(-80.0, lerpf(-21.0, -13.5, niveau), -80.0)

func musique_boss() -> void:
	_regler_musique(-27.0, -22.0, -13.0)

func _regler_musique(ambiante: float, combat: float, boss: float) -> void:
	_volumes_vises = PackedFloat32Array([ambiante, combat, boss])

func _preparer_bus(nom: String) -> void:
	if AudioServer.get_bus_index(nom) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, nom)

func appliquer_reglages() -> void:
	_appliquer_volume_bus(BUS_MUSIQUE, ReglagesJoueur.volume_musique)
	_appliquer_volume_bus(BUS_EFFETS, ReglagesJoueur.volume_effets)

func _appliquer_volume_bus(nom: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(nom)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, volume <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.001)))

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

# Trois boucles originales. Le menu conserve sa respiration lente; le combat a
# sa propre grille rapide et sombre; le boss garde une couche lourde separee.
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
	# Le combat occupe exactement 24 temps a 144 BPM dans les dix secondes de
	# boucle. Six mesures donnent une vraie progression avant le retour en re.
	var accords_combat := [
		[50, 53, 57], [46, 50, 53], [48, 52, 55],
		[45, 49, 52], [43, 46, 50], [45, 49, 52],
	]
	var melodie_combat := [
		62, 69, 74, 72, 69, 65, 67, 69,
		70, 65, 62, 65, 70, 69, 65, 62,
		64, 67, 72, 71, 67, 64, 62, 60,
		61, 64, 69, 73, 69, 67, 64, 61,
		62, 67, 70, 74, 70, 67, 65, 62,
		61, 64, 69, 67, 64, 61, 57, -1,
	]
	var motif_basse_combat := [0, 12, 0, 7, 0, 12, 7, 12]
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
			var battement_combat := temps * 144.0 / 60.0
			var mesure_combat := int(battement_combat / 4.0) % accords_combat.size()
			var accord_combat: Array = accords_combat[mesure_combat]
			# Basse en doubles croches, avec octave et quinte : une poussee continue
			# sous le combat plutot qu'une basse ronde d'ambiance.
			var pas_basse := int(battement_combat * 4.0)
			var note_basse: int = accord_combat[0] - 12 + motif_basse_combat[pas_basse % motif_basse_combat.size()]
			var phase_basse := fmod(battement_combat * 4.0, 1.0)
			var enveloppe_basse := pow(1.0 - phase_basse, 2.2)
			var fondamentale_basse := sin(TAU * _frequence(note_basse) * temps)
			var grave := sin(TAU * _frequence(note_basse - 12) * temps) * 0.38
			valeur_g += (fondamentale_basse + grave) * enveloppe_basse * 0.17
			valeur_d += (fondamentale_basse + grave) * enveloppe_basse * 0.17
			# Arpege sombre a seize pas, panoramique en mouvement. Il remplit l'espace
			# sans transformer le lead en petite comptine.
			var pas_arp_combat := int(battement_combat * 4.0)
			var note_arp_combat: int = accord_combat[pas_arp_combat % 3] + 12
			var phase_arp := fmod(battement_combat * 4.0, 1.0)
			var enveloppe_arp_combat := pow(1.0 - phase_arp, 3.0)
			var arp_combat := sin(TAU * _frequence(note_arp_combat) * temps) * enveloppe_arp_combat * 0.045
			valeur_g += arp_combat * (0.9 if pas_arp_combat % 2 == 0 else 0.35)
			valeur_d += arp_combat * (0.35 if pas_arp_combat % 2 == 0 else 0.9)
			# Accords graves sur les contretemps pour une sensation de marche heroique.
			var contretemps := fmod(battement_combat + 0.5, 1.0)
			var enveloppe_accord := pow(1.0 - contretemps, 5.0)
			for n in accord_combat:
				var phase_accord := TAU * _frequence(float(n)) * temps
				var frappe := (sin(phase_accord) * 0.7 + (1.0 if sin(phase_accord) >= 0.0 else -1.0) * 0.3) \
					* enveloppe_accord * 0.035
				valeur_g += frappe
				valeur_d += frappe * 0.94
			# Phrase principale en croches : elle monte, retombe, puis laisse la
			# dominante tendue ramener naturellement au debut de la boucle.
			var pas := int(battement_combat * 2.0) % melodie_combat.size()
			var hauteur: int = melodie_combat[pas]
			if hauteur >= 0:
				var phase_note := fmod(battement_combat * 2.0, 1.0)
				var enveloppe := pow(1.0 - phase_note, 0.72)
				var phase_lead := TAU * _frequence(hauteur) * temps
				var pulse := 1.0 if sin(phase_lead) >= 0.0 else -1.0
				var note := (pulse * 0.55 + sin(phase_lead) * 0.45) * enveloppe * 0.095
				valeur_g += note * 0.82
				valeur_d += note * 0.76
			var percussion := _percussion(temps, battement_combat, false) * 1.18
			valeur_g += percussion
			valeur_d += percussion * 0.94
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
	var charley := bruit * pow(1.0 - demi, 18.0) * (0.055 if lourde else 0.048)
	# Claquement sur les deuxième et quatrième temps pour rendre la grille
	# immédiatement lisible au milieu des tirs.
	var dans_mesure := fmod(battement, 4.0)
	var distance_clap := minf(absf(dans_mesure - 1.0), absf(dans_mesure - 3.0))
	var clap := 0.0
	if distance_clap < 0.18:
		clap = bruit * pow(1.0 - distance_clap / 0.18, 3.0) * (0.08 if lourde else 0.065)
	return coup + charley + clap

func _frequence(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)

func _ecrire_stereo(donnees: PackedByteArray, index: int, gauche: float, droite: float) -> void:
	donnees.encode_s16(index * 4, int(clampf(gauche, -0.95, 0.95) * 32767.0))
	donnees.encode_s16(index * 4 + 2, int(clampf(droite, -0.95, 0.95) * 32767.0))
