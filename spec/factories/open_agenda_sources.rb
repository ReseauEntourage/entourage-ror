FactoryBot.define do
  factory :open_agenda_source do
    sequence(:name) { |n| "Agenda #{n}" }
    sequence(:agenda_uid) { |n| 10_000_000 + n }
    city { 'Nantes' }
    status { 'not_checked' }
  end
end
