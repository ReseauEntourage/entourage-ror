module V0
  class NewsletterSubscriptionSerializer < ActiveModel::Serializer
    attributes :email,
               :active
  end
end
