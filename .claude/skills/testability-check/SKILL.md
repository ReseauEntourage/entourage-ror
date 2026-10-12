---
name: testability-check
description: Vérifier qu'une branche d'entourage-ror est correctement testée et écrire les specs manquantes selon les conventions du dépôt (RSpec, specs de contrôleur avec token, factory_bot, stubs globaux). Couvre aussi la conception testable et les pièges connus de la suite. À utiliser pour « est-ce testé ? », « écris les specs », « couverture », « spec qui échoue », « testabilité », ou avant un merge.
argument-hint: "[base, par défaut origin/master]"
---

# Testabilité et couverture

Périmètre et format des constats : `.claude/skills/delivery-report/findings-format.md`. Préfixe des constats : `T-`.

## 1. Chaque changement a sa spec

Pour chaque changement de comportement du diff (`app/`, `lib/`, `config/routes.rb`) :

1. Trouver la spec qui le couvre (`spec/` miroir de `app/`). Les specs de serializers sont dans `spec/services/v1/`.
2. Vérifier qu'elle teste le comportement, pas l'implémentation : statut HTTP **et** contenu de la réponse, état en base après l'action, job ou mail réellement mis en file.
3. Vérifier qu'elle **échoue sans le correctif**. Si le working tree des fichiers applicatifs est propre :

   ```bash
   git status --porcelain app lib config            # doit être vide
   git diff origin/master...HEAD -- app lib config | git apply -R
   bundle exec rspec spec/chemin/de_la_spec.rb      # doit échouer
   git checkout -- app lib config                   # restaure le code de la branche
   ```

   Si des changements ne sont pas commités, ou si la branche supprime des fichiers, ne pas jouer ce tour : raisonner sur le code et le dire.
4. Absence de spec, ou spec qui passerait sans le correctif : constat `T-` (`Important` pour un correctif de bug ou une règle métier, `Mineur` pour du confort).

Cas à ne pas oublier : les cas d'erreur (401 sans token, 403/401 pour un non-propriétaire, 400 sur paramètre invalide), les valeurs limites (nil, chaîne vide, `"abc"` pour un booléen), les utilisateurs d'une autre communauté (`with_community :pfp`), les effets de bord (push, Slack, mail, job).

## 2. Conventions d'écriture

- **API** : specs de contrôleur (`type: :controller`), pas de specs de requête. Authentification par paramètre :

  ```ruby
  describe Api::V1::OutingsController, type: :controller do
    let(:user) { create :pro_user }
    let(:result) { JSON.parse(response.body) }

    context 'not authorized' do
      before { get :index }
      it { expect(response.status).to eq 401 }
    end

    context 'authorized' do
      before { get :index, params: { token: user.token } }
      it { expect(result['outings'].count).to eq(1) }
    end
  end
  ```

- **Back-office** : `include AuthHelper`, `let!(:user) { admin_basic_login }`, `assigns(...)` disponible.
- **Factories** (`spec/factories/`, factory_bot 4) : `:public_user`, `:pro_user`, `:partner_user`, `:admin_user`, `:offer_help_user`, `:ask_for_help_user` ; `:entourage` (traits `:open`, `:closed`, `:joined`…, transients `participants:`), `:outing` (`:with_recurrence`, `:outing_class`, `:with_neighborhood`), `:contribution`, `:solicitation`, `:conversation`, `:neighborhood` (`participants:`), `:chat_message`, `:join_request`, `:smalltalk`, `:user_smalltalk`. Réutiliser un trait existant avant d'en créer un.
- **Temps** : `Timecop.freeze(...)` (un `Timecop.return` global est déjà fait avant chaque exemple). Pas de `travel_to`.
- **ENV** : ne jamais affecter `ENV[...]` dans une spec (ça fuit dans les suivantes). Utiliser `allow(ENV).to receive(:[]).and_call_original` puis `allow(ENV).to receive(:[]).with('X').and_return(...)`.
- **Communauté** : `include CommunityHelper` puis `with_community :pfp`, jamais modifier `$server_community` à la main.
- **Nom de fichier** : toujours `*_spec.rb` (un fichier `_rspec.rb` ne tourne jamais).
- Style : `before { requête }` + `it { expect(...) }` sur une ligne, comme les specs voisines.

## 3. Ce que l'environnement de test fait à ta place

`spec/rails_helper.rb` et `spec/spec_helper.rb` posent des stubs globaux. Les connaître évite des specs qui ne testent rien :

- **Sidekiq est en mode `inline!`** partout : les jobs (et les jobs ActiveJob) s'exécutent immédiatement. Pour tester la mise en file : `around { |ex| Sidekiq::Testing.fake!(&ex) }` ou `Sidekiq::Testing.disable!`.
- `SalesforceJob`, `OpenaiRequestJob` et `CreateGoogleMeetJob` ont `perform` stubbé ; `translate_field!` renvoie `'foo'` sur `ChatMessage`, `Entourage`, `Neighborhood` ; Mailjet, OpenAI, Slack (`https://url.to.slack.com`) et Google Calendar sont interceptés par WebMock. Pour tester l'un d'eux, lever le stub explicitement dans la spec.
- **Geocoder** répond Crozon (29160, FR) par défaut. Les stubs de test n'ont pas de `types` : stubber `EntourageServices::GeocodingService.search_postal_code` directement.
- Redis est remplacé par `fakeredis` pour le client `redis` ; Sidekiq, lui, parle à un vrai Redis (db 0 si `REDIS_URL` n'est pas défini).

## 4. Pièges connus

- **Un double cache le vrai bug** : un mailer ou un service remplacé par un double ne voit pas les erreurs de sérialisation (`deliver_later` avec une `ActiveRecord::Relation`). Pour un mail ou un job, au moins une spec doit mettre en file le vrai objet.
- **Les specs de contrôleur contournent le routage** : `patch :batch_update` passe même si la route n'accepte que `PUT`. Pour un changement de route ou de verbe, ajouter une spec de routage (`expect(put: '/api/v1/...').to route_to(...)`).
- **`have_broadcasted_to` bloque dans une spec `type: :request`** : l'utiliser en spec de channel ou de contrôleur. Après décodage JSON, les valeurs sont des chaînes (`type: 'chat_message_created'`).
- **Effets de bord d'observers et callbacks** : une création peut déclencher Slack, géocodage, push, badges. Si la spec n'en teste pas un, le stubber explicitement (`allow(Experimental::EntourageSlack).to receive(:notify)`).
- **Ordre** : la suite tourne dans l'ordre défini, sans graine aléatoire. Lancer les nouvelles specs avec `--order random` pour détecter une dépendance d'ordre.
- **Heure** : `scheduled_publications_helper_spec` échoue entre 21 h et minuit (fuseau Paris). Les factories utilisent des dates relatives (`1.day.from_now`) : figer le temps dès qu'une assertion dépend d'une date.
- **N+1** : si `spec/support/n_plus_one_helper.rb` existe sur la base (branche `n-1-exploration`, présente sur staging), toute nouvelle action `index` d'`api/v1` ou `admin` doit avoir sa spec dans `spec/n_plus_one/` (voir `perf-check`), sinon `spec/n_plus_one/coverage_spec.rb` échoue.

## 5. Lancer les specs

```bash
bundle exec rspec spec/controllers/api/v1/outings_controller_spec.rb spec/models/outing_spec.rb
RAILS_ENV=test bin/d bundle exec rspec spec/...      # via Docker
```

- Base de test : `entourage-test` (URL dans `.env.test`, non versionné). Préparation : `RAILS_ENV=test bundle exec rake db:drop db:create db:migrate`. La CI rejoue toutes les migrations depuis zéro, sans `db:schema:load` (`db/schema.rb` n'est pas fiable).
- Suite complète : environ 8 minutes, à lancer avant un merge plutôt qu'à chaque itération. Pour la paralléliser, utiliser des bases clonées (`entourage-test2`…) et une base Redis par processus.
- Toujours rapporter le résultat réel (`N examples, N failures, N pending`), jamais un résultat supposé.

## 6. Conception testable

Signaler (en `Mineur`, sauf si ça empêche de tester un comportement important) :

- logique métier dans un contrôleur ou un observer, impossible à tester sans requête : la déplacer dans un service ou un modèle ;
- appel direct à `Time.now`, `ENV`, `$server_community` ou un client externe au milieu d'une méthode : passer par un point d'injection ou une méthode stubbable ;
- effet de bord déclenché par un callback alors qu'un appel explicite suffirait ;
- job qui prend un objet au lieu d'un id.

## 7. Rendu

Constats `T-NN` au format commun, la ligne de statut du thème, et la commande exacte des specs à lancer pour la branche (elle alimente la section « Comment tester » du rapport). Proposer d'écrire les specs manquantes ; si la personne accepte, les écrire, les lancer et donner le résultat réel.
