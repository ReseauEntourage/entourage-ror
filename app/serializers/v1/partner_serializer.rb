module V1
  class PartnerSerializer < ActiveModel::Serializer
    attributes :id,
               :name,
               :large_logo_url,
               :small_logo_url,
               :description,
               :donations_needs,
               :volunteers_needs,
               :phone,
               :address,
               :postal_code,
               :website_url,
               :email,
               :default,
               :following

    def filter(keys)
      if scope[:full] == true
        keys -= [:postal_code]
      elsif scope[:minimal] == true
        keys = [:id, :name, :postal_code]
      else
        keys -= [:description, :donations_needs, :volunteers_needs, :phone, :address, :website_url, :email, :postal_code]
      end

      if scope[:following] != true
        keys -= [:following]
      end

      keys
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
  end
end
