extends RefCounted

func test_affiche_les_bonus_chiffres(v: Verif) -> void:
	var lignes := DetailsReactif.lignes(CatalogueReactifs.par_id("tir_multiple"))
	v.vrai("Dégâts -28 %" in lignes, "le compromis de dégâts est affiché")
	v.vrai("+1 projectile" in lignes, "le projectile supplémentaire est affiché")

func test_affiche_les_effets_elementaires(v: Verif) -> void:
	var fusion := CatalogueElements.creer_fusion("feu", "ricochet")
	v.vrai("Brûlures cumulatives" in DetailsReactif.texte(fusion),
		"la transformation Feu décrit son effet concret")

func test_detaille_les_augments_du_heros(v: Verif) -> void:
	var texte := DetailsReactif.texte(CatalogueReactifs.par_id("egide"))
	v.vrai("première attaque" in texte, "Égide affiche sa règle")
