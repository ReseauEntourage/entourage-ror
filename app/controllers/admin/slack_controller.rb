module Admin
  class SlackController < ActionController::Base
    before_action :parse_payload, only: [:message_action, :csv]
    before_action :authenticate!, only: [:message_action, :csv]

    def message_action
      callback_type, *callback_params = @payload['callback_id']&.split(':')
      return head :bad_request if [callback_type, callback_params.length] != ['entourage_validation', 1]

      entourage = Entourage.find callback_params[0]

      case @payload['actions'].first['value']
      when 'validate'
        entourage.update_attribute(:status, :open) unless entourage.status == :closed
        color  = :good
        icon   = :white_check_mark
        action = 'validé'
      when 'block'
        entourage.update_attribute(:status, :blacklisted) unless entourage.status == :suspended
        color  = :danger
        icon   = :no_entry_sign
        action = 'bloqué'
      else
        return head :bad_request
      end

      response = Experimental::EntourageSlack.payload entourage
      response[:attachments].first[:color] = color
      response[:attachments].last[:text] =
        "*:#{icon}: <@#{@payload['user']['name']}> a #{action} cette action*"

      render json: response
    end

    def entourage_links
      @entourage = Entourage.find params[:id]
      render layout: false
    end

    def csv
      return head :bad_request unless @payload['filename']

      document = Storage::Client.csv.url_for(key: @payload['filename'])

      send_data document.file.read, filename: document.name
    end

    private

    def parse_payload
      @payload = JSON.parse(params[:payload]) rescue {}
    end

    def authenticate!
      head :unauthorized if @payload['token'] != ENV['SLACK_APP_VERIFICATION_TOKEN']
    end
  end
end
