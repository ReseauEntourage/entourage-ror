module Admin
  class SlackController < Admin::BaseController
    skip_before_action :verify_authenticity_token
    before_action :parse_payload, only: [:message_action]
    skip_before_action :authenticate_admin!, only: [:message_action, :entourage_links]
    before_action :authenticate_slack!, only: [:message_action]

    def message_action
      callback_type, *callback_params = @payload['callback_id']&.split(':')
      return head :bad_request if [callback_type, callback_params.length] != ['entourage_validation', 1]
      return head :bad_request unless @payload['actions']

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

    # no option: render template
    # option display: display csv
    # option download: download csv
    def csv
      @filename = params['filename']
      @option = params['option']

      return head :bad_request unless @filename

      @url = Storage::Client.csv.url_for(key: @filename)

      if @option && @option == 'display'
        return redirect_to @url
      elsif @option && @option == 'download'
        return send_data(
          open(@url).read,
          filename: "#{@filename}.csv",
          type: "application/csv",
          disposition: 'inline',
          stream: 'true',
          buffer_size: '4096'
        )
      end

      render layout: false
    end

    private

    def parse_payload
      @payload = JSON.parse(params[:payload]) rescue {}
    end

    def authenticate_slack!
      puts "authenticate_slack! #{@payload.inspect}"
      unless @payload['token'] && @payload['token'] == ENV['SLACK_APP_VERIFICATION_TOKEN']
        login_error "Votre action nécessite une authentification Slack pour accéder à cette page"
      end
    end
  end
end
