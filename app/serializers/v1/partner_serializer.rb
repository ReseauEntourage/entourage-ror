module V1
  class PartnerSerializer < ActiveModel::Serializer
    attributes :id,
               :name,
               :large_logo_url,
               :small_logo_url,
               :description,
               :phone,
               :address,
               :website_url,
               :email,
               :default

    def filter(keys)
      if scope[:full] == true
        keys
      else
        keys - [:description, :phone, :address, :website_url, :email]
      end
    end

    OPTIONAL_ATTRIBUTES = [:phone, :address, :website_url, :email].freeze

    # return blank optional attributes as nil
    # to simplify front-end handling
    OPTIONAL_ATTRIBUTES.each do |attr_name|
      define_method(attr_name) { object[attr_name].presence }
    end

    def default
      # perf optimization for the feed: prevent n+1 request
      if scope[:user].default_user_partners.loaded?
        scope[:user].default_user_partners.any? { |up| up.partner_id == object.id }
      else
        scope[:user].partners.include?(object)
      end
    end
  end
end
