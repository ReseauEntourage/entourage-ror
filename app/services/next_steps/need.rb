module NextSteps
  # A need the engine answers before the segment rules. Today it comes from the
  # user's latest open solicitation of less than 30 days; the chat will be able
  # to build one too, hence a plain value rather than a Solicitation.
  Need = Struct.new(:solicitation_id, :title, :sections, :latitude, :longitude, :source, :created_at, keyword_init: true)

  class Need
    MAX_AGE = 30.days

    def self.for user, now: Time.zone.now
      solicitation = Solicitation
        .where(user_id: user.id, status: :open)
        .where('entourages.created_at > ?', now - MAX_AGE)
        .reorder(created_at: :desc)
        .first

      return unless solicitation

      new(
        solicitation_id: solicitation.id,
        title: solicitation.title,
        sections: solicitation.section_list,
        latitude: solicitation.latitude,
        longitude: solicitation.longitude,
        source: 'solicitation',
        created_at: solicitation.created_at
      )
    end
  end
end
