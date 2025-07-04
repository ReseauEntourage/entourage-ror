module Preloaders
  module JoinRequest
    def self.preload_siblings(join_requests, sibling_scope: nil)
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

    def self.preload_last_chat_message(join_requests, message_scope: nil)
      join_requests = join_requests.to_a
      return if join_requests.empty?

      join_keys = join_requests.map { |jr| [jr.joinable_type, jr.joinable_id] }.uniq

      # Construire condition sécurisée pour les chat_messages
      conditions_sql = join_keys.map do |type, id|
        sanitize_sql(["(messageable_type = ? AND messageable_id = ?)", type, id])
      end.join(" OR ")

      # Appliquer un scope sur les messages si fourni
      base_scope = ChatMessage.where(conditions_sql).order(:created_at)
      scoped_messages = message_scope ? base_scope.merge(message_scope) : base_scope

      # Charger tous les messages
      all_messages = scoped_messages.to_a
      messages_by_key = all_messages.group_by { |msg| [msg.messageable_type, msg.messageable_id] }

      # Injecter le dernier message pour chaque join_request
      join_requests.each do |jr|
        messages = messages_by_key[[jr.joinable_type, jr.joinable_id]] || []
        last_message = messages.last  # Le dernier car on a trié par created_at

        jr.last_chat_message = last_message
      end
    end

    def self.sanitize_sql(condition)
      ActiveRecord::Base.send(:sanitize_sql_array, condition)
    end
  end
end
