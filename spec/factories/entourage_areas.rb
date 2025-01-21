FactoryBot.define do
  factory :entourage_area do
    postal_code { '44' }
    antenne { true }
    geo_zone { "Bretagne" }
    display_name { "Loire-Atlantique" }
    city { "Nantes" }
  end
end
