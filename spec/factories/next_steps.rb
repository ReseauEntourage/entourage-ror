FactoryBot.define do
  factory :next_step do
    association :user
    kind { 'smalltalk' }
    mode { 'segment' }
    segment { 'Contributeur' }
    segment_source { 'computed' }
    status { 'active' }
    first_displayed_at { Time.zone.now }
    expires_at { 3.days.from_now }
  end

  factory :next_step_interaction do
    association :user
    next_step { association :next_step, user: user }
    placement { 'hero' }
    kind { 'displayed' }
  end
end
