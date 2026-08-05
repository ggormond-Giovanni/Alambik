class_name Vagues
extends RefCounted

# Composition des salles. Donnee pure : ajuster la difficulte ne demande
# jamais de toucher au code de la salle.

const TABLE := {
	1: [["encrier_rampant", "encrier_rampant"], ["encrier_rampant", "encrier_rampant"]],
	2: [["encrier_rampant", "plume_sentinelle"], ["encrier_rampant", "encrier_rampant", "plume_sentinelle"]],
	3: [["tache_veloce", "encrier_rampant"], ["plume_sentinelle", "plume_sentinelle"], ["tache_veloce", "tache_veloce"]],
	4: [["scribe_essaimeur"], ["encrier_rampant", "encrier_rampant", "tache_veloce"], ["scribe_essaimeur", "plume_sentinelle"]],
	6: [["tache_veloce", "tache_veloce", "plume_sentinelle"], ["scribe_essaimeur", "encrier_rampant", "encrier_rampant"], ["plume_sentinelle", "plume_sentinelle", "tache_veloce"]],
	7: [["scribe_essaimeur", "scribe_essaimeur"], ["tache_veloce", "tache_veloce", "tache_veloce"], ["plume_sentinelle", "plume_sentinelle", "encrier_rampant", "encrier_rampant"]],
	8: [["tache_veloce", "tache_veloce", "plume_sentinelle", "plume_sentinelle"], ["scribe_essaimeur", "scribe_essaimeur", "tache_veloce"], ["encrier_rampant", "encrier_rampant", "encrier_rampant", "plume_sentinelle", "tache_veloce"]],
	10: [["le_correcteur"]],
}

static func pour_salle(numero: int) -> Array:
	return TABLE.get(numero, [])
