FactoryBot.define do
  factory :user_recommandation do
    name { "Proposer de l'aide" }
    action { :create }
    instance { :contribution }
  end
end
