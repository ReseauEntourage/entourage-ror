module Admin
  class SlackController < ActionController::Base
    before_action :parse_payload, only: [:message_action, :user_unblock, :offensive_text]
    before_action :authenticate_slack!, only: [:message_action]
    before_action :authenticate_slack_user_unblock!, only: [:user_unblock]
    before_action :authenticate_slack_offensive_text!, only: [:offensive_text]
    before_action :authenticate_admin!, only: [:csv]

    def message_action
      callback_type, *callback_params = @payload['callback_id']&.split(':')
      username = @payload['user']['name']

      return head :bad_request unless callback_params.length == 1
      return head :bad_request unless ['entourage_validation', 'neighborhood_validation'].include?(callback_type)
      return head :bad_request unless @payload['actions']

      action = @payload['actions'].first['value']
      return head :bad_request unless ['validate', 'block'].include?(action)

      validation = Experimental::SlackValidation.new(callback_params[0], username)
      return head :bad_request unless validation.respond_to?(callback_type)

      render json: validation.send(callback_type, action)
    rescue => e
      return head :bad_request
    end

    def entourage_links
      @entourage = Entourage.find(params[:id])
      render layout: false
    end

    def neighborhood_links
      redirect_to edit_admin_neighborhood_path(params[:id])
    end

    # @deprecated related to airtable exports for Les Bonnes Ondes
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

      response = SlackServices::UnblockUser.new(user_id: callback_params[0]).payload
      response[:attachments].first[:color] = :good
      response[:attachments].last[:text] = "*:#{:white_check_mark}: <@#{@payload['user']['name']}> a débloqué l'utilisateur*"

      render json: response
    end

    def offensive_text
      callback_type, *callback_params = @payload['callback_id']&.split(':')
      return head :bad_request if [callback_type, callback_params.length] != ['offensive_text', 1]
      return head :bad_request unless @payload['actions']

      action = @payload['actions'].first['value']

      return head :bad_request unless ['is_offensive', 'is_not_offensive'].include?(action)
      return head :bad_request unless chat_message = ChatMessage.find(callback_params[0])

      response = SlackServices::OffensiveText.new(chat_message_id: callback_params[0], text: chat_message.content).payload

      if action == 'is_offensive'
        chat_message.is_offensive!

        response[:attachments].first[:color] = :danger
        response[:attachments].last[:text] = "*:#{:no_entry_sign}: <@#{@payload['user']['name']}> a marqué le contenu comme offensant*"
      elsif action == 'is_not_offensive'
        chat_message.is_not_offensive!

        response[:attachments].first[:color] = :good
        response[:attachments].last[:text] = "*:#{:white_check_mark}: <@#{@payload['user']['name']}> a marqué le contenu comme non offensant*"
      end

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
      head :unauthorized if @payload['token'] != SlackServices::UnblockUser.webhook('token')
    end

    def authenticate_slack_offensive_text!
      head :unauthorized if @payload['token'] != SlackServices::OffensiveText.webhook('token')
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
