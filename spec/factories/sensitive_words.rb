FactoryBot.define do
  factory :sensitive_word do
    sequence(:raw) { |n| "mot#{n}" }
    category { 'Insulte' }
    match_type { 'exact' }
    scope { 'all' }
  end
end
