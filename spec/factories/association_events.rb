FactoryBot.define do
  factory :association_event do
    association_event_source
    sequence(:source_uid) { |n| n.to_s }
    title { 'Café des parents' }
    starts_at { 1.day.from_now }
    ends_at { 1.day.from_now + 2.hours }
    location { 'Nantes' }
    is_free { true }
  end
end
