FactoryBot.define do
  factory :next_step_suggestion do
    suggestion_type { 'first_step' }
    target_profile { 'all' }
    min_engagement_level { 0 }
    max_engagement_level { 4 }
    title_template { 'Un événement a lieu près de chez vous' }
    reason_template { 'Parce que vous êtes dans votre quartier' }
    cta_label { 'Voir les détails' }
    cta_action { 'entourage://outings' }
    priority { 50 }
    valid_for_days { 7 }
    active { true }

    trait :reengagement do
      suggestion_type { 'reengagement' }
      title_template { 'Des choses se passent près de chez vous' }
    end

    trait :fallback do
      suggestion_type { 'fallback' }
      priority { 1 }
      title_template { 'Explorez ce qui se passe' }
    end
  end
end
