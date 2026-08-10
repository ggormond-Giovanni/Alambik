class_name AlambicLogique
extends RefCounted

# Toute paire de reactifs de base est valide. Les essences restent des resultats
# finaux et ne peuvent pas etre refusionnees.

static func paires_possibles(inventaire: Array) -> Array[Array]:
	var trouvees: Array[Array] = []
	var vues: Array[String] = []
	for i in inventaire.size():
		for j in range(i + 1, inventaire.size()):
			var a: String = inventaire[i]
			var b: String = inventaire[j]
			var essence := Recettes.essence_pour(a, b)
			if essence == "":
				continue
			var c := Recettes.cle(a, b)
			if c in vues:
				continue
			vues.append(c)
			trouvees.append([a, b, essence])
	return trouvees

static func peut_fusionner(inventaire: Array, a: String, b: String) -> bool:
	if a == b or not a in inventaire or not b in inventaire:
		return false
	return Recettes.essence_pour(a, b) != ""

# Partenaires acceptables d'un reactif deja selectionne : l'interface montre
# ce qui est possible avant le clic, elle ne punit pas apres.
static func partenaires(inventaire: Array, id: String) -> Array[String]:
	var liste: Array[String] = []
	for paire in paires_possibles(inventaire):
		if paire[0] == id and not paire[1] in liste:
			liste.append(paire[1])
		elif paire[1] == id and not paire[0] in liste:
			liste.append(paire[0])
	return liste
