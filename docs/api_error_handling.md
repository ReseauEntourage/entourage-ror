# Gestion des erreurs API (EN-9347)

Toutes les routes `api/v1` renvoient désormais leurs erreurs sous une enveloppe commune, en plus des champs déjà existants (`message`, `reasons`, ...) qui restent inchangés pour ne pas casser les anciennes versions des apps.

```json
{
  "message": "unauthorized",
  "error": {
    "code": "FORBIDDEN",
    "message": "Vous n'avez pas les droits nécessaires pour effectuer cette action."
  }
}
```

- `error.code` : toujours une string, jamais absente ni nulle (le parsing iOS en fait un force-cast, donc c'est une garantie stricte).
- `error.message` : toujours une string non vide, traduite selon `current_user.lang` (fr/en complets dans `config/locales/{fr,en}.yml` sous `api.errors.*` ; les 6 autres locales retombent sur le français en attendant une vraie traduction).
- Les autres champs (`message`, `reasons`, codes ad hoc comme `USER_NOT_FOUND`...) restent strictement identiques à ce qu'ils étaient avant ce chantier.

Implémenté par `Api::V1::BaseController#render_error(code:, status:, message: nil, legacy: {})` (`app/controllers/api/v1/base_controller.rb`).

## Quel champ utiliser, et quand

Une réponse d'erreur peut contenir plusieurs champs à la racine en plus de `error`, hérités de l'ancien format de chaque endpoint. **Règle simple : pour la logique (switch/if), lisez toujours `error.code`. Pour un message générique à afficher, lisez `error.message`. `reasons` est à part : c'est le seul champ qui donne le détail par champ d'une validation, et il vaut le coup de l'exploiter quand il est présent.** Tous les autres champs ci-dessous ne sont là que pour ne pas casser les anciennes versions de l'app.

| Champ | Type | Présent | Contenu | À faire |
|---|---|---|---|---|
| `error.code` | string | **Toujours**, sur toute vraie erreur | Identifiant stable, ex. `FORBIDDEN`, `NOT_FOUND`, `USER_NOT_FOUND` | ✅ Utiliser pour toute logique conditionnelle |
| `error.message` | string | **Toujours**, jamais vide | Une phrase générique, traduite selon `user.lang` | ✅ Utiliser comme message par défaut, surtout hors validation |
| `reasons` (racine) | array&lt;string&gt; | Quand l'erreur vient d'un modèle invalide (ex. création/mise à jour ratée) | Un message **par champ en erreur** (ex. `["Title can't be blank", "Email n'est pas valide"]`) — **toujours en français**, non lié à `user.lang` (généré par Rails, pas par notre i18n) | ✅ Utiliser en priorité sur un formulaire à plusieurs champs, si un texte français est acceptable ; sinon replier sur `error.message` |
| `errors` (racine, avec un *s*) | array&lt;string&gt; | Un seul endpoint : `POST /api/v1/messages` | Exactement la même chose que `reasons` (même origine, même limite de langue), nom différent par héritage historique | ✅ Même usage que `reasons` sur cet endpoint précis — piège : ne pas chercher `reasons` dessus, ni `errors` ailleurs |
| `message` (racine) | string | Selon l'endpoint (hérité) | Texte technique, souvent redondant avec `error.message`, pas forcément traduit | ⛔️ Ignorer dans du code neuf |
| `code` (racine, **hors** `error`) | string | Une poignée d'endpoints "signaler" (`CANNOT_REPORT_USER`, `CANNOT_REPORT_OUTING`, `CANNOT_REPORT_DONATION`, `CANNOT_REPORT_ENTOURAGE`) | Duplique exactement `error.code` | ⛔️ Ignorer, lire `error.code` à la place |

**Pourquoi `reasons`/`errors` ne sont pas simplement traduits comme `error.message` :** ils viennent de `record.errors.full_messages`, généré par le système de validation de Rails lui-même, indépendant de notre `render_error`. Le localiser proprement (un message par champ, dans la langue de l'utilisateur) demanderait de faire transiter chaque validation par `I18n.with_locale(user.lang)` au moment de la sauvegarde — un chantier à part, pas fait ici. En attendant, ce texte reste en français quel que soit `user.lang`.

**Une exception à la règle "`error` toujours présent" :** `POST /api/v1/entourages/:id/invitations` (envoi groupé de SMS) renvoie, en cas d'échec partiel, `{"successfull_numbers": [...], "failed_numbers": [...]}` en HTTP 400 - ce n'est pas une erreur unique mais un résultat mixte, donc pas d'objet `error`. À traiter au cas par cas sur cet endpoint précis.

## Registre des codes

Six codes génériques, centralisés dans `lib/api/v1/error_codes.rb` :

| Code | Renvoyé quand... |
|---|---|
| `UNAUTHORIZED` | Session absente ou invalide (le seul cas qui garde le statut 401) |
| `FORBIDDEN` | Utilisateur authentifié mais sans droit sur la ressource visée |
| `NOT_FOUND` | La ressource demandée n'existe pas ou plus |
| `VALIDATION_ERROR` | Paramètres invalides ou règle métier non respectée |
| `PARAMETER_MISSING` | Un paramètre obligatoire manque dans la requête |
| `INTERNAL_ERROR` | Exception non prévue, capturée par le filet de sécurité global |

Les codes déjà spécifiques à une ressource (`USER_NOT_FOUND`, `USER_DELETED`, `USER_BLOCKED`, `IDENTICAL_PHONES`, `INVALID_PHONE_FORMAT`, `CANNOT_UPDATE_USER`...) sont conservés tels quels là où ils existaient déjà.

## Corrections de codes HTTP

Trois familles de correction ont été appliquées aux endroits où le statut était incohérent avec son sens réel :

- **401 → 403** (~57 endroits) : l'utilisateur est authentifié mais n'a pas le droit sur la ressource ("pas accepté dans cette entourage/sortie/quartier/conversation", "pas le créateur", "pas administrateur"...). Sur Android et iOS, un 401 déclenche une **déconnexion globale forcée** — ces cas déconnectaient donc des utilisateurs par erreur pour un simple refus de permission. C'est corrigé.
- **400 → 404** (~66 endroits) : ressource réellement introuvable, auparavant renvoyée comme une "mauvaise requête" générique.
- **400 → 422** (~92 endroits) : échec de validation ou de règle métier. Les deux apps ont déjà un écran dédié pour le code 422.

Statuts volontairement **non touchés**, faute de preuve d'un problème réel ou hors du périmètre mobile :
- Le flux de connexion (`/login`) et la vérification de signature au signup restent en 401 (pré-authentification, une "déconnexion" y est un no-op).
- Le 426 de clé API invalide/manquante (`ApiRequest::Unauthorised`) — mécanisme indépendant du *force-update* Android, qui cible un endpoint dédié.
- `pois_controller.rb` (vérification de signature webhook Typeform, serveur à serveur) et `uptimes_controller.rb` (endpoint d'ops réservé aux super-admins) : pas de client mobile concerné.
- `entourages/invitations_controller.rb` : la réponse d'invitations SMS en partie échouées (`{successfull_numbers, failed_numbers}`, statut 400) est un résultat mixte, pas une erreur simple — laissée telle quelle.

## Exemples concrets

**403 (était 401) — pas membre d'une entourage/sortie/quartier/conversation**

`POST /api/v1/entourages/:id/chat_messages` par un utilisateur non accepté :

```jsonc
// Avant : HTTP 401
{ "message": "unauthorized : you are not accepted in this entourage" }

// Après : HTTP 403
{
  "message": "unauthorized : you are not accepted in this entourage",
  "error": {
    "code": "FORBIDDEN",
    "message": "Vous n'avez pas les droits nécessaires pour effectuer cette action."
  }
}
```

**404 (était 400, ou une page HTML en cas de crash) — ressource introuvable**

`GET /api/v1/conversations/:id` avec un id inconnu :

```jsonc
// Avant : HTTP 400
{ "message": "Could not find conversation" }

// Après : HTTP 404 (le champ "message" ne bouge pas)
{
  "message": "Could not find conversation",
  "error": {
    "code": "NOT_FOUND",
    "message": "Cette ressource n'existe pas ou n'est plus disponible."
  }
}
```

`GET /api/v1/entourages/:id` avec un id qui n'existe pas du tout (géré par le filet de sécurité global, aucun `render` local n'existait avant) :

```jsonc
// Après : HTTP 404
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Cette ressource n'existe pas ou n'est plus disponible."
  }
}
```

**422 (était 400) — validation**

`POST /api/v1/entourages` avec un titre vide :

```jsonc
// Avant : HTTP 400
{ "message": "Could not create entourage", "reasons": ["Title can't be blank"] }

// Après : HTTP 422 (message et reasons inchangés)
{
  "message": "Could not create entourage",
  "reasons": ["Title can't be blank"],
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Certaines informations saisies ne sont pas valides."
  }
}
```

Sur ce type d'erreur (`VALIDATION_ERROR`), préférez afficher `reasons` (ici : « Title can't be blank ») plutôt que le générique `error.message` - c'est la seule façon de dire à l'utilisateur *quel* champ corriger.

**401 conservé — vrai échec d'authentification**

`POST /api/v1/login` avec un mauvais code SMS (comportement inchangé par ce chantier) :

```jsonc
// HTTP 401, avant comme après
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "wrong phone / sms_code"
  }
}
```

**Bonus : un message vide devient exploitable**

`GET /api/v1/users/code` pour un numéro inconnu utilisait déjà `error.code`, mais avec un message vide - désormais rempli automatiquement par le texte générique :

```jsonc
// Avant : HTTP 404
{ "error": { "code": "USER_NOT_FOUND", "message": "" } }

// Après : HTTP 404 (code inchangé, message enfin exploitable)
{ "error": { "code": "USER_NOT_FOUND", "message": "Une erreur est survenue. Veuillez réessayer." } }
```

## Pour les équipes mobile (iOS / Android)

Rien n'est cassé : ce sont des changements additifs, déployés dès le merge, sans nouvelle version d'app requise.

**Android** (`ApiError.kt`, `ApiErrorBottomSheet`) : le parsing de `error.code` fonctionne sans modification. `error.message` n'a jamais été affiché jusqu'ici (tout est en strings locales par code HTTP) — il devient exploitable si vous voulez un message plus précis que le texte générique par statut, en particulier sur les 422 qui recouvrent des règles métier très différentes. Le substring-matching de `checkPhoneChangeError` sur `USER_NOT_FOUND`/`USER_DELETED`/`USER_BLOCKED`/`IDENTICAL_PHONES` continue de fonctionner à l'identique.

**iOS** (`EntourageNetworkError`) : le parsing de `json["error"]` fonctionne sans modification, et le force-unwrap sur `code` ne risque plus de crasher. Partout où `error.message` est déjà affiché (SVProgressHUD, alertes), le texte est désormais traduit et plus précis, sans rien changer au code.

À vérifier côté mobile : tout code qui teste un statut HTTP exact (`== 401`, `== 400`) en dehors de l'intercepteur générique de déconnexion, sur les actions d'appartenance/propriété listées ci-dessus — ces cas renvoient maintenant 403/404/422 selon les règles ci-dessus plutôt que 401/400.

## Tests

`bundle exec rspec spec/controllers/api/v1` — suite complète verte (2618 exemples), à l'exception de 13 échecs préexistants sans rapport avec ce chantier (une relation `feeds` absente de la base de test, un test `newsletter_subscription` instable).
