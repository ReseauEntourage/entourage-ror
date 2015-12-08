require 'rails_helper'

RSpec.describe RegistrationRequest, type: :model do
  it { should validate_presence_of :status }
  it { should validate_presence_of :extra }

  describe "info about request" do
    let(:registration_request) { FactoryGirl.build(:registration_request) }
    it { expect(registration_request.organization_name).to eq("namefoo")}
  end
end