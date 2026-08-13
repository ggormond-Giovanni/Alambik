class_name Vagues
extends RefCounted

# Les rencontres de campagne sont concues, pas generees depuis une courbe. La
# graine ne change que l'ordre interne de certaines vagues : le joueur peut
# apprendre une salle tout en gardant une petite variation d'execution.

const RENCONTRES := [
	[["encrier_rampant", "plume_sentinelle"], ["encrier_rampant", "encrier_rampant"]],
	[["plume_sentinelle", "encrier_rampant"], ["tache_veloce", "encrier_rampant"]],
	[["encrier_rampant", "tache_veloce", "plume_sentinelle"], ["encrier_rampant", "encrier_rampant", "plume_sentinelle"]],
	[["tache_veloce", "plume_sentinelle", "encrier_rampant"], ["tache_veloce", "encrier_rampant", "plume_sentinelle"]],
	[],
	[["plume_sentinelle", "folio_orbiteur", "encrier_rampant"], ["tache_veloce", "tache_veloce", "encrier_rampant"]],
	[["scribe_essaimeur", "plume_sentinelle"], ["folio_orbiteur", "tache_veloce", "encrier_rampant"]],
	[["tache_veloce", "marge_harceleuse", "plume_sentinelle"], ["scribe_essaimeur", "encrier_rampant", "folio_orbiteur"]],
	[["sceau_belier", "plume_sentinelle", "tache_veloce"], ["marge_harceleuse", "encrier_rampant", "folio_orbiteur"]],
	[],
	[["fiole_volatile", "miroir_encre", "tache_veloce"], ["scribe_essaimeur", "encrier_rampant", "marge_harceleuse"]],
	[["fuseau_tisseur", "folio_orbiteur"], ["plume_sentinelle", "sceau_belier", "encrier_rampant"]],
	[["cachet_phaseur", "marge_harceleuse", "plume_sentinelle"], ["miroir_encre", "fiole_volatile", "folio_orbiteur"]],
	[["scribe_essaimeur", "fuseau_tisseur", "folio_orbiteur"], ["sceau_belier", "marge_harceleuse", "encrier_rampant"]],
	[],
	[["scribe_essaimeur", "sceau_belier", "cachet_phaseur"], ["miroir_encre", "marge_harceleuse", "tache_veloce"]],
	[["fuseau_tisseur", "folio_orbiteur", "sceau_belier"], ["scribe_essaimeur", "miroir_encre", "fiole_volatile"]],
	[["scribe_essaimeur", "tache_veloce", "marge_harceleuse"], ["fuseau_tisseur", "miroir_encre", "folio_orbiteur"]],
	[["cachet_phaseur", "sceau_belier", "plume_sentinelle"], ["fiole_volatile", "marge_harceleuse", "miroir_encre"]],
	[],
]

const POOL_MINE_DEBUT := ["encrier_rampant", "plume_sentinelle", "tache_veloce", "folio_orbiteur"]
const POOL_MINE_FIN := ["encrier_rampant", "plume_sentinelle", "tache_veloce", "scribe_essaimeur",
	"folio_orbiteur", "sceau_belier", "marge_harceleuse", "miroir_encre",
	"cachet_phaseur", "fuseau_tisseur", "fiole_volatile"]

static func pour_salle(numero: int, chapitre := 0, graine := 0, mode := "grimoire") -> Array:
	if mode == "retro":
		return [
			["encrier_rampant", "plume_sentinelle", "tache_veloce"],
			["folio_orbiteur", "fiole_volatile", "fuseau_tisseur"],
			["la_rature"],
		]
	if mode == "epreuve_sorts":
		return _miniboss_aleatoire(numero, graine)
	if mode == "mine":
		# La Mine est alimentee au fil du temps par Salle, pas par une vague posee
		# integralement au chargement.
		return []
	var donnees := Chapitres.par_index(chapitre)
	if Chapitres.est_boss(chapitre, numero):
		return [[donnees["boss"]]] if numero == 20 else _miniboss_campagne(numero, chapitre, graine)
	var index := clampi(numero - 1, 0, RENCONTRES.size() - 1)
	var resultat: Array = RENCONTRES[index].duplicate(true)
	var alea := RandomNumberGenerator.new()
	alea.seed = graine * 7919 + chapitre * 104729 + numero * 31
	for vague in resultat:
		if alea.randf() < 0.5:
			vague.reverse()
	return resultat

static func _miniboss_campagne(numero: int, chapitre: int, graine: int) -> Array:
	var candidats: Array[String] = CatalogueEnnemis.ids_miniboss()
	var boss_final := str(Chapitres.par_index(chapitre)["boss"])
	candidats.erase(boss_final)
	if candidats.is_empty():
		return [[boss_final]]
	var alea := RandomNumberGenerator.new()
	alea.seed = graine * 8191 + chapitre * 131071
	var depart := alea.randi_range(0, candidats.size() - 1)
	var index_palier := maxi(0, [5, 10, 15].find(numero))
	return [[candidats[(depart + index_palier) % candidats.size()]]]

static func _miniboss_aleatoire(numero: int, graine: int) -> Array:
	var miniboss: Array[String] = CatalogueEnnemis.ids_miniboss()
	var alea := RandomNumberGenerator.new()
	alea.seed = graine * 7919
	var depart := alea.randi_range(0, miniboss.size() - 1)
	return [[miniboss[(depart + maxi(0, numero - 1)) % miniboss.size()]]]

static func pool_mine(progression: float) -> Array:
	return POOL_MINE_DEBUT if progression < 0.50 else POOL_MINE_FIN

static func ennemi_mine(alea: RandomNumberGenerator, progression := 0.0) -> String:
	var pool := pool_mine(progression)
	return pool[alea.randi_range(0, pool.size() - 1)]

static func boss_mine(graine: int) -> String:
	var candidats: Array[String] = CatalogueEnnemis.ids_miniboss()
	var alea := RandomNumberGenerator.new()
	alea.seed = graine * 65537 + 97
	return candidats[alea.randi_range(0, candidats.size() - 1)]
