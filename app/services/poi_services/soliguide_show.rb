module PoiServices
  class SoliguideShow
    def self.get id
      format JSON.parse(get_response(id).body)
    end

    private

    SHOW_URI = "https://api.soliguide.fr/place/%s"

    def self.api_key
      Soliguide::API_KEY
    end

    def self.get_response id
      uri = URI(SHOW_URI % id)

      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri, {
        'Content-Type' => 'application/json',
        'Authorization' => api_key,
      })

        http.request(request)
      end
    end

    def self.format poi
      source_categories = poi['services_all'].map { |service| service['categorie'] }

      category_ids = source_categories.map {
        |cat_id| SoliguideFormatter::CATEGORIES_EQUIVALENTS[cat_id]
      }.compact.uniq

      {
        uuid: "s#{poi['lieu_id']}",
        source: :soliguide,
        source_url: "https://soliguide.fr/fiche/#{poi['seo_url']}",
        name: SoliguideFormatter.format_title(poi['name'], poi['entity']['name']),
        description: SoliguideFormatter.format_description(poi['description']),
        longitude: poi['location']['coordinates'][0].round(6),
        latitude: poi['location']['coordinates'][1].round(6),
        address: poi['address'].presence,
        phone: poi['entity']['phone'].presence,
        website: poi['entity']['website'].presence,
        email:poi['entity']['mail'].presence,
        audience: SoliguideFormatter.format_audience(poi['conditions'], poi['modalities']),
        category_ids: category_ids,
        source_category_id: source_categories.compact.first,
        source_category_ids: source_categories.compact.uniq,
        hours: SoliguideFormatter.format_hours(poi['newhours']),
        languages: poi['languages'].map { |l| SoliguideFormatter::ISO_LANGS[l.to_sym] }.compact.join(', ')
      }
    end
  end
end
