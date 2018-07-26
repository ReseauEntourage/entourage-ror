FactoryGirl.define do
  factory :join_request do
    transient do
      joinable_factory :entourage
    end

    association :user, factory: :pro_user
    joinable { association joinable_factory }
    status "pending"
    role :auto

    after(:build) do |join_request, _|
      joinable = join_request.joinable
      next unless join_request.role == 'auto' && joinable.present?
      join_request.role =
        case [joinable.community, joinable.group_type]
        when ['entourage', 'tour'          ] then 'member'
        when ['entourage', 'action'        ] then 'member'
        when ['pfp',       'private_circle'] then 'visitor'
        when ['pfp',       'conversation'  ] then 'participant'
        when ['pfp',       'neighborhood'  ] then 'member'
        when ['entourage', 'conversation'  ] then 'participant'
        else raise 'Unhandled: %s:%s' % [joinable.community.slug, joinable.group_type]
        end
    end
  end

end
