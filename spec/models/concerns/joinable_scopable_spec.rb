require 'rails_helper'

describe JoinableScopable do
  let(:user) { create(:public_user) }

  let(:action) { create(:entourage) }
  let(:conversation) { create(:conversation) }
  let(:neighborhood) { create(:neighborhood, user: user) }

  describe "members_has_changed!" do
    let(:join_request) { create :join_request, status: :accepted, joinable: joinable }

    context "on create join_request on action" do
      let(:joinable) { action }

      it {
        expect_any_instance_of(Entourage).to receive(:members_has_changed!)

        join_request
      }

      it {
        join_request

        expect(joinable.reload.number_of_people).to eq(1)
      }
    end

    context "on update join_request on action" do
      let(:joinable) { action }
      let(:subject) { join_request.update_attribute(:status, :cancelled) }

      before { join_request }

      it {
        expect_any_instance_of(Entourage).to receive(:members_has_changed!)

        subject
      }

      it {
        subject

        expect(joinable.reload.number_of_people).to eq(0)
      }
    end

    context "on create join_request on conversation" do
      let(:joinable) { conversation }

      it {
        expect_any_instance_of(Entourage).to receive(:members_has_changed!)

        join_request
      }

      it {
        join_request

        expect(joinable.reload.number_of_people).to eq(1)
      }
    end

    context "on update join_request on conversation" do
      let(:joinable) { conversation }
      let(:subject) { join_request.update_attribute(:status, :cancelled) }

      before { join_request }

      it {
        expect_any_instance_of(Entourage).to receive(:members_has_changed!)

        subject
      }

      it {
        subject

        expect(joinable.reload.number_of_people).to eq(0)
      }
    end

    context "on create join_request on neighborhood" do
      it {
        expect_any_instance_of(Neighborhood).to receive(:members_has_changed!)

        neighborhood
      }

      it {
        neighborhood

        expect(neighborhood.reload.number_of_people).to eq(1)
      }
    end

    context "on update join_request on neighborhood" do
      let(:join_request) { JoinRequest.find_by(joinable: neighborhood, user: neighborhood.user, status: :accepted) }
      let(:subject) { join_request.update_attribute(:status, :cancelled) }

      before { join_request }

      it {
        expect_any_instance_of(Neighborhood).to receive(:members_has_changed!)

        subject
      }

      it {
        subject

        expect(neighborhood.reload.number_of_people).to eq(0)
      }
    end
  end
end
