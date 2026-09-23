# Détection des requêtes N+1 par "mise à l'échelle" :
#
#   1. on crée un petit jeu de données (populate(1)) et on fait une requête de chauffe ;
#   2. on mesure le nombre de requêtes SQL d'un appel ;
#   3. on ajoute des données (populate(n)) et on mesure à nouveau ;
#   4. le nombre de requêtes doit rester identique : s'il augmente avec le nombre
#      d'éléments retournés, c'est qu'une requête est faite par élément (N+1).
#
# Chaque action index de api/v1 et admin doit avoir son test, dans spec/n_plus_one au même
# chemin que le contrôleur : spec/n_plus_one/coverage_spec.rb le vérifie.
#
# Usage (controller spec) :
#
#   it_behaves_like 'an endpoint without N+1 queries' do
#     def populate(count)
#       count.times { create :outing, participants: [user, create(:public_user)] }
#     end
#
#     def perform_request
#       get :index, params: { token: user.token }
#     end
#
#     # garde-fou : vérifie que les éléments créés sont bien retournés
#     def returned_items_count
#       JSON.parse(response.body)['outings'].size
#     end
#   end
#
# Un N+1 connu mais pas encore corrigé se déclare avec `pending:` : le test reste
# exécuté et échouera ("expected pending but passed") dès que le N+1 sera corrigé.
#
# Les requêtes servies par le cache SQL de Rails ne sont pas comptées (comme en
# production) : `populate` doit donc donner des valeurs distinctes à chaque élément
# (logo, département, image…), sinon un N+1 sur des valeurs identiques reste invisible.
#
#   it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 sur users (serializer)' do
#
# `N_PLUS_ONE_VERBOSE=1 bundle exec rspec spec/n_plus_one` affiche le nombre de requêtes
# mesuré pour chaque exemple.
#
# `populate(count)` doit créer `count` éléments supplémentaires qui apparaîtront dans la
# réponse, avec des associations distinctes (auteur, image, membres…) pour que chaque
# élément déclenche ses propres chargements.
module NPlusOneHelper
  IGNORED_QUERY_NAMES = %w[SCHEMA TRANSACTION CACHE].freeze
  IGNORED_SQL = /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE SAVEPOINT|SHOW|SET)\b/i

  # Retourne la liste des requêtes SQL exécutées pendant le bloc
  def collect_queries(&block)
    queries = []

    callback = lambda do |*, payload|
      next if payload[:cached]
      next if IGNORED_QUERY_NAMES.include?(payload[:name])
      next if payload[:sql] =~ IGNORED_SQL

      queries << payload[:sql]
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)

    queries
  end

  # Normalise une requête pour regrouper celles qui ne diffèrent que par leurs valeurs
  def normalize_query(sql)
    sql
      .gsub(/\$\d+/, '?')
      .gsub(/'(?:[^']|'')*'/, '?')
      .gsub(/\b\d+(\.\d+)?\b/, '?')
      .gsub(/\((\?,\s*)*\?\)/, '(?)')
      .gsub(/\s+IN\s+\(\?\)/i, ' = ?')
      .squish
  end

  # Remet à zéro ce qui, d'un appel à l'autre, pourrait masquer des requêtes :
  # - une instance de contrôleur neuve (variables mémoïsées par un appel précédent) ;
  # - le cache de BatchLoader (lazy_relationship des serializers) et les CurrentAttributes
  #   (préchargements limités à la requête), que les middlewares et l'executor Rails remettent
  #   à zéro à chaque requête, mais qui ne sont pas traversés en controller spec.
  def reset_request_state
    @controller = @controller.class.new if defined?(@controller) && @controller
    BatchLoader::Executor.clear_current if defined?(BatchLoader::Executor)
    ActiveSupport::CurrentAttributes.reset_all
  end

  # Requêtes SQL d'un appel, dans un état "requête HTTP neuve"
  def measure_queries
    reset_request_state
    collect_queries { yield }
  end

  def n_plus_one_report(small, large)
    small_counts = small.map { |q| normalize_query(q) }.tally
    large_counts = large.map { |q| normalize_query(q) }.tally

    extra = large_counts.filter_map do |sql, count|
      diff = count - small_counts.fetch(sql, 0)
      "  +#{diff} × #{sql.truncate(300)}" if diff > 0
    end

    "#{small.size} requêtes avec le petit jeu de données, #{large.size} avec le grand.\n" \
      "Requêtes supplémentaires :\n#{extra.join("\n")}"
  end
end

RSpec.shared_examples 'an endpoint without N+1 queries' do |scale: 3, pending: nil|
  include NPlusOneHelper

  it "keeps a constant number of SQL queries when the number of returned items grows (x#{scale})" do
    populate(1)
    reset_request_state
    perform_request # chauffe : caches applicatifs, options, etc.
    expect(response.status).to be_between(200, 299)

    small = measure_queries { perform_request }
    small_items = returned_items_count if respond_to?(:returned_items_count)

    populate(scale)
    large = measure_queries { perform_request }

    expect(response.status).to be_between(200, 299)
    expect(returned_items_count).to be > small_items if respond_to?(:returned_items_count)

    if ENV['N_PLUS_ONE_VERBOSE']
      puts "[N+1] #{RSpec.current_example.full_description} : #{small.size} -> #{large.size} requêtes"
      puts n_plus_one_report(small, large).lines.drop(1).join if large.size > small.size
    end

    # N+1 connu : seule l'assertion finale est attendue en échec (une erreur de setup
    # ou de réponse ci-dessus reste une vraie erreur)
    pending(pending) if pending

    expect(large.size).to be <= small.size, n_plus_one_report(small, large)
  end
end
