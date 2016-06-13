namespace :data_migration do
  desc "create marketing referers"
  task create_marketing_referer: :environment do
    MarketingReferer.where(name: "entourage_bo").first_or_create!
    MarketingReferer.where(name: "monoprix").first_or_create!
  end
end