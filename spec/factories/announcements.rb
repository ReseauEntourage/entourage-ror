FactoryGirl.define do
  factory :announcement do
    id 1
    title "Une autre façon de contribuer."
    body "Entourage a besoin de vous pour continuer à accompagner les sans-abri."
    action "Aider"
    association :author, factory: :public_user
  end
end
