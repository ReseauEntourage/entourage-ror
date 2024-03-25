require 'rails_helper'

describe Onboarding::Timeliner do
  let!(:user) { create(:public_user) }
  let(:subject) { Onboarding::Timeliner.new(user.id, verb).run }

  let!(:neighborhood) { create(:neighborhood) }

  before { User.any_instance.stub(:default_neighborhood).and_return(neighborhood) }

  describe "offer_help_on_h1_after_registration" do
    let(:verb) { :h1_after_registration }

    after { subject }

    it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
      nil,
      Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.h1.title'),
      Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.h1.offer'),
      [user], :resources, nil,
      { instance: :resources, stage: :h1 }
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
      Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.j2.title'),
      Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.j2.offer'),
      [user], "neighborhood", neighborhood.id,
      { instance: "neighborhood", instance_id: neighborhood.id, stage: :j2 }
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
      before { OutingsServices::Finder.any_instance.stub(:find_all) { Entourage.where(id: create(:outing, online: false)) } }

      it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
        nil,
        Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.j5.title_outing'),
        Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.j5.offer_outing'),
        [user], :outings, nil,
        { instance: :outings, stage: :j5 }
      ) }
    end

    context "no outing, action" do
      before { SolicitationServices::Finder.any_instance.stub(:find_all) { Entourage.where(id: create(:entourage)) } }

      it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
        nil,
        Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.j5.title_action'),
        Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.j5.offer_action'),
        [user], :solicitations, nil,
        { instance: :solicitations, stage: :j5 }
      ) }
    end

    context "no outing, no action" do
      it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
        nil,
        Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.j5.title_create_action'),
        Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.j5.offer_create_action'),
        [user], :contribution, nil,
        { instance: :contribution, stage: :j5 }
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
