FactoryGirl.define do
  factory :category do
    sequence :name do |n|
      "Categorie #{n}"
    end
  end
end
