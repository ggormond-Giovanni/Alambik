extends RefCounted

func test_egal_detecte_une_difference(v: Verif) -> void:
	var interne := Verif.new()
	interne.egal(1, 2, "controle")
	v.egal(interne.echecs.size(), 1, "un ecart doit produire un echec")

func test_egal_accepte_une_egalite(v: Verif) -> void:
	var interne := Verif.new()
	interne.egal(3, 3, "controle")
	v.egal(interne.echecs.size(), 0, "une egalite ne doit rien signaler")

func test_presque_tolere_la_marge(v: Verif) -> void:
	var interne := Verif.new()
	interne.presque(1.0, 1.0005, "controle")
	v.egal(interne.echecs.size(), 0, "un ecart sous la marge est accepte")
