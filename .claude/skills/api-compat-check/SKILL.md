---
name: api-compat-check
description: Vérifier qu'un changement d'entourage-ror ne casse pas les apps iOS et Android déjà installées (versions anciennes comprises), ni la webapp, les webhooks ou les Lambdas. Champs JSON, types, null/false/absent, routes et verbes, codes HTTP (401 = déconnexion), paramètres, metadata, textes traduits (8 langues). À utiliser pour « compatibilité », « ça casse les apps ? », « anciennes versions », « nouveau champ API », « supprimer une route », « i18n », « traduction », ou avant un merge qui touche l'API.
argument-hint: "[base, par défaut origin/master]"
---

# Compatibilité avec les apps et les autres clients

Périmètre et format des constats : `.claude/skills/delivery-report/findings-format.md`. Préfixe des constats : `A-`.

Une app mobile publiée reste installée des mois sans mise à jour, et il n'existe aucun mécanisme de version minimale forcée côté API. Tout changement doit donc fonctionner avec les versions en circulation, pas seulement avec `develop`.

## Qui appelle l'API

| Client | Où lire ses appels |
|---|---|
| iOS | `../entourage-ios/entourage/Network Managers/Endpoints.swift` (constantes `kAPI…`) et `Network Managers/*Service.swift` ; certaines routes sont construites ligne à ligne (`let endpoint = kAPI…` puis concaténation) |
| Android | `../entourage-android/app/src/main/java/social/entourage/android/api/request/*.kt` (annotations Retrofit `@GET("…")`, `@POST`, `@PUT`, `@PATCH`, `@DELETE`) |
| Webapp | clé d'API `web` |
| Back-office | même application Rails, routes `admin` |
| Webhooks entrants | Typeform (`pois#create`, `users#ethics_charter_signed`), Mailjet, Slack, iRaiser |
| Lecteurs de la base | Lambdas `../entourage-tasks`, Metabase (voir `migration-check`) |

La version d'app d'une requête se déduit de sa clé `X-API-KEY` (`app/services/api/application_key.rb`, format `version:clé`) ; la version installée par appareil est dans `user_applications.version`. Pour savoir si une ancienne version circule encore : Datadog (champ `version` des lignes lograge, 15 jours de logs) ou une requête en lecture seule sur `user_applications`, avec l'accord de la personne.

Si un dépôt mobile n'est pas cloné à côté de celui-ci, le dire et limiter la conclusion.

## 1. Réponses JSON

- **Ne jamais supprimer ni renommer un champ.** Un champ obsolète reste, avec une valeur vide du bon type et un commentaire `# @deprecated` (modèle : `birthday` et `memberships` dans `app/serializers/v1/user_serializer.rb`).
- **Ne jamais changer le type** d'un champ (chaîne ↔ nombre ↔ booléen ↔ objet). iOS décode strictement et force certains casts (`error.code` doit rester une chaîne).
- **Nouveau champ** : purement additif. Choisir une seule convention pour l'absence de valeur et la tenir dans **tous** les serializers de la ressource. Cas réel (EN-9582) : `pmr` vaut `false` dans l'index, `null` dans le détail et est absent des sorties créées avant le déploiement ; l'app doit gérer les trois.
- **Une ressource a plusieurs serializers** (index, détail, home, list, summary) : `grep -rn "<attribut>" app/serializers` et mettre à jour chacun, ou justifier.
- Les champs « de compatibilité » existants (`members` qui renvoie des objets factices pour `members.size`) ne se retirent pas.

## 2. Routes et paramètres

- **Ne jamais supprimer une route** encore appelée par une version en circulation. Vérifier dans Datadog et dans le code mobile, sur `develop` et sur les branches ou tags des versions encore utilisées. Exemple : `DELETE /api/v1/outings/:id` a été restauré car iOS ≤ 14.1 et Android ≤ 14.0 annulent un évènement avec, alors que les versions récentes utilisent `POST /cancel`.
- **Ne jamais changer le verbe** d'une route existante ; en ajouter un si besoin.
- **Nouveau paramètre** : toujours optionnel, avec une valeur par défaut qui reproduit l'ancien comportement.
- **Paramètres reçus en chaînes** : un booléen arrive en `"true"`, `"1"`, `"false"`… Le caster explicitement et accepter les formes que les apps envoient.
- **Points d'entrée multiples** : un champ ajouté à `outings#create` doit l'être aussi à `update`, `batch_update` et `POST /neighborhoods/:id/outings`, sinon il est ignoré en silence selon l'écran d'origine.
- **`metadata` des entourages** : clé nouvelle = valeur par défaut obligatoire (voir `migration-check`), types tolérants (`[:string, :boolean, :null]`) pour les anciens clients.
- **Pagination** : ne pas changer `per` par défaut, l'ordre de tri ou la sémantique d'un filtre existant sans coordination avec les apps.

## 3. Codes HTTP et erreurs

- **Un 401 déconnecte l'utilisateur** sur iOS et Android. Le 401 est réservé au token absent ou invalide. Un refus de droit (non-propriétaire, non-membre) renvoie 403. La branche `EN-9347-api-errors-management` (document `docs/api_error_handling.md`) migre les refus existants de 401 vers 403 ; un nouveau refus en 401 est un constat `Important`.
- Format d'erreur : garder les champs existants (`message`, `reasons`, `errors`) ; ne pas inventer un nouveau format dans un contrôleur isolé.
- Clé d'API inconnue → 426 : ne pas changer ce code, les apps l'utilisent pour proposer la mise à jour.

## 4. Textes renvoyés aux apps (i18n)

- Langues : `fr` (référence), `en`, `de`, `es`, `pl`, `ro`, `uk`, `ar` (`Translation::LANGUAGES`). Toute nouvelle clé visible par un utilisateur existe dans les 8 fichiers `config/locales/*.yml`. Signaler les traductions non relues par un humain.
- `I18n.locale` n'est jamais réglé par requête : un texte destiné à un utilisateur précis se traduit avec `I18n.t(clé, locale: user.lang)`. Le paramètre s'appelle `locale:`, pas `lang:` (un `lang:` est ignoré et renvoie toujours le français).
- `user.lang` n'est pas validé : prévoir le repli sur `fr` pour une langue inconnue.
- Push, inapp et emails passent par `PushNotificationTrigger::I18nStruct` / les mailers avec `user.lang` : suivre le même chemin.
- Vérification : `bundle exec rake i18n:smoke_test` (prévu pour la préprod, transaction annulée, `VERBOSE=1` pour voir les textes) et, a minima, un chargement des YAML modifiés.

## 5. iso-fonctionnalité iOS / Android

Une route ou un champ utilisé par une seule des deux apps est signalé, avec la date à laquelle l'app l'a ajouté (`git log -S "<route>"` dans le dépôt mobile) : l'autre app doit-elle suivre ?

## 6. Rendu

Constats `A-NN` au format commun, la ligne de statut du thème, et pour la section « Déploiement » du rapport : ce que les apps doivent faire (nouveau champ à lire, route à adopter), les versions concernées, et si l'ordre de mise en production compte (API avant apps).
