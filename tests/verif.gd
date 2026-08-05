class_name Verif
extends RefCounted

# Accumule les echecs au lieu de s'arreter au premier : une seule course
# doit dire tout ce qui est casse.

var total := 0
var echecs: Array[String] = []

func egal(obtenu, attendu, message: String) -> void:
	total += 1
	if obtenu != attendu:
		echecs.append("%s -- attendu %s, obtenu %s" % [message, attendu, obtenu])

func vrai(condition: bool, message: String) -> void:
	total += 1
	if not condition:
		echecs.append(message)

func presque(obtenu: float, attendu: float, message: String, marge := 0.001) -> void:
	total += 1
	if absf(obtenu - attendu) > marge:
		echecs.append("%s -- attendu ~%f, obtenu %f" % [message, attendu, obtenu])
