require 'rails_helper'
require 'mixpanel_tools'

RSpec.describe Address, type: :model do
  it { should validate_presence_of(:place_name) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }

  describe "Mixpanel sync" do
    before { Address.stub(:enable_mixpanel_sync?) { true } }

    context "after creation" do
      let(:address) { build :address }

      it do
        expect(MixpanelTools).to receive(:batch_update).with(anything) do |updates|
          expect(updates.to_a).to eq([{
            "$distinct_id"=>address.user.id,
            "$set"=>{
              "Zone d'action (pays)"=>"France",
              "Zone d'action (code postal)"=>"75020",
              "Zone d'action (département)"=>"75"
            }
          }])
        end.and_return([])
        address.save
      end
    end
  end
end
