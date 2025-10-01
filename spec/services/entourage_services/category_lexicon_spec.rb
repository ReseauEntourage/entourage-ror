require 'rails_helper'

RSpec.describe EntourageServices::CategoryLexicon do

  describe 'category' do
    subject { EntourageServices::CategoryLexicon.new(text: text).category }

    context 'one word from mat_help' do
      let(:text) { "besoin d'aide" }
      it { should eq('mat_help') }
    end

    context 'one word from social' do
      let(:text) { 'atelier' }
      it { should eq('social') }
    end

    context 'multiple word from mat_help' do
      let(:text) { "besoin d'aide distribution" }
      it { should eq('mat_help') }
    end

    context 'one word from non_mat_help' do
      let(:text) { 'maraude pour partager' }
      it { should eq('non_mat_help') }
    end

    context 'one word from mat_help and one word from non_mat_help' do
      let(:text) { 'maraude de distribution' }
      it { should eq('mat_help') }
    end

    context 'one word from mat_help and two word from non_mat_help' do
      let(:text) { 'maraude de distribution à partager' }
      it { should eq('non_mat_help') }
    end

    context 'no known word' do
      let(:text) { 'aucun mot connu' }
      it { should be nil }
    end
  end
end
