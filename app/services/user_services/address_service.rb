module UserServices
  class AddressService
    def initialize(user:, position:, params:)
      @user = user
      @position = position
      @params = params
      @callback = Callback.new
    end

    def update
      yield callback if block_given?

      # if the address is a postal code and place_id is missing
      if [:postal_code, :country, :place_name].all? { |p| params[p].present? } &&
         params[:place_name] == params[:postal_code] &&
         params[:google_place_id].blank?

        handle_postal_code
      end

      fetched_google_place_details = false
      if can_update?(params, [:place_name, :latitude, :longitude])
        fetch_google_place_details
        fetched_google_place_details = true
      end

      address, success = self.class.update_address(user: user, position: position, params: params)

      if !success
        callback.on_failure.try(:call, user, address)
        return false
      end

      google_place_id_changed =
        address.previous_changes.keys.include?('google_place_id') &&
        address.google_place_id.present?

      if !fetched_google_place_details &&
         (google_place_id_changed ||
          can_update?(address, [:postal_code, :country]))
        AsyncService.new(self.class).update_with_google_place_details(address)
      end

      callback.on_success.try(:call, user, address)
      true
    end

    def synchronous_update
      yield callback if block_given?

      if params[:google_place_id].present?
        @params.merge! self.class.fetch_google_place_details(params[:google_place_id])

      elsif params[:latitude].present? && params[:longitude].present?
        country, postal_code, city = EntourageServices::GeocodingService.search_postal_code(
          params[:latitude], params[:longitude])

        @params.merge!(country: country, postal_code: postal_code)
      end

      address, success = self.class.update_address(user: user, position: position, params: params)

      if !success
        callback.on_failure.try(:call, user, address)
        return false
      end

      callback.on_success.try(:call, user, address)
      true
    end

    def self.update_with_google_place_details address
      address.update!(fetch_google_place_details(address.google_place_id))
    end

    def self.confirm_url user:, postal_code:
      Rails.application.routes.url_helpers.address_suggestion_api_v1_user_url(
        user, postal_code: postal_code,
        auto: 1,
        signature: SignatureService.sign(confirm_url_key(user_id: user.id, postal_code: postal_code)),
        host: API_HOST,
        protocol: (Rails.env.development? ? :http : :https)
      )
    end

    def self.confirm_url_key user_id:, postal_code:
      [user_id, postal_code].join(':')
    end

    private
    attr_reader :user, :position, :params, :callback

    def self.update_address user:, position:, params:
      if user.anonymous?
        address = Address.new(user_id: 0, position: position)
      else
        address = user.addresses.find_or_initialize_by(position: position)
      end

      if params[:google_place_id] != address.google_place_id
        address.postal_code = nil
        address.country = nil
        address.google_place_id = nil
      end

      address.assign_attributes(params)

      if user.anonymous?
        success = address.valid?
        user.address = address
      else
        success = address.save
      end

      [address, success]
    end

    def fetch_google_place_details
      @params.merge! self.class.fetch_google_place_details(params[:google_place_id])
    end

    def self.fetch_google_place_details place_id
      get_google_place_details(place_id).slice(:place_name, :latitude, :longitude, :postal_code, :country, :google_place_id)
    end

    def self.get_google_place_details place_id
      raise if place_id.blank?

      result = Geocoder.search(
        place_id,
        lookup: :google_places_details,
        params: {
          region: :fr,
          fields: [
            'geometry/location',
            :name,
            :address_components,
            :place_id,
            :formatted_address
          ].join(',')
        }
      ).first

      raise if result.nil?

      country, postal_code =
        if result.postal_code
          [result.country_code, result.postal_code]
        else
          EntourageServices::GeocodingService.search_approximate_postal_code(
            result.latitude, result.longitude)
        end

      {
        place_name: result.data['name'],
        formatted_address: result.data['formatted_address'],

        latitude:  result.latitude,
        longitude: result.longitude,

        city:        result.city,
        postal_code: postal_code,
        country:     country,

        google_place_id: result.place_id
      }
    end

    def can_update? record, attributes
      record[:google_place_id].present? &&
      attributes.any? { |p| record[p].blank? }
    end

    def handle_postal_code
      # delete possible blank value
      params.delete(:google_place_id)

      # try to find an existing entry for this postal code
      similar_address =
        Address.where("place_name = postal_code")
               .where(postal_code: params[:postal_code], country: params[:country])
               .first

      if similar_address
        params.reverse_merge! similar_address.attributes.symbolize_keys.slice(
          :latitude, :longitude, :google_place_id)
        return
      end

      # try to geocode
      result =
        Geocoder.search(
          nil, # no address
          lookup: :google,
          params: {
            components: {
              postal_code: params[:postal_code],
              country: params[:country]
            }.map { |c| c.join(':') }.join('|'),
            region: :fr # region bias, not a restriction
          }
        ).first

      if result
        params.reverse_merge!(
          latitude: result.latitude,
          longitude: result.longitude,
          google_place_id: result.data['place_id']
        )
      end
    end
  end
end
