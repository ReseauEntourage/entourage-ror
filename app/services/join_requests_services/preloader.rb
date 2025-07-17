module JoinRequestsServices
  module Preloader
    def self.preload_siblings(join_requests, sibling_scope: nil)
      join_requests = join_requests.to_a
      return if join_requests.empty?

      join_keys = join_requests.map { |jr| [jr.joinable_type, jr.joinable_id] }.uniq

      # Construire condition sécurisée
      conditions_sql = join_keys.map do |type, id|
        sanitize_sql(["(joinable_type = ? AND joinable_id = ?)", type, id])
      end.join(" OR ")

      # Appliquer un scope sur les siblings si fourni
      base_scope = JoinRequest.where(conditions_sql)
      scoped_siblings = sibling_scope ? base_scope.merge(sibling_scope) : base_scope

      # Charger les résultats
      all_siblings = scoped_siblings.to_a
      siblings_by_key = all_siblings.group_by { |jr| [jr.joinable_type, jr.joinable_id] }

      # Injecter les siblings filtrés
      join_requests.each do |jr|
        siblings = (siblings_by_key[[jr.joinable_type, jr.joinable_id]] || []).reject { |s| s.id == jr.id }
        jr.define_singleton_method(:siblings) { siblings }
      end
    end

    def self.sanitize_sql(condition)
      ActiveRecord::Base.send(:sanitize_sql_array, condition)
    end
  end
end
