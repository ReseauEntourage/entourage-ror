module V1
  class NewsletterSubscriptionSerializer < ActiveModel::Serializer
    attributes :email,
               :active
  end
end