require 'rails_helper'

describe MemberMailer, type: :mailer do
  describe '#tour_report' do
    let!(:tour) { FactoryGirl.create :tour, :filled }
    let!(:mail) { MemberMailer.tour_report(tour) }
    it { expect(mail.from).to eq ['contact@entourage.social'] }
    it { expect(mail.to).to eq [tour.user.email] }
    it { expect(mail.subject).to eq 'R&eacute;sum&eacute; de la maraude' }
    it { expect(mail.body.encoded).to match "Bonjour #{tour.user.first_name}" }
    it { expect(mail.body.encoded).to match "https://maps.googleapis.com/maps/api/staticmap?size=512x512&path=color:0x0000ff|weight:5#{tour.get_coordinates_uri_static_map}" }
  end
end