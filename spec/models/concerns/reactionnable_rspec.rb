require 'rails_helper'
require "#{Rails.root}/lib/tasks/populate.rb"

describe Reactionnable do
  let(:instance) { create(:chat_message) }

  let(:heart) { create(:reaction, key: :heart) }
  let(:thumb) { create(:reaction, key: :thumb) }
  let(:entourage) { create(:reaction, key: :entourage) }

  describe "reactions.summary" do
    let(:subject) { instance.reactions.summary }

    context "no reaction" do
      it { expect(subject).to eq({}) }
    end

    context "no reaction on instance" do
      let!(:user_reaction) { create(:user_reaction) }

      it { expect(subject).to eq({}) }
    end

    context "one reaction" do
      let!(:user_reaction) { create(:user_reaction, instance: instance, reaction: heart) }

      it { expect(subject).to eq({ heart.id => 1 }) }
    end

    context "multiple reactions" do
      let!(:user_reaction_1) { create(:user_reaction, instance: instance, reaction: heart) }
      let!(:user_reaction_2) { create(:user_reaction, instance: instance, reaction: heart) }
      let!(:user_reaction_3) { create(:user_reaction, instance: instance, reaction: thumb) }

      it { expect(subject).to eq({
        heart.id => 2,
        thumb.id => 1,
      }) }
    end
  end

  describe "reactions.user_reaction_id" do
    let(:subject) { instance.reactions.user_reaction_id(user_id) }

    let!(:user_reaction_0) { create(:user_reaction) }
    let!(:user_reaction_1) { create(:user_reaction, instance: instance, reaction: heart) }
    let!(:user_reaction_2) { create(:user_reaction, instance: instance, reaction: heart) }
    let!(:user_reaction_3) { create(:user_reaction, instance: instance, reaction: thumb) }

    context "no reaction" do
      let(:user_id) { create(:public_user).id }

      it { expect(subject).to eq(nil) }
    end

    context "no reaction on instance" do
      let(:user_id) { user_reaction_0.user_id }

      it { expect(subject).to eq(nil) }
    end

    context "on single reaction" do
      let(:user_id) { user_reaction_3.user_id }

      it { expect(subject).to eq(user_reaction_3.reaction_id) }
    end

    context "on multiple reactions" do
      let(:user_id) { user_reaction_2.user_id }

      it { expect(subject).to eq(user_reaction_2.reaction_id) }
    end
  end

  describe "reactions.build" do
    let(:subject) { instance.reactions.build(user: user, reaction_id: reaction_id) }

    let(:user) { create(:public_user) }
    let(:reaction_id) { heart.id }

    it { expect(subject).to be_a(UserReaction) }
    it { expect(subject.user.id).to eq(user.id) }
    it { expect(subject.reaction.id).to eq(heart.id) }

    context "reaction saved" do
      it { expect(subject.save).to eq(true) }
      it { expect { subject.save }.to change { UserReaction.count }.by(1) }
    end

    context "already reacted succeeds on same reaction but different instance" do
      let!(:user_reaction) { create(:user_reaction, reaction: heart, user: user) }

      it { expect(subject.save).to eq(true) }
      it { expect { subject.save }.to change { UserReaction.count }.by(1) }
    end

    context "already reacted fails on same reaction" do
      let!(:user_reaction) { create(:user_reaction, instance: instance, reaction: heart, user: user) }

      it { expect(subject.save).to eq(false) }
      it { expect { subject.save }.not_to change { UserReaction.count } }
    end

    context "already reacted fails on another reaction" do
      let!(:user_reaction) { create(:user_reaction, instance: instance, reaction: thumb, user: user) }

      it { expect(subject.save).to eq(false) }
      it { expect { subject.save }.not_to change { UserReaction.count } }
    end
  end

  describe "reactions.destroy" do
    let(:subject) { instance.reactions.destroy(user: user) }

    let(:user) { create(:public_user) }

    context "no reaction" do
      it { expect(subject).to eq(nil) }
      it { expect { subject }.not_to change { UserReaction.count } }
    end

    context "no reaction on instance" do
      let!(:user_reaction) { create(:user_reaction, user: user) }

      it { expect(subject).to eq(nil) }
      it { expect { subject }.not_to change { UserReaction.count } }
    end

    context "on single reaction" do
      let!(:user_reaction) { create(:user_reaction, instance: instance, reaction: heart, user: user) }

      it { expect(subject.id).to eq(user_reaction.id) }
      it { expect { subject }.to change { UserReaction.count }.by(-1) }
    end

    context "on multiple reactions" do
      let!(:user_reaction_1) { create(:user_reaction, instance: instance, reaction: heart, user: user) }
      let!(:user_reaction_2) { create(:user_reaction, instance: instance, reaction: heart) }

      it { expect(subject.id).to eq(user_reaction_1.id) }
      it { expect { subject }.to change { UserReaction.count }.by(-1) }
    end
  end
end
