require 'rails_helper'

def expect_json_eq a, b
  expect(JSON.parse(a)).to eq JSON.parse(JSON.fast_generate(b))
end

def default_variables
  auth_token = UserServices::UserAuthenticator.auth_token(user)

  {
    first_name: user.first_name,
    user_id: UserServices::EncodedId.encode(user.id),
    webapp_login_link: "https://www.entourage.social/app?auth=#{auth_token}",
    login_link: "https://www.entourage.social/deeplink/feed?auth=#{auth_token}",
    unsubscribe_url: EmailPreferencesService.update_url(user: user, accepts_emails: false, category: :default)
  }
end

def expect_mailjet_email opts={}, &block
  let(:options) do
    options = opts.merge(instance_eval(&block)).reverse_merge(
      from: %("Le Réseau Entourage" <guillaume@entourage.social>),
      variables: {},
      payload: {}
    )

    options[:variables].reverse_merge!(default_variables)

    options[:payload].reverse_merge!(
      type: options[:campaign_name],
      user_id: user.id,
      unsubscribe_category: :default
    )
    options
  end

  context "when user has no email" do
    before { user.update_column(:email, nil) }
    it { expect(mail.message).to be_a ActionMailer::Base::NullMail }
  end

  it { expect(mail.subject).to be nil }
  it { expect(mail[:from].value).to eq options[:from] }
  it { expect(mail.to).to eq [user.email] }
  it { expect(mail.subject).to be nil }
  it { expect(mail['X-MJ-TemplateID'].value).to eq options[:template_id].to_s }
  it { expect(mail['X-MJ-TemplateLanguage'].value).to eq '1' }
  it { Timecop.freeze; expect_json_eq mail['X-MJ-Vars'].value, options[:variables] }
  it { expect_json_eq mail['X-MJ-EventPayload'].value, options[:payload] }
  it { expect(mail['X-Mailjet-Campaign'].value).to eq options[:campaign_name].to_s }
end

describe MemberMailer, type: :mailer do
  let(:user) { create :public_user }

  context "when first_name is not capitalized" do
    let(:user) { create :public_user, first_name: " bob" }
    let(:mail) { MemberMailer.mailjet_email(to: user, template_id: 0, campaign_name: :c) }
    let(:json_variables) { JSON.parse(mail['X-MJ-Vars'].value) }
    it { expect(json_variables['first_name']).to eq "Bob" }
  end

  describe '#poi_report' do
    let!(:poi) { create :poi }
    let!(:user) { create :pro_user }
    let!(:message) { 'message' }
    let!(:poi_report_email) { 'report_email' }
    before { ENV["POI_REPORT_EMAIL"] = poi_report_email }
    after { ENV.delete("POI_REPORT_EMAIL") }
    subject { MemberMailer.poi_report(poi, user, message) }

    it { expect(subject.from).to eq ['contact@entourage.social'] }
    it { expect(subject.to).to eq [poi_report_email] }
    it { expect(subject.subject).to eq 'Correction de POI' }
    it { expect(subject.body.encoded).to match "L'utilisateur #{user.full_name} ##{user.id} voudrait soumettre une correction sur le POI #{poi.name} ##{poi.id}" }
    it { expect(subject.body.encoded).to match message }
  end

  describe '#welcome' do
    let(:mail) { MemberMailer.welcome(user) }
    let!(:outing) { create(:outing, :outing_class, online: true, title: "JO 2024", event_url: "Paris", sf_category: :welcome_entourage_local) }

    expect_mailjet_email do
      {
        from: %("Le Réseau Entourage" <contact@entourage.social>),
        template_id: user.community.mailjet_template['welcome'],
        campaign_name: :welcome,
        variables: {
          outings_url: Entourage.share_url(:outings),
          outings: [{
            name: 'JO 2024',
            address: 'Paris',
            date: I18n.l(outing.metadata[:starts_at].to_date, format: :short),
            hour: outing.metadata[:starts_at].strftime("%Hh%M"),
            image_url: nil,
            url: outing.share_url
          }]
        }
      }
    end

    describe "community customization" do
      before { allow(user).to receive(:community).and_return(community) }
      let(:community) { OpenStruct.new(
        slug: 'slug',
        mailjet_template: {
          'welcome' => 121212
        }
      )}

      it { expect(mail['X-MJ-TemplateID'].value).to eq '121212' }
      it { expect(mail['X-Mailjet-Campaign'].value).to eq 'slug_welcome' }
    end
  end

  describe 'select default variables' do
    it do
      Timecop.freeze

      mail = MemberMailer.mailjet_email(
        to: user,
        template_id: 123,
        campaign_name: :foobar,
        variables: [
          :first_name,
          :login_link,
          entourage_title: "foobaz"
        ]
      )

      expect_json_eq(
        mail['X-MJ-Vars'].value,
        default_variables.slice(:first_name, :login_link, :unsubscribe_url)
                         .merge(entourage_title: "foobaz")
      )

    end
  end

  describe 'group variables' do
    let(:event) { build :outing, title: "lol", uuid_v2: "e12345" }

    it do
      Timecop.freeze

      mail = MemberMailer.mailjet_email(
        to: user,
        template_id: 123,
        campaign_name: :foobar,
        variables: {
          event => [:event_title, :event_share_url]
        }
      )

      expect_json_eq(
        mail['X-MJ-Vars'].value,
        default_variables.merge(
          event_title: "lol",
          event_share_url: "https://app.entourage.social/actions/e12345"
        )
      )

    end
  end
end
