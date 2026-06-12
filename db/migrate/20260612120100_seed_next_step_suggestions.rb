class SeedNextStepSuggestions < ActiveRecord::Migration[7.1]
  def up
    suggestions = [
      {
        suggestion_type: 'first_step',
        target_profile: 'offer_help',
        min_engagement_level: 0,
        max_engagement_level: 1,
        title_template: 'Un Papotage solidaire a lieu près de chez vous cette semaine',
        reason_template: 'Parce que vous êtes dans votre quartier et que des voisins y vont déjà',
        cta_label: 'Voir les détails',
        cta_action: 'entourage://outings',
        priority: 100,
        valid_for_days: 7,
        active: true
      },
      {
        suggestion_type: 'first_step',
        target_profile: 'ask_for_help',
        min_engagement_level: 0,
        max_engagement_level: 1,
        title_template: 'Un événement gratuit a lieu près de chez vous — venez comme vous êtes',
        reason_template: 'Parce que des gens de votre quartier y participent',
        cta_label: "Voir l'événement",
        cta_action: 'entourage://outings',
        priority: 100,
        valid_for_days: 7,
        active: true
      },
      {
        suggestion_type: 'event',
        target_profile: 'all',
        min_engagement_level: 1,
        max_engagement_level: 2,
        title_template: 'Un événement dans votre zone a lieu dans les 7 prochains jours',
        reason_template: 'Parce que vous avez participé à des activités similaires',
        cta_label: 'Voir les événements',
        cta_action: 'entourage://outings',
        priority: 80,
        valid_for_days: 7,
        active: true
      },
      {
        suggestion_type: 'connection',
        target_profile: 'offer_help',
        min_engagement_level: 1,
        max_engagement_level: 3,
        title_template: 'Un voisin cherche à créer du lien dans votre quartier',
        reason_template: 'Parce que vous habitez la même zone',
        cta_label: 'Dire bonjour',
        cta_action: 'entourage://actions',
        priority: 70,
        valid_for_days: 7,
        active: true
      },
      {
        suggestion_type: 'group',
        target_profile: 'all',
        min_engagement_level: 2,
        max_engagement_level: 3,
        title_template: 'Rejoignez un groupe actif près de chez vous',
        reason_template: 'Parce que des voisins s\'y retrouvent régulièrement',
        cta_label: 'Voir les groupes',
        cta_action: 'entourage://neighborhoods',
        priority: 60,
        valid_for_days: 7,
        active: true
      },
      {
        suggestion_type: 'reengagement',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 3,
        title_template: 'Des choses se passent près de chez vous cette semaine',
        reason_template: 'Des voisins que vous connaissez y participent',
        cta_label: 'Voir ce qui se passe',
        cta_action: 'entourage://home',
        priority: 50,
        valid_for_days: 7,
        active: true
      },
      {
        suggestion_type: 'fallback',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 3,
        title_template: 'Explorez ce qui se passe près de chez vous',
        reason_template: nil,
        cta_label: 'Découvrir',
        cta_action: 'entourage://home',
        priority: 1,
        valid_for_days: 7,
        active: true
      }
    ]

    now = Time.zone.now
    suggestions.each do |attrs|
      NextStepSuggestion.create!(attrs.merge(created_at: now, updated_at: now))
    end
  end

  def down
    NextStepSuggestion.delete_all
  end
end
