require 'tasks/entourage_task'

namespace :entourage do
  task set_entourage_user_suggestion: :environment do
    EntourageServices::UserEntourageSuggestion.perform
  end

  task set_max_chat_message_created_at_in_batch: :environment do
    EntourageTask.set_max_chat_message_created_at_in_batch
  end

  task set_max_join_request_requested_at_in_batch: :environment do
    EntourageTask.set_max_join_request_requested_at_in_batch
  end
end
