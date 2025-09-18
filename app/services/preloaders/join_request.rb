module Preloaders
  module JoinRequest
    def self.preload_siblings join_requests, sibling_scope: nil
      join_requests = join_requests.to_a
      return if join_requests.empty?

      join_keys = join_requests.map { |jr| [jr.joinable_type, jr.joinable_id] }.uniq

      # Construire condition sécurisée
      conditions_sql = join_keys.map do |type, id|
        sanitize_sql(["(joinable_type = ? AND joinable_id = ?)", type, id])
      end.join(" OR ")

      # Appliquer un scope sur les siblings si fourni
      base_scope = ::JoinRequest.where(conditions_sql)
      scoped_siblings = sibling_scope ? base_scope.merge(sibling_scope) : base_scope

      # Charger les résultats
      all_siblings = scoped_siblings.to_a
      siblings_by_key = all_siblings.group_by { |jr| [jr.joinable_type, jr.joinable_id] }

      # Injecter les siblings filtrés
      join_requests.each do |jr|
        siblings = (siblings_by_key[[jr.joinable_type, jr.joinable_id]] || []).reject { |s| s.id == jr.id }
        jr.siblings = siblings
      end
    end

    def self.preload_joinable join_requests
      join_requests = join_requests.to_a
      return if join_requests.empty?

      # Transforme join_requests en :
      # { "Entourage" => { id => <Entourage>, id => <Entourage> }, "Smalltalk" => { id => <Smalltalk>, id => <Smalltalk> } }
      joinables = join_requests.each_with_object(Hash.new { |h, k| h[k] = [] }) do |join_request, h|
        h[join_request.joinable_type] << join_request.joinable_id
      end.transform_values!(&:uniq).to_h do |klass, ids|
        [klass, klass.constantize.where(id: ids).index_by(&:id)]
      end

      join_requests.each do |join_request|
        join_request.joinable = joinables[join_request.joinable_type][join_request.joinable_id]
      end
    end

    def self.preload_image join_requests, scope: nil
      join_requests = join_requests.to_a
      return if join_requests.empty?

      # get outings
      outings = join_requests.map do |join_request|
        next unless join_request.outing?

        join_request.joinable
      end.compact.uniq

      # populate outings with images
      outings.tap do |o|
        Preloaders::Outing.preload_images(o, scope: scope)
      end

      outings = outings.index_by(&:id)

      # populate join_requests with imageable outings
      join_requests.each do |join_request|
        next unless join_request.outing?
        next unless outings.has_key?(join_request.joinable_id)

        join_request.joinable = outings[join_request.joinable_id]
      end
    end

    def self.sanitize_sql condition
      ActiveRecord::Base.send(:sanitize_sql_array, condition)
    end
  end
end
