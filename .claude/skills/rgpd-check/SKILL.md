---
name: rgpd-check
description: Contrôle données personnelles (RGPD) d'une branche d'entourage-ror. Nouvelle donnée collectée, exposition dans l'API, le back-office, Slack, les exports ou les logs, cycle de vie (suppression de compte, anonymisation, export CNIL), transferts vers des tiers (Salesforce, OpenAI, Google Translate, Mailjet, SMS), conservation. À utiliser pour « RGPD », « données personnelles », « DPO », « CNIL », « anonymisation », « suppression de compte », « export utilisateur », ou avant un merge qui touche aux utilisateurs ou à leurs contenus.
argument-hint: "[base, par défaut origin/master]"
---

# Données personnelles (RGPD)

Périmètre et format des constats : `.claude/skills/delivery-report/findings-format.md`. Préfixe des constats : `D-`.

Entourage accompagne des personnes précaires et isolées. Leurs messages et descriptions peuvent révéler des données sensibles au sens de l'article 9 (santé, situation sociale, origine, religion). Le DPO doit être informé de toute nouvelle collecte, de tout nouveau destinataire et de tout nouvel usage : c'est le premier livrable de ce contrôle, avant la technique.

## Où sont les données personnelles

| Où | Quoi |
|---|---|
| `users` | email, phone, first_name, last_name, birthdate, `options` (gender, discovery_source, ids Salesforce), about, availability, lang, token, sms_code, device_id, searchable_text (contient téléphone et email), slack_id, salesforce_id |
| `addresses` | latitude, longitude, adresse, place_name, code postal, ville, google_place_id |
| Contenus | `chat_messages.content`, titres et descriptions d'entourages et de groupes, `translations` (copies traduites), `rpush_notifications` (texte des push) |
| Traces | `user_phone_changes`, `sms_deliveries.phone_number`, `entourage_invitations.phone_number`, `user_applications.push_token`, `session_histories`, `login_histories`, `user_histories` |
| Formulaires | `contact_subscriptions.email`, `newsletter_subscriptions.email`, `messages` |

## 1. Collecte

Pour chaque nouvelle colonne, table, clé `metadata` ou `options`, ou paramètre conservé :

- **Finalité** : à quoi sert la donnée ? Une donnée sans usage dans le diff est un constat (minimisation).
- **Sensibilité** : donnée de l'article 9, donnée sur un mineur, localisation précise → `Important`, DPO à informer avant la mise en production.
- **Base légale et information** : le changement modifie-t-il ce que l'utilisateur a accepté (charte, CGU, écran d'onboarding) ? Le signaler comme point ouvert pour le DPO.

## 2. Exposition

- **API** : un champ personnel n'est visible que par son propriétaire (`if: :me?` dans `V1::UserSerializer`, coordonnées précises seulement pour `me?` dans `V1::AddressSerializer`, nom de famille réduit à l'initiale). Pour les autres, localisation approchée (`EntourageServices::LocationApproximationService`). Voir `security-check` pour le contrôle d'accès.
- **Back-office** : listes, exports CSV (`UserServices::Exporter`, `UserServices::ListExporter`), emails d'export.
- **Slack** : les canaux de modération reçoivent-ils un téléphone, un email, un contenu de message ? Seulement si la modération en a besoin.
- **Logs, Sentry, arguments de jobs** : `filter_parameter_logging` ne masque que les secrets (`token`, `password`, `sms_code`…), pas le téléphone, l'email, le nom ni les coordonnées. Aucune donnée personnelle dans un message de log ; jamais `params.inspect` / `params.to_unsafe_h` ; un nouveau paramètre personnel peut être ajouté à `config/initializers/filter_parameter_logging.rb`.
- **Fichiers** : les uploads S3 sont en `public-read` : jamais d'export ni de document personnel dans ces buckets.

## 3. Cycle de vie

Deux chemins de fin de compte, qui ne font pas la même chose :

| Chemin | Code | Effet aujourd'hui |
|---|---|---|
| Suppression par l'utilisateur (`DELETE` via l'API) | `UserServices::DeleteUserService#delete` | suffixe horodaté sur téléphone et email, `deleted: true`, `validation_status: 'deleted'` ; réversible (`undelete`) ; le reste du profil est conservé |
| Anonymisation (back-office, `rake cnil_task:anonymize`) | `User#anonymize!(updater)` | remplace email, téléphone, prénom, efface nom et adresse ; ne touche pas `birthdate`, `about`, `options`, `token`, `device_id`, les push tokens, les contenus, ni Salesforce |

Pour toute nouvelle donnée personnelle :

- l'ajouter à `User#anonymize!` (et se demander si `DeleteUserService` doit l'effacer) ;
- l'ajouter à l'export du droit d'accès (`UserServices::Exporter`, `rake cnil_task:export`) ;
- vérifier si elle part vers Salesforce (`SalesforceServices::User#updatable_fields`, `SalesforceServices::UserTableInterface`) : une suppression de compte n'y efface rien, seul le statut passe à « supprimé ».

Si la branche touche à ces chemins, signaler les trous préexistants qu'elle laisse en l'état (constat « préexistant »).

## 4. Destinataires externes

Tout nouveau flux de données personnelles vers un tiers est un constat `Important` à faire valider par le DPO (registre des traitements, sous-traitant, transfert hors UE) :

| Tiers | Ce qui y part aujourd'hui |
|---|---|
| Salesforce | profil (nom, email, téléphone, code postal, coordonnées, statut), à chaque connexion quotidienne |
| OpenAI | contenus pour la détection de propos offensants et le matching |
| Google Translate | titres, descriptions et messages, envoyés à `translate.google.com` pour traduction automatique |
| Mailjet | emails, variables des templates |
| Fournisseurs SMS (Vonage/Nexmo, AWS SNS) | téléphone et texte (codes de connexion) |
| APNs / FCM | texte des notifications |
| Slack | contenus et identités pour la modération |

## 5. Conservation

Il n'existe aujourd'hui aucun job de purge. Une nouvelle donnée à finalité limitée dans le temps (code, lien signé, trace technique) doit avoir une durée de conservation et un mécanisme d'effacement, ou le point est ouvert pour le DPO.

## 6. Données de production pendant le développement

- Ne jamais copier de données personnelles de production dans le dépôt, un rapport, un ticket ou une conversation : volumes et agrégats seulement.
- Les dumps (`bin/docker/db-pull`) excluent les tables volumineuses ou sensibles listées dans `bin/database-operations.md` ; ne pas réduire cette liste.

## 7. Rendu

Constats `D-NN` au format commun, la ligne de statut du thème, et la liste des points à soumettre au DPO (pour la section « Points ouverts » du rapport, avec « DPO » dans la colonne « Qui tranche »).
