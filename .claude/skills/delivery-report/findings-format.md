# Format commun des constats

Tous les skills `*-check` rendent leurs constats dans ce format. `delivery-report` les reprend tels quels dans la section « Contrôles » du rapport, et `branch-review` les agrège.

## Périmètre par défaut

Sauf demande contraire, un contrôle porte sur le diff de la branche courante contre master :

```bash
git fetch origin master --quiet
git diff --stat origin/master...HEAD
git diff origin/master...HEAD -- <fichiers>
git log --reverse --format='%h %s' origin/master..HEAD
```

Ajouter les changements non commités (`git status`, `git diff HEAD`) en le signalant. Lire le code autour du diff (appelants, modèle, serializer, spec) avant de conclure : un constat se vérifie dans le code, pas dans le diff seul.

## Un constat

| Champ | Contenu |
|---|---|
| Identifiant | Préfixe du thème + numéro : `S-01` sécurité, `P-` performance, `Q-` qualité, `T-` testabilité, `D-` données personnelles, `A-` compatibilité apps, `M-` migrations |
| Gravité | `Bloquant` (ne pas merger en l'état), `Important` (à corriger avant ou juste après le merge), `Mineur` (amélioration), `Note` (information, pas d'action) |
| Emplacement | `chemin/fichier.rb:ligne`, cliquable |
| Défaut | Une phrase |
| Scénario | Entrées ou état concrets → mauvais résultat. Sans scénario plausible, ce n'est pas un constat : au mieux une `Note` |
| Correction | Correctif proposé (ou appliqué, avec le hash du commit) |
| Statut | `À corriger`, `Corrigé dans <hash>`, `Accepté` (risque assumé, dire par qui), `Reporté` (ticket ou raison) |

## Statut d'un thème

Un contrôle se termine par une ligne de synthèse :

- `OK` : rien à signaler, ou seulement des `Note`.
- `À voir` : au moins un constat `Important` ou `Mineur`.
- `Bloquant` : au moins un constat `Bloquant`.
- `Sans objet` : la branche ne touche pas ce thème (dire pourquoi en une phrase).
- `Non fait` : le contrôle n'a pas pu être mené (dire pourquoi, par ex. base de préprod inaccessible).

## Rendu dans le terminal

Quand le contrôle est lancé seul, sans rapport :

```
Sécurité : À voir (2 constats)

S-01 Important · app/controllers/api/v1/outings_controller.rb:88
  Un participant non créateur peut modifier l'événement.
  Scénario : PATCH /api/v1/outings/12 avec le token d'un membre → 200 et titre changé.
  Correction : vérifier `@outing.user == current_user` comme dans #cancel.
  Statut : À corriger
```

Proposer ensuite, en une ligne, de corriger les constats ou de les publier dans le rapport de livraison.

## Règles

- Classer du plus grave au moins grave.
- Ne pas gonfler : un constat non vérifié ou purement théorique devient une `Note` ou disparaît.
- Signaler ce qui préexiste à la branche comme tel (« préexistant ») : c'est utile, mais ça ne bloque pas la branche.
- Écrire en français, phrases courtes, termes du code en `code`.
