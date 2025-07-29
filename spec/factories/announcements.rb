FactoryBot.define do
  factory :announcement do
    id { 1 }
    title { 'Une autre façon de contribuer.' }
    body { 'Entourage a besoin de vous pour continuer à accompagner les sans-abri.' }
    action { 'Aider' }
    url { 'https://blog.entourage.social/' }
    image_url { 'https://blog.entourage.social/' }
    icon { 'https://blog.entourage.social/' }
    webview { false }
    position { 2 }
    status { :active }
  end
end
