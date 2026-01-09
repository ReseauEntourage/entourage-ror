class PopulatePostalCodeOnPartners < ActiveRecord::Migration[7.1]
  def up
    Partner.all.pluck(:id).each do |partner_id|
      partner = Partner.find(partner_id)

      next unless partner.latitude && partner.longitude

      postal_code = EntourageServices::GeocodingService.search_postal_code(
        partner.latitude,
        partner.longitude
      )

      partner.update(postal_code: postal_code.second)
    end
  end
end
