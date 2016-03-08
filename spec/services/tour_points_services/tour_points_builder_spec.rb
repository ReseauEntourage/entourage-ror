require 'rails_helper'

describe TourPointsServices::TourPointsBuilder do

  let(:tour) { FactoryGirl.create(:tour) }

  describe 'create' do
    context "valid params" do
      let(:params) { [{"passing_time"=>"2016-03-07T19:41:06.953", "longitude"=>0.3, "latitude"=>49.1}, {"passing_time"=>"2016-03-08T19:41:06.953", "longitude"=>0.4, "latitude"=>49.2}] }
      subject { TourPointsServices::TourPointsBuilder.new(tour, params).create }
      it { expect{ subject }.to change {TourPoint.count}.by(2) }
      it { expect(subject).to be_truthy }

      it "sets passing time" do
        subject
        expect(TourPoint.last.passing_time).to eq(DateTime.parse("2016-03-08T19:41:06.953"))
      end
    end

    context "missing passing time" do
      let(:params) { [{"longitude"=>0.3, "latitude"=>49.1}, {"longitude"=>0.4, "latitude"=>49.2}] }
      subject { TourPointsServices::TourPointsBuilder.new(tour, params).create }
      it { expect{ subject }.to change {TourPoint.count}.by(2) }
      it { expect(subject).to be_truthy }

      it "sets passing time" do
        subject
        expect(TourPoint.last.passing_time).to_not be nil
      end
    end

    context "invalid params" do
      let(:params) { [{"longitude"=>"ABC", "latitude"=>"ABC"}, {"longitude"=>0.4, "latitude"=>49.2}] }
      subject { TourPointsServices::TourPointsBuilder.new(tour, params).create }
      it { expect{ subject }.to change {TourPoint.count}.by(0) }
      it { expect(subject).to be false }
    end

    context "only one point" do
      let(:params) { {"passing_time"=>"2016-03-07T19:41:06.953", "longitude"=>0.3, "latitude"=>49.1} }
      subject { TourPointsServices::TourPointsBuilder.new(tour, params).create }
      it { expect{ subject }.to change {TourPoint.count}.by(1) }
      it { expect(subject).to be_truthy }
    end
  end
end