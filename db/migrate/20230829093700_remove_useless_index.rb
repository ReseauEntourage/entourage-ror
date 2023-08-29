class AddIndexToEntouragesMetadataDatesId < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
    DROP INDEX IF EXISTS public.index_chat_messages_on_content;
    DROP INDEX IF EXISTS public.index_inapp_notifications_on_displayed_at;  
    DROP INDEX IF EXISTS public.index_user_joinable_on_join_requests;
    SQL
    #remove_index :chat_messages, :content
    #remove_index :inapp_notifications, :displayed_at
    #remove_index :join_requests, [:user_id, :joinable_id, :joinable_type, :status], name: "index_user_joinable_on_join_requests"
  end

  def down
    execute <<-SQL
    CREATE INDEX IF NOT EXISTS index_chat_messages_on_content ON public.chat_messages ("content");
    CREATE INDEX IF NOT EXISTS index_inapp_notifications_on_displayed_at ON public.inapp_notifications USING btree (displayed_at);
    CREATE INDEX IF NOT EXISTS index_user_joinable_on_join_requests ON public.join_requests USING btree (user_id, joinable_id, joinable_type, status);
    SQL
    #add_index :chat_messages, :content, opclass: :gin_trgm_ops, using: :gin
    #add_index :inapp_notifications, :displayed_at
    #add_index :join_requests, [:user_id, :joinable_id, :joinable_type, :status], name: "index_user_joinable_on_join_requests"
  end
end
