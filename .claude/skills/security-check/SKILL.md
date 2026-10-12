---
name: security-check
description: Revue de sécurité du code commité sur une branche d'entourage-ror (API mobile, back-office, webhooks, ActionCable). Authentification par token, contrôles de propriété et d'appartenance (IDOR), strong params, injections SQL/SOQL, exposition de données dans les serializers, XSS du back-office, signatures de webhooks, secrets, logs, Rack::Attack. À utiliser pour « sécurité », « faille », « IDOR », « est-ce sécurisé ? », « audit », ou avant un merge qui touche un contrôleur, une route, un serializer ou une requête.
argument-hint: "[base, par défaut origin/master]"
---

# Revue de sécurité

Périmètre et format des constats : `.claude/skills/delivery-report/findings-format.md`. Préfixe des constats : `S-`.

On cherche ce qu'un attaquant réel peut faire avec le diff : un utilisateur connecté qui manipule ses requêtes, un client anonyme, un webhook forgé. Chaque constat donne la requête concrète qui l'exploite. Ne jamais tester une exploitation contre la préproduction ou la production : raisonner sur le code et le prouver par une spec.

## Le modèle d'accès du projet

| Surface | Authentification | Où |
|---|---|---|
| API mobile `api/v1` | `params[:token]` → `User.find_by_token` ; utilisateur supprimé ou bloqué → 401 | `app/controllers/api/v1/base_controller.rb` |
| Accès anonyme | `allow_anonymous_access only: [...]`, token `1_anonymous_<uuid>_<sig>` ; dans ces actions, utiliser `current_user_or_anonymous` | `app/services/anonymous_user_service.rb` |
| Version d'app | clé `X-API-KEY` (`API_KEYS_IOS`, `API_KEYS_ANDROID`, format `version:clé`), clé inconnue → 426 | `app/services/api/application_key.rb`, `app/validators/api_request.rb` |
| Inscription | signature HMAC obligatoire (`X-Request-Timestamp`, `X-Request-Signature`, fenêtre 300 s) | `users_controller.rb#verify_request_signature!` |
| Back-office | sous-domaine `admin`, `session[:admin_user_id]`, `authenticate_admin!` / `authenticate_super_admin!` | `app/controllers/admin/base_controller.rb` |
| Espace association | `session[:org_admin_user_id]`, `ensure_org_member!` / `ensure_org_admin!`, requêtes scopées `current_user.partner.users` | `app/controllers/organization_admin/` |
| ActionCable | token signé (back-office) ou `params[:token]` (mobile) ; abonnement soumis à un `join_request` accepté | `app/channels/` |

Les administrateurs sont considérés de confiance (décision prise lors de l'audit DPO de septembre 2026) : une action réservée aux admins est au plus une `Note`, sauf fuite hors du back-office.

Il n'y a ni Pundit ni CanCan : chaque contrôleur vérifie lui-même les droits. **L'oubli d'un contrôle est le risque principal**, y compris en lecture : les correctifs L-01 (lecture d'une conversation privée par un identifiant prévisible), L-02 (`mesure_impact` qui exposait email et téléphone) et L-03 (`/users/:user_id/entourages` d'un autre utilisateur) étaient tous des contrôles absents.

## 1. Chaque action modifiée ou ajoutée

Pour chaque action du diff (et chaque route ajoutée dans `config/routes.rb`) :

1. **Authentification** : l'action hérite de `Api::V1::BaseController` et ne saute `authenticate_user!` (`skip_before_action`, `Api::V1::Public::BaseController`, `allow_anonymous_access`) que si elle doit vraiment être publique. Une action publique ne doit renvoyer aucune donnée personnelle.
2. **Propriété**, pour toute écriture : utiliser le contrôle du voisinage.
   - `@outing.can_be_managed_by?(current_user)` (`before_action :authorised?` dans `outings_controller.rb`) ;
   - `@chat_message.user != current_user` → refus ;
   - routes imbriquées sous un utilisateur : `@user == current_user`, sinon `ActiveRecord::RecordNotFound` (`users/neighborhoods_controller.rb`) ;
   - services : `on.not_authorized` des builders et deleters.
3. **Appartenance**, pour toute lecture ou écriture dans un groupe, une conversation ou un smalltalk : `ensure_is_member` (join_request `accepted` de `current_user`). Une conversation privée, un groupe privé ou un smalltalk ne se lisent pas sans appartenance.
4. **Identifiants** : `find_by_id_through_context` / `find_by_id_or_uuid` acceptent des ids entiers prévisibles. Ne jamais compter sur un identifiant « difficile à deviner » comme contrôle d'accès.
5. **Spec** : un cas « sans token » (401) et un cas « autre utilisateur » ou « non-membre » qui doit être refusé. Une spec qui affirme qu'un non-membre obtient 200 sur une ressource privée est un constat.

## 2. Entrées

- **Strong params** : pas de `permit!`. Un client mobile ne doit pas pouvoir écrire `admin`, `super_admin`, `roles`, `moderator`, `validation_status`, `targeting_profile`, `partner_id` ou `deleted`. Le téléphone ne change que par le parcours vérifié (`request_phone_change`). Pattern correct : la permission conditionnée au rôle de `outings_controller.rb`.
- **SQL** : aucune valeur venue d'une requête ne doit être interpolée dans `where("…#{x}…")`, `Arel.sql`, `order`, `find_by_sql`, `execute`, même si elle « a l'air numérique ». Utiliser des binds (`where('x < ?', v)`), `Float()` / `Integer()` (comme `PostgisHelper`), ou une liste blanche pour les colonnes de tri.
- **SOQL** (`app/services/salesforce_services/`) : même règle, une valeur interpolée dans une chaîne `where` est une injection.
- **Dispatch dynamique** : `constantize`, `const_get`, `send`, `public_send` uniquement sur une liste blanche (pattern de `ConversationChannel` et `admin/slack_controller.rb`).
- **Redirections** : pas d'URL de redirection prise dans les params.
- **Booléens** : un cast trop permissif (`"abc"` → `true`) peut ouvrir un drapeau ; vérifier le cast quand le booléen donne un droit.

## 3. Sorties

- **Serializers** : les champs privés de `V1::UserSerializer` et `V1::AddressSerializer` sont protégés par `if: :me?`, qui dépend de `scope: { user: current_user }`. Un nouveau champ personnel est privé par défaut. Vérifier aussi les serializers « basic », « summary », « list » et ceux des membres d'un groupe : un téléphone ou un email d'un tiers ne doit jamais sortir.
- **Autres canaux** : messages Slack de modération, push, emails, exports CSV. Un champ personnel ajouté à l'un d'eux relève aussi de `rgpd-check`.
- **Back-office (XSS)** : pas de `html_safe` / `raw` sur du contenu saisi par un utilisateur. Dans un `.js.erb`, `j(contenu)` injecté par `.html(...)` n'échappe pas le HTML : échapper avec `h` avant `j`, ou utiliser `.text(...)`. `simple_format` assainit par défaut.
- **Cache Redis** : une valeur qui dépend de l'utilisateur doit avoir son id dans la clé.

## 4. Webhooks et signatures

- Référence correcte : `PoiServices::Typeform#verify` (HMAC-SHA256 du corps, `ActiveSupport::SecurityUtils.secure_compare`).
- Toute comparaison de token, signature ou code se fait en temps constant (`secure_compare`), jamais avec `==` ou `!=`.
- Refuser explicitement si le secret attendu est absent de l'ENV : sinon `nil == nil` laisse passer.
- Un nouveau webhook sans signature vérifiable doit au minimum limiter ce qu'il peut modifier, et être signalé.

## 5. Secrets, logs et traces

- Secrets uniquement par `ENV`. Aucun fichier de clé, certificat, `.env*`, dump ou export ajouté au dépôt (`git diff --name-only origin/master...HEAD`). Aucune clé en dur dans le code.
- `config/initializers/filter_parameter_logging.rb` ne masque que `passw, password, sms_code, secret, token, _key, crypt, salt, certificate, otp, ssn`. Donc :
  - jamais `params.inspect`, `params.to_unsafe_h` ou `request.url` dans `Rails.logger`, Sentry (`set_extras`), Slack ou des arguments de job : ces valeurs ne sont pas filtrées ;
  - jamais de code SMS, de téléphone ou d'email dans un message de log.
- Le token passé en query string apparaît en clair dans les logs du router Heroku : un nouvel appel ne doit pas ajouter d'autre secret dans l'URL.

## 6. Abus

- Un nouvel endpoint public, ou qui envoie un SMS ou un email, crée du contenu, ou révèle l'existence d'un compte (téléphone, email), a besoin d'une règle dans `config/initializers/rack_attack.rb` (règles actuelles : 600 requêtes / 5 min par IP, inscription 10 / h par IP, connexions 5 / 20 s par IP et par téléphone, régénération du code SMS 5 / 20 s).
- Réponses qui distinguent « existe » / « n'existe pas » sur un identifiant personnel : oracle d'énumération.

## 7. Fichiers et uploads

- URL présignées : expiration courte (1 minute aujourd'hui), type de contenu en liste blanche, clé aléatoire (`SecureRandom.uuid`), et contrôle d'appartenance sur l'action qui la délivre.
- Les objets sont en `public-read` : n'y mettre aucun document privé (export, pièce d'identité).

## 8. ActionCable

- Un nouveau channel vérifie l'appartenance dans `subscribed` et rejette sinon (`reject`).
- `allowed_request_origins` : une regex doit être ancrée (`\A…\z`).

## 9. Dépendances et outils

- Gemfile modifié : lire le changelog des gems ajoutées ou montées. Si `bundle-audit` est installé, `bundle-audit check --update` ; sinon proposer `gem install bundler-audit` sans l'installer d'office.
- Brakeman n'est pas dans le Gemfile. S'il est disponible : `brakeman --no-pager -q --only-files <fichiers du diff>` ; sinon l'indiquer dans la méthode (`Non fait` pour cet outil, pas pour le thème).

## 10. Gravité

- `Bloquant` : lecture ou écriture de données d'un autre utilisateur, injection, contournement d'authentification, secret commité, donnée personnelle exposée publiquement.
- `Important` : défaut exploitable sous conditions (webhook non signé, comparaison non constante, absence de limite sur un endpoint d'envoi de SMS).
- `Mineur` / `Note` : durcissement, défense en profondeur, actions réservées aux admins.

Un défaut préexistant découvert en passant est rapporté comme tel (« préexistant »), sans bloquer la branche, et signalé à la personne en privé : ne pas le détailler dans un rapport destiné à une audience large.

## 11. Rendu

Constats `S-NN` au format commun, chacun avec la requête d'exploitation et la spec qui le prouve ou le prouverait, puis la ligne de statut du thème.
