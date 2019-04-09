require 'rails_helper'

RSpec.describe RegistrationRequest, type: :model do
  it { should validate_presence_of :status }
  it { should validate_presence_of :extra }
  it { should validate_inclusion_of(:status).in_array(%w(pending rejected validated)) }

  describe "info about request" do
    let(:registration_request) { FactoryGirl.build(:registration_request) }
    it { expect(registration_request.organization_field("name")).to eq("namefoo")}
    it { expect(registration_request.user_field("first_name")).to eq("John")}
  end
end
