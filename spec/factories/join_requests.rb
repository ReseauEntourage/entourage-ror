FactoryGirl.define do
  factory :join_request do
    association :user, factory: :pro_user
    association :joinable, factory: :entourage
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
        else raise 'Unhandled: %s:%s' % [joinable.community.slug, joinable.group_type]
        end
    end
  end

end
