require 'rails_helper'

describe JoinRequestAcceptTracking do

  context 'when creating a join request' do
    let(:request) { create :join_request, status: status }

    context 'when status is pending' do
      let(:status) { :pending }
      it 'sets requested_at to the same value as created_at' do
        expect(request.requested_at).to be_present
        expect(request.requested_at).to eq request.created_at
      end
      it 'leaves accepted_at blank' do
        expect(request.accepted_at).to be nil
      end
    end

    context 'when status is accepted' do
      let(:status) { :accepted }
      it 'leaves requested_at blank' do
        expect(request.requested_at).to be nil
      end
      it 'sets accepted_at to the same value as created_at' do
        expect(request.accepted_at).to be_present
        expect(request.accepted_at).to eq request.created_at
      end
    end

    context 'when status is neither pending nor accepted' do
      let(:status) { :cancelled }
      it 'leaves requested_at blank' do
        expect(request.requested_at).to be nil
      end
      it 'leaves accepted_at blank' do
        expect(request.accepted_at).to be nil
      end
    end
  end

  context 'when accepting a join request' do
    let(:request) { Timecop.freeze(5.hours.ago) { create :join_request, status: status } }
    subject { request.update(status: :accepted) }

    context 'when status was pending' do
      let(:status) { :pending }
      it "doesn't change requested_at" do
        expect { subject }.not_to change { request.requested_at }
      end
      it 'updates accepted_at to the same value as updated_at' do
        expect { subject }.to change { request.accepted_at }
        expect(request.accepted_at).to eq request.updated_at
      end
    end

    context 'when status was accepted' do
      let(:status) { :accepted }
      it "doesn't change requested_at" do
        expect { subject }.not_to change { request.requested_at }
      end
      it "doesn't change accepted_at" do
        expect { subject }.not_to change { request.accepted_at }
      end
    end

    context 'when status was neither pending nor accepted' do
      let(:status) { :cancelled }
      it "doesn't change requested_at" do
        expect { subject }.not_to change { request.requested_at }.from(nil)
      end
      it 'updates accepted_at to the same value as updated_at' do
        expect { subject }.to change { request.accepted_at }
        expect(request.accepted_at).to eq request.updated_at
      end
    end
  end

  context 'when updating a join request to pending' do
    let(:request) { Timecop.freeze(5.hours.ago) { create :join_request, status: status } }
    subject { request.update(status: :pending) }

    context 'when status was pending' do
      let(:status) { :pending }
      it "doesn't change requested_at" do
        expect { subject }.not_to change { request.requested_at }
      end
      it "doesn't change accepted_at" do
        expect { subject }.not_to change { request.accepted_at }
      end
    end

    context 'when status was accepted' do
      let(:status) { :accepted }
      it 'updates requested_at to the same value as updated_at' do
        expect { subject }.to change { request.requested_at }
        expect(request.requested_at).to eq request.updated_at
      end
      it 'sets accepted_at to nil' do
        expect { subject }.to change { request.accepted_at }.to(nil)
      end
    end

    context 'when status was neither pending nor accepted' do
      let(:status) { :cancelled }
      it 'updates requested_at to the same value as updated_at' do
        expect { subject }.to change { request.requested_at }
        expect(request.requested_at).to eq request.updated_at
      end
      it 'leaves accepted_at blank' do
        expect { subject }.not_to change { request.accepted_at }.from(nil)
      end
    end
  end

  context 'when updating a join request to a state other than pending or accepted' do
    let(:request) { Timecop.freeze(5.hours.ago) { create :join_request, status: status } }
    subject { request.update(status: :cancelled) }

    context 'when status was pending' do
      let(:status) { :pending }
      it "doesn't change requested_at" do
        expect { subject }.not_to change { request.requested_at }
      end
      it "doesn't change accepted_at" do
        expect { subject }.not_to change { request.accepted_at }
      end
    end

    context 'when status was accepted' do
      let(:status) { :accepted }
      it "doesn't change requested_at" do
        expect { subject }.not_to change { request.requested_at }
      end
      it "doesn't change accepted_at" do
        expect { subject }.not_to change { request.accepted_at }
      end
    end

    context 'when status was neither pending nor accepted' do
      let(:status) { :cancelled }
      it "doesn't change requested_at" do
        expect { subject }.not_to change { request.requested_at }
      end
      it "doesn't change accepted_at" do
        expect { subject }.not_to change { request.accepted_at }
      end
    end
  end
end
