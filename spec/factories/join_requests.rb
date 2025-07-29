FactoryBot.define do
  factory :join_request do
    transient do
      joinable_factory { :entourage }
    end

    association :user, factory: :pro_user
    joinable { association joinable_factory }
    status { 'pending' }
    role { :auto }

    after(:build) do |join_request, _|
      joinable = join_request.joinable

      next unless join_request.role == 'auto' && joinable.present?

      join_request.role = joinable.is_a?(Neighborhood) || joinable.is_a?(Smalltalk) ? 'member' :
        case joinable.group_type
          when 'action' then 'member'
          when 'outing' then 'participant'
          when 'conversation' then 'participant'
          when 'group' then 'member'
        else raise 'Unhandled: %s:%s' % [joinable.group_type]
        end
    end

    after(:create) do |join_request, _|
      group = join_request.joinable
      group.update_column(:number_of_people, group.join_requests.accepted.count) unless join_request.neighborhood?
    end
  end

end
