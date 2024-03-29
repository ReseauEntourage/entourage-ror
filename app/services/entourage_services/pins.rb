module EntourageServices
  class Pins
    def self.find user, types
      return [] if user.community != :entourage

      pinned = []

      if (types.nil? || types.any? { |t| t.starts_with?('ask_for_help_') || t.starts_with?('contribution_') })
        pinned << self.pinned_for(user, types)
      end

      if (types.nil? || types.include?('outing'))
        pinned << self.outing_pinned(user)
      end

      pinned.uniq.compact
    end

    def self.pinned_for user, types = nil
      return if user.address.nil?
      return if user.address.country != 'FR'

      postal_code = user.address.postal_code.to_s
      departement = postal_code.first(2)

      Entourage.select(:id)
        .where(pin: true, group_type: :action)
        .where((["concat(entourage_type, '_', coalesce(display_category, 'other')) IN (?)", types] if types.present?))
        .where('pins ? :postal_code OR pins ? :departement',
          postal_code: postal_code,
          departement: departement
        )
        .map(&:id)
        .first
    end

    # Atelier solidaire : 1h pour comprendre comment aider les personnes SDF
    def self.outing_pinned(user)
      Entourage.select(:id)
        .where(status: :open, group_type: :outing, online: true)
        .map(&:id)
        .first
    end
  end
end
