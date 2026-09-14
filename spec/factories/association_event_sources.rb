FactoryBot.define do
  factory :association_event_source do
    sequence(:name) { |n| "Agenda #{n}" }
    provider { 'open_agenda' }
    sequence(:agenda_uid) { |n| 10_000_000 + n }
    city { 'Nantes' }
    status { 'not_checked' }

    trait :hello_asso do
      provider { 'hello_asso' }
      agenda_uid { nil }
      sequence(:helloasso_organization_slug) { |n| "asso-#{n}" }
    end
  end
end
