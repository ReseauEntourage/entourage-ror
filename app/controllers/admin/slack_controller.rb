module Admin
  class SlackController < Admin::BaseController
    before_action :parse_payload, only: [:message_action]
    skip_before_action :authenticate_admin!, only: [:message_action]
    before_action :authenticate_slack!, only: [:message_action]

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
      return head :bad_request unless params['filename']

      # why that? because download fails from slack without this instruction
      return redirect_to admin_slack_csv_url(filename: params['filename'], has_been_redirected: true) unless params['has_been_redirected'].present?

      send_data(
        open(Storage::Client.csv.url_for key: params['filename']).read,
        filename: "#{params['filename']}.csv",
        type: "application/csv",
        disposition: 'inline',
        stream: 'true',
        buffer_size: '4096'
      )
    end

    private

    def parse_payload
      @payload = JSON.parse(params[:payload]) rescue {}
    end

    def authenticate_slack!
      head :unauthorized if @payload['token'] != ENV['SLACK_APP_VERIFICATION_TOKEN']
    end
  end
end
