FactoryBot.define do
  factory :recommandation do
    user_goals { [:offer_help] }
    fragment { 0 }

    factory :recommandation_neighborhood do
      name { 'Voisinage' }
      instance { :neighborhood }
      action { :show }
      position_offer_help { 0 }
    end

    factory :recommandation_pois do
      name { 'Pois' }
      instance { :poi }
      action { :index }
      position_offer_help { 1 }
    end

    factory :recommandation_contribution do
      name { "Proposer de l'aide" }
      instance { :contribution }
      action { :new }
      position_offer_help { 2 }
    end

    factory :recommandation_webview do
      name { 'Webview' }
      instance { :webview }
      action { :show }
      fragment { 1 }
      position_offer_help { 0 }
    end
  end
end
