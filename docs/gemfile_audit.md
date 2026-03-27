# Audit du Gemfile (Rails 7.1)

Ce document répertorie les librairies (gems) qui ne sont plus utiles ou qui devraient être mises à jour/remplacées par des alternatives plus modernes.

## 1. Librairies qui ne sont plus utiles (À supprimer)

| Gem | Raison | Alternative |
| --- | --- | --- |
| `rails_stdout_logging` | Rails 7.1 gère nativement la journalisation vers STDOUT via `config.logger = ActiveSupport::Logger.new(STDOUT)`. | Configuration native Rails |
| `turbolinks` | Turbolinks est obsolète. Rails utilise désormais Turbo (Hotwire). | `turbo-rails` |
| `rails-observers` | Le pattern Observer a été extrait de Rails et est considéré comme obsolète au profit des callbacks de modèles ou des services. | Callbacks / Services / Pub-Sub |
| `fakeredis` | Librairie ancienne et peu maintenue pour les tests Redis. | `mock_redis` ou un vrai Redis en Docker |
| `terser` | Bien qu'utile avec Sprockets, les applications modernes migrent vers `jsbundling-rails` avec `esbuild` ou `webpack`. | `esbuild` / `swc` |

## 2. Librairies à mettre à jour ou remplacer

| Gem | Recommandation | Justification |
| --- | --- | --- |
| `nexmo` | Remplacer par `vonage` | Nexmo a été racheté par Vonage. Le gem `nexmo` est en maintenance uniquement depuis 2021. |
| `active_model_serializers` | Remplacer par `blueprinter` ou `jsonapi-serializer` | AMS est un projet "mort" (stagnant). Les alternatives modernes sont beaucoup plus rapides et flexibles. |
| `momentjs-rails` | Remplacer par `date-fns`, `luxon` ou l'API native `Intl` | Moment.js est en mode maintenance. Il est lourd et ses objets sont mutables. |
| `mini_magick` | Envisager `ruby-vips` | `ruby-vips` est nettement plus rapide et consomme moins de mémoire que `mini_magick` (ImageMagick). |
| `google-api-client` | Mettre à jour (version 0.53 est très ancienne) | Les nouvelles API Google utilisent des gems spécifiques (ex: `google-apis-calendar_v3`) pour de meilleures performances. |
| `rpush` | Vérifier la version | S'assurer d'utiliser la v7.0+ pour la compatibilité avec les nouveaux protocoles Apple/Google. |

## 3. Améliorations de performance suggérées

*   **Migration vers Turbo :** Remplacer `turbolinks` par `turbo-rails` pour bénéficier des dernières améliorations de vitesse et de fonctionnalités (Turbo Frames, Turbo Streams).
*   **Modernisation du JS :** Passer de Sprockets à `importmap-rails` ou `jsbundling-rails` pour supprimer la dépendance à des gems "wrappers" comme `jquery-rails` ou `momentjs-rails`.
