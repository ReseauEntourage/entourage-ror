module Api
  module V1
    module Users
      class AddressesController < Api::V1::BaseController
        before_filter :enforce_id

        def create_or_update
          updater = UserServices::AddressService.new(
            user: current_user,
            position: params[:position],
            params: address_params
          )

          updater.update do |on|
            on.success do |user, address|
              render status: 200, json: {
                address: ::V1::AddressSerializer.new(address, root: false)
              }
              # TODO
              # firebase_properties: UserService.firebase_properties(user.reload)
            end

            on.failure do |user, address|
              render_error(
                code: "CANNOT_UPDATE_ADDRESS",
                message: address.errors.full_messages +
                user.errors.full_messages,
                status: 400
              )
            end
          end
        end

        def destroy
          position = params[:position]&.to_i
          if position.blank? || position < 2 || position > Address::USER_MAX_ADDRESSES
            return render_error(
                code: "CANNOT_DELETE_ADDRESS",
                message: "Invalid address id",
                status: 400
            )
          end
          address = current_user.addresses.find_by(position: position)
          address.destroy! if address
          head :no_content
        end

        private

        def address_params
          params.require(:address).permit(:place_name, :latitude, :longitude, :street_address, :google_place_id)
        end

        def enforce_id
          unless params[:user_id] == 'me'
            render_error(code: "UNAUTHORIZED", message: "You can only update your own address.", status: 401)
          end
        end
      end
    end
  end
end
