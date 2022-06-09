FactoryBot.define do
  factory :recommandation do
    profile { :offer_help }
    user_goals { [:offer_help] }
    areas { [:dep_75] }

    factory :recommandation_profile do
      name { 'Profil' }
      instance { :profile }
      action { :show }
    end

    factory :recommandation_neighborhood do
      name { 'Voisinage' }
      profile { :offer_help }
      instance { :neighborhood }
      action { :show }
    end

    factory :recommandation_pois do
      name { 'Voisinage' }
      profile { :offer_help }
      instance { :poi }
      action { :index }
    end
  end
end
