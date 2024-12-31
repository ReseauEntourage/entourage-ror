FactoryBot.define do
  factory :openai_assistant do
    api_key { "API_KEY" }
    assistant_id { "OPENAI_ASSISTANT_ID" }
    module_type { "offense" }
    prompt { "please do something" }
  end
end
