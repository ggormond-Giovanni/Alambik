extends RefCounted

func test_rampant_avance_de_loin(v: Verif) -> void:
	v.egal(Cerveaux.rampant(400.0, 60.0), "avancer", "loin, le rampant avance")

func test_rampant_frappe_au_contact(v: Verif) -> void:
	v.egal(Cerveaux.rampant(50.0, 60.0), "frapper", "au contact, il frappe")

func test_sentinelle_tire_a_portee(v: Verif) -> void:
	v.egal(Cerveaux.sentinelle(500.0, 700.0, 0.0), "tirer", "a portee et rechargee, elle tire")

func test_sentinelle_attend_si_pas_rechargee(v: Verif) -> void:
	v.egal(Cerveaux.sentinelle(500.0, 700.0, 0.4), "attendre", "en recharge, elle attend")

func test_sentinelle_hors_portee(v: Verif) -> void:
	v.egal(Cerveaux.sentinelle(900.0, 700.0, 0.0), "attendre", "hors de portee, elle attend")

func test_veloce_prepare_puis_charge(v: Verif) -> void:
	v.egal(Cerveaux.veloce(600.0, "repos", 0.0), "preparer", "de loin, elle se prepare")
	v.egal(Cerveaux.veloce(600.0, "preparer", 0.0), "charger", "preparation finie, elle charge")
	v.egal(Cerveaux.veloce(600.0, "preparer", 0.5), "preparer", "la preparation dure")
	v.egal(Cerveaux.veloce(600.0, "charger", 0.0), "repos", "la charge finie, elle se repose")

func test_essaimeur_garde_ses_distances(v: Verif) -> void:
	v.egal(Cerveaux.essaimeur(200.0, 500.0, 1.0), "reculer", "trop pres, il recule")
	v.egal(Cerveaux.essaimeur(900.0, 500.0, 1.0), "avancer", "trop loin, il avance")
	v.egal(Cerveaux.essaimeur(500.0, 500.0, 0.0), "invoquer", "a bonne distance et pret, il invoque")
	v.egal(Cerveaux.essaimeur(500.0, 500.0, 2.0), "attendre", "a bonne distance mais en recharge, il attend")
