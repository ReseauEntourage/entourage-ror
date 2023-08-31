module V1
  class ContactSubscriptionSerializer < ActiveModel::Serializer
    attributes :email,
               :name,
               :profile,
               :subject,
               :message
  end
end
