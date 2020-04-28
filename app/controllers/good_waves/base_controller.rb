require 'layout_options'

module GoodWaves
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :ensure_canonical_url!
    before_action :authenticate_user!
    before_action :ensure_profile_complete!, except: [:onboarding, :update_profile]

    helper_method :current_user, :community

    include LayoutOptions
    layout 'good_waves'

    def home
      @groups = current_user.entourages.where(group_type: :group)
      case @groups.to_a.count
      when 0
        redirect_to new_good_waves_group_path
      else
        redirect_to good_waves_groups_path
      end
    end

    def new_group
    end

    def onboarding
    end

    def update_profile
      if current_user.update(profile_params)
        redirect_to(params[:continue] || good_waves_path)
      else
        flash[:error_type] = 'unknown'
        redirect_to(request.referrer || good_waves_onboarding_path)
      end
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

    def create_group
      members_by_phone = {}
      params[:members].each do |member|
        phone = Phonelib.parse(member[:phone]).e164
        members_by_phone[phone] ||= {phone: phone}
        members_by_phone[phone][:name] ||= UserPresenter.format_name_part(member[:name])
        members_by_phone[phone][:email] ||= (member[:email] || '').strip.downcase.presence
      end

      existing = []
      community.users.where(phone: members_by_phone.keys).pluck(:id, :phone).each do |user_id, phone|
        member = members_by_phone.delete(phone)
        member[:user_id] = user_id
        existing.push member
      end

      non_registered = members_by_phone.values

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

      # TODO send emails

      short_uuid = group.uuid_v2[1..]
      message = "Hey, ta bande de Bonnes Ondes a été créée ! Pour diffuser la chaleur humaine, rejoins ton groupe sur l'app Entourage : http://entourage.social/i/#{short_uuid}"
      members_by_phone.keys.each do |phone_number|
        SmsSenderJob.perform_later(phone_number, message, 'invite')
      end

      redirect_to good_waves_group_path(group)
    end

    protected

    def ensure_canonical_url!
      if request.get?
        canonical_url = url_for(params)
        redirect_to canonical_url if request.url != canonical_url
      end
    end

    def authenticate_user!
      if current_user.nil?
        return redirect_to new_good_waves_session_path
      end
    end

    def sign_out
      session[:user_id] = nil
      @current_user = nil
    end

    def sign_in user
      session[:user_id] = user.id
      @current_user = nil
    end

    def current_user
      return @current_user if @current_user != nil
      return nil if session[:user_id].nil?

      @current_user = community.users.find_by(id: session[:user_id])

      sign_out if @current_user.nil?

      @current_user
    end

    def community
      @community ||= begin
        $server_community
      end
    end

    def ensure_profile_complete!
      profile_complete =
        current_user.last_name.present? &&
        current_user.last_name.present? &&
        current_user.email.present? &&
        current_user.has_password?

      unless profile_complete
        redirect_to good_waves_onboarding_path
      end
    end

    private

    def profile_params
      params.require(:user).permit(:first_name, :last_name, :email, :password)
    end
  end
end
