module MatchingServices
  # explanation of a recommandation when the language model is disabled or fails: "À 800 m · le 22 octobre"
  module Explanation
    def self.for candidate
      parts = [distance(candidate), date(candidate), category(candidate)].compact

      parts.any? ? parts.join(' · ').upcase_first : 'Proche du sujet de votre action'
    end

    def self.distance candidate
      return 'en ligne' if candidate.type == 'outing' && candidate.record.online
      return unless candidate.distance_km
      return 'tout près' if candidate.distance_km < 0.1

      return "à #{(candidate.distance_km * 1000).round(-2).to_i} m" if candidate.distance_km < 1

      "à #{candidate.distance_km.round(1).to_s.sub('.', ',').delete_suffix(',0')} km"
    end

    def self.date candidate
      return unless candidate.type == 'outing'
      return unless starts_at = Candidates.starts_at(candidate.record)

      "le #{I18n.l(starts_at.to_date, format: '%-d %B', locale: :fr)}"
    end

    def self.category candidate
      return unless candidate.category_match

      case candidate.type
      when 'contribution', 'solicitation' then 'même catégorie que votre action'
      when 'outing', 'neighborhood' then 'correspond à vos centres d\'intérêt'
      when 'poi' then 'lieu adapté à votre demande'
      when 'resource' then 'ressource recommandée pour votre profil'
      end
    end
  end
end
