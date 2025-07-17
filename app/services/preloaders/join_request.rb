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

      # Générer la table virtuelle VALUES pour jointure
      values_clause = join_keys.map do |type, id|
        ActiveRecord::Base.send(:sanitize_sql_array, ["(?, ?)", type, id])
      end.join(", ")
      values_table = "(VALUES #{values_clause}) AS keys(messageable_type, messageable_id)"

      # Récupérer 1 message par messageable via DISTINCT ON
      ranked_messages = ChatMessage
        .select("DISTINCT ON (chat_messages.messageable_type, chat_messages.messageable_id) chat_messages.*")
        .joins("JOIN #{values_table} ON chat_messages.messageable_type = keys.messageable_type AND chat_messages.messageable_id = keys.messageable_id")
        .merge(message_scope || ChatMessage.all)
        .order("chat_messages.messageable_type, chat_messages.messageable_id, chat_messages.created_at DESC")

      messages_by_key = ranked_messages.index_by { |msg| [msg.messageable_type, msg.messageable_id] }

      join_requests.each do |jr|
        jr.last_chat_message = messages_by_key[[jr.joinable_type, jr.joinable_id]]
      end
    end


    def self.sanitize_sql(condition)
      ActiveRecord::Base.send(:sanitize_sql_array, condition)
    end
  end
end
