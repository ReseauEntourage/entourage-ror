FactoryBot.define do
  factory :email_category do
    sequence(:name) { |n| "test_category_#{n}" }
    sequence(:description) { |n| "catégorie de test n. #{n}" }
    after(:create) { EmailPreferencesService.reload_categories }
  end
end
