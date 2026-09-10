FactoryBot.define do
  factory :open_agenda_event do
    open_agenda_source
    sequence(:source_event_uid) { |n| n }
    title { 'Café des parents' }
    starts_at { 1.day.from_now }
    ends_at { 1.day.from_now + 2.hours }
    location { 'Nantes' }
    is_free { true }
  end
end
