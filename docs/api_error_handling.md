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

## Pour les équipes mobile (iOS / Android)

Rien n'est cassé : ce sont des changements additifs, déployés dès le merge, sans nouvelle version d'app requise.

**Android** (`ApiError.kt`, `ApiErrorBottomSheet`) : le parsing de `error.code` fonctionne sans modification. `error.message` n'a jamais été affiché jusqu'ici (tout est en strings locales par code HTTP) — il devient exploitable si vous voulez un message plus précis que le texte générique par statut, en particulier sur les 422 qui recouvrent des règles métier très différentes. Le substring-matching de `checkPhoneChangeError` sur `USER_NOT_FOUND`/`USER_DELETED`/`USER_BLOCKED`/`IDENTICAL_PHONES` continue de fonctionner à l'identique.

**iOS** (`EntourageNetworkError`) : le parsing de `json["error"]` fonctionne sans modification, et le force-unwrap sur `code` ne risque plus de crasher. Partout où `error.message` est déjà affiché (SVProgressHUD, alertes), le texte est désormais traduit et plus précis, sans rien changer au code.

À vérifier côté mobile : tout code qui teste un statut HTTP exact (`== 401`, `== 400`) en dehors de l'intercepteur générique de déconnexion, sur les actions d'appartenance/propriété listées ci-dessus — ces cas renvoient maintenant 403/404/422 selon les règles ci-dessus plutôt que 401/400.

## Tests

`bundle exec rspec spec/controllers/api/v1` — suite complète verte (2618 exemples), à l'exception de 13 échecs préexistants sans rapport avec ce chantier (une relation `feeds` absente de la base de test, un test `newsletter_subscription` instable).
