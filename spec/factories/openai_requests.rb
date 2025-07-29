FactoryBot.define do
  factory :openai_request do
    instance { association :chat_message }
    instance_class  { 'ChatMessage' }
    openai_assistant_id { 'OPENAI_ASSISTANT_ID' }
    openai_thread_id { 'OPENAI_THREAD_ID' }
    module_type { 'offense' }
  end
end
