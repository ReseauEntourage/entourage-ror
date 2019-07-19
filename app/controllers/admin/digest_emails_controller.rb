module Admin
  class DigestEmailsController < Admin::BaseController
    def index
      @emails = DigestEmail.scheduled.upcoming_delivery.sorted
    end

    def show
      redirect_to edit_admin_digest_email_path(params[:id])
    end

    def edit
      @email = DigestEmail.find(params[:id])

      @cities = DigestEmailService.config.cities.map do |name, department|
        [name.to_s, department.to_s]
      end

      @group_ids = {}

      @cities.each do |_, department|
        ids = @email.data.dig('group_ids', department) || []
        @group_ids[department] = ids
      end

      @groups = Entourage.where(id: @group_ids.values.flatten.uniq)
      @groups = Hash[@groups.map { |g| [g.id, g] }]

      @events = {}
      @cities.each do |_, department|
        @events[department] = DigestEmailService.events_for_city(department, date: @email.deliver_at)
      end
    end

    def update
      @email = DigestEmail.find(params[:id])

      @email.data['group_ids'] = {}
      params[:group_ids].each do |department, values|
        group_ids = values.scan(/\d+/).map(&:to_i).uniq
        @email.data['group_ids'][department.to_s] = group_ids
      end

      if !@email.save
        flash[:error] = @email.errors.full_messages.to_sentence
      end

      redirect_to edit_admin_digest_email_path(@email)
    end

    def send_test
      email = DigestEmail.find(params[:id])
      recipient = User.where(community: :entourage).find_by(email: params[:email])

      if recipient.nil? || !recipient.admin
        flash[:error] = "#{params[:email]} n'est pas administrateur. L'email n'a pas été envoyé."
        redirect_to edit_admin_digest_email_path(email)
        return
      end

      status = DigestEmailService.deliver_test(
        email, user_id: recipient.id, department: params[:department])

      if status == :success
        flash[:success] = "Email envoyé !"
      else
        flash[:error] = "Erreur (#{status.inspect}). L'email n'a pas été envoyé."
      end

      redirect_to edit_admin_digest_email_path(email)
    end
  end
end
