module V1
  class PartnerSerializer < ActiveModel::Serializer
    attributes :id, :name

    attribute :postal_code, if: :minimal?

    attribute :description, if: :full?
    attribute :donations_needs, if: :full?
    attribute :volunteers_needs, if: :full?
    attribute :phone, if: :full?
    attribute :address, if: :full?
    attribute :website_url, if: :full?
    attribute :email, if: :full?

    attribute :image_url, unless: :minimal?
    attribute :default, unless: :minimal?

    attribute :following, if: :following?

    def full?
      scope[:full] == true
    end

    def minimal?
      scope[:minimal] == true
    end

    def following?
      return false if minimal?
      scope[:following] == true
    end

    OPTIONAL_ATTRIBUTES = [:phone, :address, :website_url, :email].freeze

    # return blank optional attributes as nil
    # to simplify front-end handling
    OPTIONAL_ATTRIBUTES.each do |attr_name|
      define_method(attr_name) { object[attr_name].presence }
    end

    def default
      return true
    end

    def following
      Following.where(user: scope[:user], partner_id: object.id, active: true).exists?
    end
  end
end
