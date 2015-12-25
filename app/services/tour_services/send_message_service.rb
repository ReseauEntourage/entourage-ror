module TourServices
  class SendMessageService
    def initialize(params:, current_user:)
      @params = params
      @current_user = current_user
    end

    def sender
      current_user.full_name
    end

    def object
      params[:object]
    end

    def content
      params[:message]
    end

    def recipients
      if params[:recipients]=="all"
        recipients = organization.users
      end

      if params[:recipients]=="in_tour"
        recipients = organization.users.joins(:tours).where("tours.status=\"ongoing\" AND date(created_at)=?", Date.today).group("users.id")
      end

      individual_recipients = params.keys.select {|k| k.match("user_id").present? }
      if individual_recipients.present?
        recipients = organization.users.where(id: individual_recipients.map {|user_id_str| user_id_str.delete("user_id")})
      end

      recipients || organization.users
    end

    private
    attr_reader :params, :current_user

    def organization
      current_user.organization
    end
  end
end