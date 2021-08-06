FactoryBot.define do
  factory :moderator_read do
    transient do
      moderatable_factory { :entourage }
    end
    moderatable { association moderatable_factory }

    # association :user, factory: :pro_user

    read_at { Time.now }
  end
end
