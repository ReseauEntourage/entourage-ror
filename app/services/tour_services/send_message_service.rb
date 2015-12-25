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
      elsif params[:recipients]=="in_tour"
        recipients = organization.users.joins(:tours).where("tours.status=0 AND tours.created_at>=?", Date.today.beginning_of_day).group("users.id")
      elsif params[:recipients]
        individual_recipients = params[:recipients].select {|k| k.match(/user_id/).present? }
        recipients = organization.users.where(id: individual_recipients.map {|user_id_str| user_id_str.delete("user_id_")})
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