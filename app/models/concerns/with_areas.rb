module WithAreas
  extend ActiveSupport::Concern

  included do
    attribute :areas, :jsonb_set

    validates :areas, presence: true

    scope :for_areas, -> (area_slugs) {
      where('areas ?| array[%s]' % area_slugs.map { |a| ApplicationRecord.connection.quote(a) }.join(','))
    }

    before_validation do
      areas.reject!(&:blank?)
    end
  end
end
