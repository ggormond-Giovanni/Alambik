class_name Reactif
extends RefCounted

var id: String
var nom: String
var description: String
var mods: Dictionary
var est_essence := false
var teinte := Color(0.9, 0.8, 0.5)   # sert au cadre et a l'icone dessinee
var glyphe := "goutte"               # forme dessinee dans l'icone

static func creer(id_: String, nom_: String, description_: String, mods_: Dictionary,
		essence := false, teinte_ := Color(0.9, 0.8, 0.5), glyphe_ := "goutte") -> Reactif:
	var r := Reactif.new()
	r.id = id_
	r.nom = nom_
	r.description = description_
	r.mods = mods_
	r.est_essence = essence
	r.teinte = teinte_
	r.glyphe = glyphe_
	return r
