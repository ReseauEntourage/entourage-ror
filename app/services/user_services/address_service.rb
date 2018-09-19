module UserServices
  class AddressService
    def initialize(user:, params:)
      @user = user
      @params = params.with_indifferent_access
      @callback = Callback.new
    end

    def update
      yield callback if block_given?

      if can_update?(params, [:place_name, :latitude, :longitude])
        fetch_google_place_details
      end

      address, success = self.class.update_address(user: user, params: params)

      if !success
        callback.on_failure.try(:call, user, address)
        return false
      end

      google_place_id_changed =
        address.previous_changes.keys.include?('google_place_id') &&
        address.google_place_id.present?

      if google_place_id_changed ||
         can_update?(address, [:postal_code, :country])
        AsyncService.new(self.class).update_with_google_place_details(address)
      end

      callback.on_success.try(:call, user, address)
      true
    end

    def self.update_with_google_place_details address
      address.update!(fetch_google_place_details(address.google_place_id))
    end

    private
    attr_reader :user, :params, :callback

    def self.update_address user:, params:
      address = user.address || Address.new

      begin
        ActiveRecord::Base.transaction do
          address.update!(params)
          if address.id != user.address_id
            user.update_column(:address_id, address.id)
          end
        end
        success = true
      rescue ActiveRecord::ActiveRecordError
        success = false
      end

      [address, success]
    end

    def fetch_google_place_details
      @params.merge! self.class.fetch_google_place_details(params[:google_place_id])
    end

    def self.fetch_google_place_details place_id
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

        latitude:  result.latitude,
        longitude: result.longitude,

        postal_code: postal_code,
        country:     country,

        google_place_id: result.place_id
      }
    end

    def can_update? record, attributes
      record[:google_place_id].present? &&
      attributes.any? { |p| record[p].blank? }
    end
  end
end
