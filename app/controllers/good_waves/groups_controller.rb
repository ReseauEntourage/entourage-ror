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
      @members = @group.members.where("status = 'accepted'").order('join_requests.accepted_at')
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

      # prevent group creator from adding themselves again
      members_by_phone.delete(current_user.phone)

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

      ApplicationRecord.transaction do
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
        flash[:erreur] = "Erreur ! Si le problème persiste, contactez lesbonnesondes@entourage.social"
        redirect_to new_good_waves_group_path
      end

      short_uuid = group.uuid_v2[1..]
      message = "Hey, ta bande de Bonnes Ondes a été créée ! Pour une diffuser la chaleur humaine, rejoins ton groupe sur l'app Entourage : http://entourage.social/i/#{short_uuid}"
      phones.each do |phone|
        SmsSenderJob.perform_later(phone, message, 'invite')
      end

      members.each do |member|
        email, alternate_email = [member[:account_email], member[:email]].compact.uniq
        if email.present?
          GoodWavesMailer.invitation(email, alternate_email, short_uuid).deliver_later
        end
      end

      flash[:success] = "Groupe créé ! Des invitations ont été envoyées aux membres par SMS et email."
      redirect_to good_waves_group_path(group)
    end

    def new_invitation
      @group = current_user.entourages.where(group_type: :group).find(params[:id])
    end

    def create_invitation
      group = current_user.entourages.where(group_type: :group).find(params[:id])

      phone = Phonelib.parse(params[:phone]).e164
      name = UserPresenter.format_name_part(params[:name])
      email = (params[:email] || '').strip.downcase.presence

      existing = community.users.find_by(phone: phone)

      if existing.nil?
        invitation = EntourageInvitation.find_or_initialize_by(
          invitable: group,
          phone_number: phone
        )
        invitation.assign_attributes(
          inviter: group.user,
          status: :pending,
          invitation_mode: :good_waves,
          metadata: {
            name: name,
            email: email
          }
        )
        if invitation.persisted?
          invitation.save
          flash[:notice] = "Cette personne a déjà une invitation en attente pour ce groupe."
          return redirect_to good_waves_group_path(group)
        elsif invitation.save
          # continue below
        else
          Raven.capture_exception(ActiveRecord::RecordInvalid.new(invitation))
          flash[:error] = invitation.errors.full_messages.to_sentence
          return redirect_to good_waves_group_path(group)
        end
      else
        join_request = JoinRequest.find_or_initialize_by(
          joinable: group,
          user_id: existing.id,
        )

        if join_request.persisted? && join_request.status == 'accepted'
          flash[:notice] = "Cette personne a déjà membre de ce groupe."
          return redirect_to good_waves_group_path(group)
        end

        join_request.assign_attributes(
          role: :member,
          status: :accepted
        )

        if join_request.save
          # continue below
        else
          Raven.capture_exception(ActiveRecord::RecordInvalid.new(join_request))
          flash[:error] = join_request.errors.full_messages.to_sentence
          return redirect_to good_waves_group_path(group)
        end
      end

      short_uuid = group.uuid_v2[1..]
      message = "Hey, ta bande de Bonnes Ondes a été créée ! Pour une diffuser la chaleur humaine, rejoins ton groupe sur l'app Entourage : http://entourage.social/i/#{short_uuid}"
      SmsSenderJob.perform_later(phone, message, 'invite')

      alternate_email = (existing&.email || '').strip.downcase.presence
      email, alternate_email = [email, alternate_email].compact.uniq
      if email.present?
        GoodWavesMailer.invitation(email, alternate_email, short_uuid).deliver_later
      end

      if existing
        flash[:success] = "Membre ajouté !"
      else
        flash[:success] = "Invitation envoyée !"
      end

      redirect_to good_waves_group_path(group)
    end

    def remove_member
      group = current_user.entourages.where(group_type: :group).find(params[:id])
      join_requests = group.join_requests.where(user_id: params[:user_id])
      join_requests.update_all(status: :cancelled)
      flash[:success] = "Membre retiré du groupe"
      redirect_to good_waves_group_path(group)
    end

    def cancel_invitation
      group = current_user.entourages.where(group_type: :group).find(params[:id])
      invitations = group.entourage_invitations.where(id: params[:invitation_id])
      invitations.update_all(status: :cancelled)
      flash[:success] = "Invitation annulée !"
      redirect_to good_waves_group_path(group)
    end
  end
end
