extends RefCounted

func test_premiere_phase(v: Verif) -> void:
	v.egal(Boss.phase_pour(100.0, 100.0), 1, "a pleine vie, phase 1")
	v.egal(Boss.phase_pour(60.0, 100.0), 1, "au-dessus de la moitie, phase 1")

func test_seconde_phase(v: Verif) -> void:
	v.egal(Boss.phase_pour(40.0, 100.0), 2, "sous la moitie, phase 2")

func test_motifs_cycliques(v: Verif) -> void:
	v.egal(Boss.motif_suivant(1, 0), Boss.motif_suivant(1, Boss.MOTIFS_PHASE_1.size()),
		"les motifs bouclent")

func test_motifs_connus(v: Verif) -> void:
	for phase in [1, 2]:
		for i in 6:
			var motif := Boss.motif_suivant(phase, i)
			v.vrai(motif in Boss.MOTIFS_PHASE_1 + Boss.MOTIFS_PHASE_2, "motif %s inconnu" % motif)

func test_la_seconde_phase_change_de_repertoire(v: Verif) -> void:
	# Une phase 2 qui rejoue les memes motifs n'est pas une seconde phase.
	v.vrai("invocation" in Boss.MOTIFS_PHASE_2, "la phase 2 invoque")
	v.vrai(not "invocation" in Boss.MOTIFS_PHASE_1, "la phase 1 n'invoque pas")
