require 'layout_options'

module GoodWaves
  class GroupsController < BaseController
    def index
      @groups = current_user.entourages.where(group_type: :group).to_a
      if @groups.none?
        redirect_to new_good_waves_group_path
      end
    end

    def show
      @group = current_user.entourages.where(group_type: :group).find(params[:id])
      @members = @group.members.order('join_requests.accepted_at')
      @invitations = @group.entourage_invitations.where(status: :pending).order(:created_at).to_a
    end

    def new
    end

    def parse_members
      raw = params[:raw]
      members = []
      raw.each_line do |line|
        raw_phone = line.match(/[\+\d]([^[:alnum:]]*\d){7,}/).try(:[], 0) || ''
        raw_email = line.match(/[[:alnum:]\.\-_]+@[[:alnum:]\.\-_]+/).try(:[], 0) || ''
        raw_name = line.sub(raw_phone, '').sub(raw_email, '')
                       .sub(/^[^[:alpha:]]+/, '').sub(/[^[:alpha:]]+$/, '')
        phone = Phonelib.parse(raw_phone).national
        email = raw_email.downcase.presence
        name = UserPresenter.format_name_part(raw_name)
        members.push(name: name, phone: phone, email: email) if [name, phone, email].any?
      end
      render json: {members: members}
    end

    def create
      members_by_phone = {}
      params[:members].each do |member|
        phone = Phonelib.parse(member[:phone]).e164
        members_by_phone[phone] ||= {phone: phone}
        members_by_phone[phone][:name] ||= UserPresenter.format_name_part(member[:name])
        members_by_phone[phone][:email] ||= (member[:email] || '').strip.downcase.presence
      end

      phones = members_by_phone.keys
      members = members_by_phone.values

      existing = []
      community.users.where(phone: members_by_phone.keys).pluck(:id, :phone, :email).each do |user_id, phone, email|
        member = members_by_phone.delete(phone)
        member[:user_id] = user_id
        member[:account_email] = (email || '').strip.downcase.presence
        existing.push member
      end

      non_registered = members_by_phone.values

      # TODO send email to existing
      # TODO send email to creator?

      group = nil

      ActiveRecord::Base.transaction do
        group = Entourage.create!(
          group_type: :group,
          entourage_type: :contribution,
          display_category: :social,
          user_id: current_user.id,
          title: params[:title],
          public: false,
          latitude: params[:latitude],
          longitude: params[:longitude],
          feed_updated_at: Time.zone.now # simulate content, to mark as unread
        )
        JoinRequest.create!(
          user: current_user,
          joinable: group,
          role: :admin,
          status: :accepted
        )
        existing.each do |member|
          JoinRequest.create!(
            user_id: member[:user_id],
            joinable: group,
            role: :member,
            status: :accepted
          )
        end
        non_registered.each do |member|
          EntourageInvitation.create!(
            invitable: group,
            inviter: group.user,
            phone_number: member[:phone],
            status: :pending,
            invitation_mode: :good_waves, # auto_accept ?
            metadata: {
              name: member[:name],
              email: member[:email]
            }
          )
        end
      end

      # error
      if !group
        redirect_to good_waves_group_path(group)
      end

      short_uuid = group.uuid_v2[1..]
      message = "Hey, ta bande de Bonnes Ondes a été créée ! Pour une diffuser la chaleur humaine, rejoins ton groupe sur l'app Entourage : http://entourage.social/i/#{short_uuid}"
      phones.each do |phone|
        SmsSenderJob.perform_later(phone, message, 'invite')
      end

      members.each do |member|
        email, alternate_email = [member[:account_email], member[:email]].compact.uniq
        GoodWavesMailer.invitation(email, alternate_email, short_uuid).deliver_later
      end

      existing_ids = existing.map { |member| member[:user_id] }
      author_name = UserPresenter.display_name(group.user)
      object = group.title
      message = "Vous venez de rejoindre le groupe de #{author_name}"

      PushNotificationService.new.send_notification(
        author_name,
        object,
        message,
        User.where(id: existing_ids),
        {
          joinable_id: group.id,
          joinable_type: group.class.name,
          group_type: group.group_type,
          type: "JOIN_REQUEST_ACCEPTED",
          user_id: nil
        }
      )

      redirect_to good_waves_group_path(group)
    end
  end
end
