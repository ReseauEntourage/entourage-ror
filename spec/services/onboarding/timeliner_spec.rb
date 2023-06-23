require 'rails_helper'

describe Onboarding::Timeliner do
  let!(:user) { create(:public_user) }
  let(:subject) { Onboarding::Timeliner.new(user.id, verb).run }

  describe "offer_help_on_h1_after_registration" do
    let(:verb) { :h1_after_registration }

    after { subject }

    it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(nil,
      Onboarding::Timeliner::TITLE_H1,
      Onboarding::Timeliner::OFFER_H1,
      [user], nil, nil,
      { welcome: true, stage: :h1, url: :resources }
    ) }
  end

  describe "ask_for_help_on_h1_after_registration" do
    let(:verb) { :h1_after_registration }
    let!(:user) { create(:public_user, goal: :ask_for_help) }

    after { subject }

    # it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(nil,
    #   Onboarding::Timeliner::TITLE_H1,
    #   Onboarding::Timeliner::ASK_H1,
    #   [user], nil, nil,
    #   { welcome: true, stage: :h1, url: :resources }
    # ) }
  end

  describe "offer_help_on_j2_after_registration" do
    let(:verb) { :j2_after_registration }

    after { subject }

    it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(nil,
      Onboarding::Timeliner::TITLE_J2,
      Onboarding::Timeliner::OFFER_J2,
      [user], nil, nil,
      { welcome: true, stage: :j2 }
    ) }
  end

  describe "ask_help_on_j2_after_registration" do
    let(:verb) { :j2_after_registration }
    let!(:user) { create(:public_user, goal: :ask_for_help) }

    after { subject }

    # it { expect_any_instance_of(PushNotificationService).to receive(:send_notification) }
  end

  describe "offer_help_on_j5_after_registration" do
    let(:verb) { :j5_after_registration }

    after { subject }

    context "outing, no action" do
      before { OutingsServices::Finder.any_instance.stub(:find_all) { [create(:outing)] } }

      it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
        nil,
        Onboarding::Timeliner::TITLE_J5_OUTING,
        Onboarding::Timeliner::OFFER_J5_OUTING,
        [user], nil, nil,
        { welcome: true, stage: :j5, url: :outings }
      ) }
    end

    context "no outing, action" do
      before { SolicitationServices::Finder.any_instance.stub(:find_all) { [create(:entourage)] } }

      it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
        nil,
        Onboarding::Timeliner::TITLE_J5_ACTION,
        Onboarding::Timeliner::OFFER_J5_ACTION,
        [user], nil, nil,
        { welcome: true, stage: :j5, url: :solicitations }
      ) }
    end

    context "no outing, no action" do
      it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
        nil,
        Onboarding::Timeliner::TITLE_J5_CREATE_ACTION,
        Onboarding::Timeliner::OFFER_J5_CREATE_ACTION,
        [user], nil, nil,
        { welcome: true, stage: :j5, url: :create_action }
      ) }
    end
  end

  describe "ask_help_on_j5_after_registration" do
    let(:verb) { :j5_after_registration }
    let!(:user) { create(:public_user, goal: :ask_for_help) }

    after { subject }

    # it { expect_any_instance_of(PushNotificationService).to receive(:send_notification) }
  end

  describe "offer_help_on_j8_after_registration" do
    let(:verb) { :j8_after_registration }

    after { subject }

    it { expect_any_instance_of(PushNotificationService).to receive(:send_notification) }
  end

  describe "ask_help_on_j8_after_registration" do
    let(:verb) { :j8_after_registration }
    let!(:user) { create(:public_user, goal: :ask_for_help) }

    after { subject }

    # it { expect_any_instance_of(PushNotificationService).to receive(:send_notification) }
  end

  describe "offer_help_on_j11_after_registration" do
    let(:verb) { :j11_after_registration }

    after { subject }

    it { expect_any_instance_of(PushNotificationService).to receive(:send_notification) }
  end

  describe "ask_help_on_j11_after_registration" do
    let(:verb) { :j11_after_registration }
    let!(:user) { create(:public_user, goal: :ask_for_help) }

    after { subject }

    # it { expect_any_instance_of(PushNotificationService).to receive(:send_notification) }
  end
end
