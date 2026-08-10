extends Node

# Les effets et le menu restent synthetises au demarrage. Toute la run, boss et
# transitions compris, joue la composition exportee depuis LMMS.

const TAUX := 22050
const TAUX_MUSIQUE := 11025
const VOIX := 8
const DUREE_FONDU := 2.2
const DUREE_BLANC_COMBAT := 0.14
const BUS_MUSIQUE := "Musique"
const BUS_EFFETS := "Effets"
const MUSIQUE_COMBAT := preload("res://assets/audio/firstarcade.ogg")

var _banque := {}
var _voix: Array[AudioStreamPlayer] = []
var _prochaine := 0
var actif := true
var _musiques: Array[AudioStreamPlayer] = []
var _volumes_vises := PackedFloat32Array([-80.0, -80.0])

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preparer_bus(BUS_MUSIQUE)
	_preparer_bus(BUS_EFFETS)
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		actif = false
	_banque["tir"] = _souffle(0.07, 900.0, 420.0, 0.35, 0.25)
	_banque["impact"] = _souffle(0.09, 320.0, 140.0, 0.6, 0.4)
	_banque["mort"] = _souffle(0.22, 240.0, 60.0, 0.8, 0.55)
	# Un choc court, grave et granuleux : lisible au haut-parleur d'un téléphone
	# sans couvrir la musique ni ressembler au petit impact des projectiles.
	_banque["degat"] = _impact_heros()
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
		# Une copie locale active la boucle sans modifier la ressource importee.
		for ambiance in 2:
			var musique := AudioStreamPlayer.new()
			musique.bus = BUS_MUSIQUE
			if ambiance == 1:
				var piste_combat: AudioStreamOggVorbis = MUSIQUE_COMBAT.duplicate()
				piste_combat.loop = true
				musique.stream = piste_combat
			else:
				musique.stream = _composer_boucle_menu()
			musique.volume_db = -80.0
			add_child(musique)
			_musiques.append(musique)
		# Tout demarrer une fois permet ensuite des fondus sans latence de lecture.
		for musique in _musiques:
			musique.play()
		musique_menu()

func _process(delta: float) -> void:
	for i in _musiques.size():
		_musiques[i].volume_db = move_toward(_musiques[i].volume_db, _volumes_vises[i],
			80.0 * delta / DUREE_FONDU)

func musique_menu() -> void:
	_regler_musique(-8.0, -80.0)

func musique_calme() -> void:
	# Une pause ne baisse ni ne rembobine la piste : elle suspend seulement le jeu.
	var volume_combat := _volumes_vises[1] if _volumes_vises.size() > 1 else -13.0
	_regler_musique(-80.0, volume_combat)

func musique_combat(intensite := 0.5) -> void:
	var niveau := clampf(intensite, 0.0, 1.0)
	_regler_musique(-80.0, lerpf(-13.0, -8.0, niveau))

func musique_boss() -> void:
	_regler_musique(-80.0, -8.0)

func demarrer_musique_combat() -> void:
	if not actif or _musiques.size() < 2:
		return
	# Couper avant de rembobiner rend l'attaque composee dans LMMS intacte.
	_regler_musique(-80.0, -80.0)
	for musique in _musiques:
		musique.volume_db = -80.0
	_musiques[1].stop()
	await get_tree().create_timer(DUREE_BLANC_COMBAT).timeout
	if _musiques.size() < 2:
		return
	_musiques[1].play(0.0)
	_musiques[1].volume_db = -12.0
	_regler_musique(-80.0, -12.0)

func _regler_musique(ambiante: float, combat: float) -> void:
	_volumes_vises = PackedFloat32Array([ambiante, combat])

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

func _impact_heros() -> AudioStreamWAV:
	var duree := 0.14
	var echantillons := int(duree * TAUX)
	var donnees := PackedByteArray()
	donnees.resize(echantillons * 2)
	var phase_grave := 0.0
	var phase_clic := 0.0
	var alea := RandomNumberGenerator.new()
	alea.seed = 17011996
	for i in echantillons:
		var t := float(i) / float(echantillons)
		phase_grave += TAU * lerpf(210.0, 72.0, t) / float(TAUX)
		phase_clic += TAU * lerpf(980.0, 360.0, t) / float(TAUX)
		var choc := sin(phase_grave) * pow(1.0 - t, 3.2)
		var clic := sin(phase_clic) * pow(1.0 - t, 10.0) * 0.30
		var grain := alea.randf_range(-1.0, 1.0) * pow(1.0 - t, 8.0) * 0.42
		var valeur := clampf(choc * 0.72 + clic + grain, -0.95, 0.95)
		donnees.encode_s16(i * 2, int(valeur * 32767.0))
	var flux := AudioStreamWAV.new()
	flux.format = AudioStreamWAV.FORMAT_16_BITS
	flux.mix_rate = TAUX
	flux.stereo = false
	flux.data = donnees
	return flux

# La piste LMMS est chargee directement plus haut ; seule l'ambiance du menu
# reste synthetisee pour que le projet ne possede que deux identites musicales.
func _composer_boucle_menu() -> AudioStreamWAV:
	var tempo := 96.0
	var battements := 16.0
	var duree := battements * 60.0 / tempo
	var echantillons := int(duree * TAUX_MUSIQUE)
	var donnees := PackedByteArray()
	donnees.resize(echantillons * 4)
	var accords := [
		[50, 53, 57], [46, 50, 53], [53, 57, 60], [48, 52, 55],
	]
	for i in echantillons:
		var temps := float(i) / float(TAUX_MUSIQUE)
		var battement := temps * tempo / 60.0
		var index_accord := int(battement / 4.0) % accords.size()
		var accord: Array = accords[index_accord]
		var local := fmod(battement, 1.0)
		var valeur_g := 0.0
		var valeur_d := 0.0
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
		var phrase := fmod(battement, 4.0)
		var enveloppe_air := pow(sin(PI * clampf(phrase / 4.0, 0.0, 1.0)), 2.0)
		var note_air: int = accord[2] + 24
		var air := sin(TAU * _frequence(note_air) * temps + 0.6) * enveloppe_air * 0.035
		valeur_g += air * 0.55
		valeur_d += air
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

func _frequence(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)

func _ecrire_stereo(donnees: PackedByteArray, index: int, gauche: float, droite: float) -> void:
	donnees.encode_s16(index * 4, int(clampf(gauche, -0.95, 0.95) * 32767.0))
	donnees.encode_s16(index * 4 + 2, int(clampf(droite, -0.95, 0.95) * 32767.0))
