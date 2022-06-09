FactoryBot.define do
  factory :recommandation do
    factory :recommandation_profile do
      name { 'Profil' }
      image_url { nil }
      profile { :offer_help }
      instance { :profile }
      action { :show }
      url { nil }
    end

    factory :recommandation_neighborhood do
      name { 'Voisinage' }
      image_url { nil }
      profile { :offer_help }
      instance { :neighborhood }
      action { :show }
      url { nil }
    end

    factory :recommandation_pois do
      name { 'Voisinage' }
      image_url { nil }
      profile { :offer_help }
      instance { :poi }
      action { :index }
      url { nil }
    end
  end
end
