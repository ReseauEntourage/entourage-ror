FactoryBot.define do
  factory :organization do
    sequence :name do |n|
      "Association #{n}"
    end
    sequence :description do |n|
      "Association description"
    end
    sequence :phone do |n|
      "+336%08i" % n
    end
    sequence :address do |n|
      "#{n} avenue des Champs Elysées 75008 Paris France"
    end
    test_organization { false }
  end
end
