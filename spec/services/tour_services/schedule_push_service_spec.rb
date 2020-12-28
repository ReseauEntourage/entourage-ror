require 'rails_helper'

describe TourServices::SchedulePushService do
  before { Timecop.freeze(Time.parse("08/10/2010").at_beginning_of_day) }
  let(:organization) { FactoryBot.create(:organization) }

  describe "initialize" do
    it "raises exception if date is in the past" do
      expect { TourServices::SchedulePushService.new(organization: organization,
                                               date: Date.parse("10/10/2009"))
      }.to raise_error(TourServices::InvalidScheduledPushDateError)
    end
  end

  describe 'scheduled_message' do
    let(:service) { TourServices::SchedulePushService.new(organization: organization,
                                                                  date: Date.parse("10/10/2010")) }
    before { service.schedule(object: "foo",
                              message: "bar",
                              sender: "vda") }


    it "returns message for same date" do
      on_time_service = TourServices::SchedulePushService.new(organization: organization,
                                                              date: Date.parse("10/10/2010"))
      expect(on_time_service.scheduled_message).to eq({"object" => "foo",
                                                       "message" => "bar",
                                                       "sender" => "vda"})
    end
    it "returns nil for another date" do
      off_time_service = TourServices::SchedulePushService.new(organization: organization,
                                                              date: Date.parse("09/10/2010"))
      expect(off_time_service.scheduled_message).to eq({})
    end

    it "returns nil for another organisation" do
      other_org_service = TourServices::SchedulePushService.new(organization: FactoryBot.create(:organization),
                                                               date: Date.parse("10/10/2010"))
      expect(other_org_service.scheduled_message).to eq({})
    end
  end

  describe 'schedule' do
    let(:service) { TourServices::SchedulePushService.new(organization: organization,
                                                          date: Date.parse("10/10/2010")) }
    it "sets expire on key" do
      expect($redis).to receive(:expire).with("scheduled_message:organization:#{organization.id}:date:2010-10-10", 172800)
      service.schedule(object: "foo",
                       message: "bar",
                       sender: "vda")
    end
  end
end
