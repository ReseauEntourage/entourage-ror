FactoryBot.define do
  factory :tour_area do
    departement { '75000' }
    area { 'Paris' }
    status { 'active' }
    email { 'paris@paris.fr' }
  end
end
