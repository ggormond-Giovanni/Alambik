class_name Reactif
extends RefCounted

var id: String
var nom: String
var description: String
var mods: Dictionary
var est_transformation := false
var famille := ""
var teinte := Color(0.9, 0.8, 0.5)   # sert au cadre et a l'icone dessinee
var glyphe := "goutte"               # forme dessinee dans l'icone
# Combien de fois on peut le reprendre. Un reactif qui ne fait qu'ajouter un
# effet n'apporte rien la seconde fois : les effets ne s'empilent pas.
var copies_max := 0                  # 0 : valeur par defaut des reglages

static func creer(id_: String, nom_: String, description_: String, mods_: Dictionary,
		transformation := false, teinte_ := Color(0.9, 0.8, 0.5), glyphe_ := "goutte",
		copies := 0, famille_ := "") -> Reactif:
	var r := Reactif.new()
	r.id = id_
	r.nom = nom_
	r.description = description_
	r.mods = mods_
	r.est_transformation = transformation
	r.teinte = teinte_
	r.glyphe = glyphe_
	r.copies_max = copies
	r.famille = famille_
	return r

func copies_permises() -> int:
	return copies_max if copies_max > 0 else Reglages.COPIES_MAX
