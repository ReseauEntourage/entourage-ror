FactoryBot.define do
  factory :user_recommandation do
    name { "Proposer de l'aide" }
    action { :new }
    instance_type { :Contribution }
  end
end
