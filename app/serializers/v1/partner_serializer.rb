module V1
  class PartnerSerializer < ActiveModel::Serializer
    attributes :id,
               :name,
               :large_logo_url,
               :small_logo_url,
               :default

    def default
      scope[:user].partners.include?(object)
    end
  end
end