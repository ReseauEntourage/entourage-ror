module Admin
  class SlackController < ActionController::Base
    before_action :parse_payload, only: [:message_action, :user_unblock]
    before_action :authenticate_slack!, only: [:message_action]
    before_action :authenticate_slack_user_unblock!, only: [:user_unblock]
    before_action :authenticate_admin!, only: [:csv]

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

    def user_unblock
      callback_type, *callback_params = @payload['callback_id']&.split(':')
      return head :bad_request if [callback_type, callback_params.length] != ['user_unblock', 1]
      return head :bad_request unless @payload['actions']
      return head :bad_request unless @payload['actions'].first['value'] == 'unblock'

      User.find(callback_params[0]).unblock!(OpenStruct.new(id: nil), 'auto')

      response = UserServices::Unblock.payload(callback_params[0])
      response[:attachments].first[:color] = :good
      response[:attachments].last[:text] = "*:#{:white_check_mark}: <@#{@payload['user']['name']}> a débloqué l'utilisateur*"

      render json: response
    end

    private

    def parse_payload
      @payload = JSON.parse(params[:payload]) rescue {}
    end

    def authenticate_slack!
      head :unauthorized if @payload['token'] != ENV['SLACK_APP_VERIFICATION_TOKEN']
    end

    def authenticate_slack_user_unblock!
      head :unauthorized if @payload['token'] != UserServices::Unblock.webhook('token')
    end

    def authenticate_admin!
      head :unauthorized unless current_admin
    end

    def current_admin
      return if session[:admin_user_id].nil?
      @current_admin ||= User.where(id: session[:admin_user_id]).first
    end
  end
end
