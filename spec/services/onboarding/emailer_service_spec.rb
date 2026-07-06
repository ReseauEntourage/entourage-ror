require 'rails_helper'

describe Onboarding::EmailerService, type: :service do
  describe '.deliver_papotages_invitation_email' do
    let(:run_time) { Time.zone.now }

    let!(:papotage) { create(:outing, :outing_class, online: true, title: 'Papotage du mardi') }

    let!(:first_steps_outing) { create(:outing, :outing_class, online: true, sf_category: :welcome_entourage_local) }
    let!(:user) { create(:public_user) }
    let!(:join_request) do
      Timecop.freeze(1.day.ago) do
        create(:join_request, user: user, joinable: first_steps_outing, status: 'accepted')
      end
    end

    subject { Timecop.freeze(run_time) { described_class.deliver_papotages_invitation_email } }

    it "envoie un email a l'utilisateur eligible" do
      mail = double('mail')
      expect(MemberMailer).to receive(:first_steps_papotages_invitation).with(user, anything).and_return(mail)
      expect(mail).to receive(:deliver_later)
      subject
    end

    context "quand il n'y a pas de papotage a venir" do
      before { papotage.destroy }

      it "n'envoie pas d'email" do
        expect(MemberMailer).not_to receive(:first_steps_papotages_invitation)
        subject
      end
    end

    context "quand l'utilisateur a deja rejoint un papotage" do
      let!(:papotage_join) { create(:join_request, user: user, joinable: papotage, status: 'accepted') }

      it "n'envoie pas d'email" do
        expect(MemberMailer).not_to receive(:first_steps_papotages_invitation)
        subject
      end
    end

    context "quand l'inscription a la session premiers pas date d'avant-hier" do
      let!(:join_request) do
        Timecop.freeze(2.days.ago) do
          create(:join_request, user: user, joinable: first_steps_outing, status: 'accepted')
        end
      end

      it "n'envoie pas d'email" do
        expect(MemberMailer).not_to receive(:first_steps_papotages_invitation)
        subject
      end
    end

    context "quand l'inscription est pour un webinaire (pas une session premiers pas)" do
      let!(:webinar_outing) { create(:outing, :outing_class, online: true, sf_category: :atelier_femmes) }
      let!(:webinar_join) do
        Timecop.freeze(1.day.ago) do
          create(:join_request, user: user, joinable: webinar_outing, status: 'accepted')
        end
      end

      before { JoinRequest.where(joinable: first_steps_outing, user: user).delete_all }

      it "n'envoie pas d'email" do
        expect(MemberMailer).not_to receive(:first_steps_papotages_invitation)
        subject
      end
    end

    context "quand l'inscription est en statut pending" do
      let!(:join_request) do
        Timecop.freeze(1.day.ago) do
          create(:join_request, user: user, joinable: first_steps_outing, status: 'pending')
        end
      end

      it "n'envoie pas d'email" do
        expect(MemberMailer).not_to receive(:first_steps_papotages_invitation)
        subject
      end
    end

    context "quand l'utilisateur est supprime" do
      before { user.update_column(:deleted, true) }

      it "n'envoie pas d'email" do
        expect(MemberMailer).not_to receive(:first_steps_papotages_invitation)
        subject
      end
    end

    context "quand l'utilisateur n'a pas d'email" do
      before { user.update_column(:email, '') }

      it "n'envoie pas d'email" do
        expect(MemberMailer).not_to receive(:first_steps_papotages_invitation)
        subject
      end
    end

    context "quand plusieurs utilisateurs sont eligibles" do
      let!(:user2) { create(:public_user) }
      let!(:join_request2) do
        Timecop.freeze(1.day.ago) do
          create(:join_request, user: user2, joinable: first_steps_outing, status: 'accepted')
        end
      end

      it "envoie un email a chaque utilisateur" do
        mail = double('mail')
        allow(mail).to receive(:deliver_later)
        expect(MemberMailer).to receive(:first_steps_papotages_invitation).twice.and_return(mail)
        subject
      end
    end

    context "quand l'utilisateur a deux inscriptions a des sessions premiers pas hier" do
      let!(:first_steps_outing2) { create(:outing, :outing_class, online: true, sf_category: :welcome_entourage_pro) }
      let!(:join_request2) do
        Timecop.freeze(1.day.ago) do
          create(:join_request, user: user, joinable: first_steps_outing2, status: 'accepted')
        end
      end

      it "n'envoie qu'un seul email" do
        mail = double('mail')
        allow(mail).to receive(:deliver_later)
        expect(MemberMailer).to receive(:first_steps_papotages_invitation).once.and_return(mail)
        subject
      end
    end
  end
end
