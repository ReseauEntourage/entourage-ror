module V1
  class PoiSerializer < ActiveModel::Serializer
    attribute :id,           if: :v1_list? || :default?
    attribute :name
    attribute :description,  unless: :v2_list?
    attribute :longitude
    attribute :latitude
    attribute :adress,       if: :v1_list? || :default?
    attribute :phone
    attribute :website,      unless: :v2_list?
    attribute :email,        unless: :v2_list?
    attribute :audience,     unless: :v2_list?
    attribute :validated,    if: :v1_list? || :default?
    attribute :category_id,  unless: :v2?
    attribute :partner_id
    attribute :address,      unless: :v1_list?
    attribute :hours,        if: :v2? || :default?
    attribute :languages,    if: :v2? || :default?
    attribute :source_url,   if: :v2? || :default?
    attribute :uuid,         unless: :v1_list?
    attribute :source,       if: :v2? || :default?
    attribute :category_ids, if: :v2? || :default?

    has_one :category, serializer: V1::CategorySerializer, if: :v1_list? || :default?

    def v1_list?; version == :v1_list; end
    def v2_list?; version == :v2_list; end
    def v2?; version == :v2; end
    def default?; !v1_list? && !v2_list? && !v2?; end

    def category_id
      case version
      when :v1_list
        {
          40 => 4,
          41 => 4,
          42 => 4,
          43 => 4,
          61 => 6,
          62 => 6
        }[object.category_id] || object.category_id
      else
        category_ids.any? ? category_ids.first : 0
      end
    end

    def category_ids
      @category_ids ||= CategoryPoi.where(poi_id: object.id).pluck(:category_id)
    end

    private

    def version
      scope&.[](:version)
    end
  end
end
