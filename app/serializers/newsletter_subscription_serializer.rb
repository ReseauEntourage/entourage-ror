class NewsletterSubscriptionSerializer < ActiveModel::Serializer
  attributes :email,
             :active
end