require 'rails_helper'

def expect_json_eq a, b
  expect(JSON.parse(a)).to eq JSON.parse(JSON.fast_generate(b))
end

def expect_mailjet_email opts={}, &block
  let(:options) do
    options = opts.merge(instance_eval &block).reverse_merge(
      from: %("Le Réseau Entourage" <guillaume@entourage.social>),
      variables: {},
      payload: {}
    )

    auth_token = UserServices::UserAuthenticator.auth_token(user)

    options[:variables].reverse_merge!(
      first_name: user.first_name,
      user_id: UserServices::EncodedId.encode(user.id),
      webapp_login_link: "https://www.entourage.social/app?auth=#{auth_token}",
      login_link: "https://www.entourage.social/deeplink/feed?auth=#{auth_token}",
    )
    options[:payload].reverse_merge!(
      type: options[:campaign_name],
      user_id: user.id
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
  it { expect_json_eq mail['X-MJ-Vars'].value, options[:variables] }
  it { expect_json_eq mail['X-MJ-EventPayload'].value, options[:payload] }
  it { expect(mail['X-Mailjet-Campaign'].value).to eq options[:campaign_name].to_s }
end

describe MemberMailer, type: :mailer do
  let(:user) { create :public_user }

  describe '#tour_report' do
    let!(:tour) { FactoryGirl.create :tour, :filled }
    let!(:mail) { MemberMailer.tour_report(tour) }
    it { expect(mail.from).to eq ['maraudes@entourage.social'] }
    it { expect(mail.to).to eq [tour.user.email] }
    it { expect(mail.subject).to eq 'Résumé de la maraude' }
    it { expect(mail.body.encoded).to match "Bonjour #{tour.user.first_name}" }
    it { expect(mail.body.encoded).to match "<a href=\"http://localhost/tours/#{tour.id}\">Cliquez ici</a> pour retrouver votre maraude sur le web" }

    context "encounter has answers" do
      let!(:question) { FactoryGirl.create(:question) }
      let!(:answer) { FactoryGirl.create(:answer, question: question, encounter: tour.encounters.first) }
      it { expect(mail.body.encoded).to match "aux questions" }
    end
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

  describe '#registration_request_accepted' do
    let!(:user) { create :pro_user }
    subject { MemberMailer.registration_request_accepted(user) }
    it { expect(subject.from).to eq ['communaute@entourage.social'] }
    it { expect(subject.to).to eq [user.email] }
    it { expect(subject.subject).to eq "Votre demande d'adhésion à la plateforme Entourage a été acceptée" }
  end

  describe '#welcome' do
    let(:mail) { MemberMailer.welcome(user) }

    expect_mailjet_email do
      {
        from: %("Le Réseau Entourage" <contact@entourage.social>),
        template_id: user.community.mailjet_template['welcome'],
        campaign_name: :welcome
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

  describe '#entourage_confirmation' do
    let(:entourage) { create :entourage, user: user }
    let(:mail) { MemberMailer.entourage_confirmation(entourage) }

    expect_mailjet_email do
      {
        template_id: 312279,
        campaign_name: :action_confirmation,
        variables: {
          entourage_title: entourage.title
        },
        payload: {
          entourage_id: entourage.id
        }
      }
    end
  end

  describe '#action_zone_suggestion' do
    let(:postal_code) { '75012' }
    let(:user_id) { UserServices::EncodedId.encode(user.id) }
    let(:mail) { MemberMailer.action_zone_suggestion(user, postal_code) }

    expect_mailjet_email do
      {
        template_id: 355675,
        campaign_name: :action_zone_suggestion,
        variables: {
          postal_code: postal_code,
          confirm_url: confirm_api_v1_action_zones_url(
            host: API_HOST,
            protocol: :https,
            user_id: user_id,
            postal_code: postal_code
          )
        }
      }
    end
  end

  describe '#action_zone_confirmation' do
    let(:postal_code) { '75012' }
    let(:mail) { MemberMailer.action_zone_confirmation(user, postal_code) }

    expect_mailjet_email do
      {
        template_id: 335020,
        campaign_name: :action_zone_confirmation,
        variables: {
          postal_code: postal_code,
        }
      }
    end
  end
end
