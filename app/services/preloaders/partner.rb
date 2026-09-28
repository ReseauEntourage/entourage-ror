module Preloaders
  module Partner
    # une requête Following pour toute la page, au lieu d'une par partenaire (@see V1::PartnerSerializer#following)
    def self.preload_following partners, user:
      partners = partners.compact
      return if partners.empty?
      return unless user.is_a?(::User) && user.persisted?

      followed_partner_ids = ::Following.where(user: user, partner_id: partners.map(&:id).uniq, active: true).pluck(:partner_id).to_set

      partners.each do |partner|
        (partner.preloaded_following ||= {})[user.id] = followed_partner_ids.include?(partner.id)
      end
    end
  end
end
