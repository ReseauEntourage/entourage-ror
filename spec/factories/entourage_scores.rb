FactoryBot.define do
  factory :entourage_score do
    entourage
    association :user, factory: :public_user
    base_score { 1.5 }
    final_score { 1.5 }
  end
end
