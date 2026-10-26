require 'rails_helper'

describe Translation do
  describe '.text_presence' do
    it { expect(Translation.text_presence('Hello')).to eq('Hello') }
    it { expect(Translation.text_presence('<p>Hello</p>')).to eq('<p>Hello</p>') }

    context 'failed translation' do
      it { expect(Translation.text_presence(nil)).to be_nil }
      it { expect(Translation.text_presence('')).to be_nil }
      it { expect(Translation.text_presence('<p></p>')).to be_nil }
      it { expect(Translation.text_presence('<p dir="ltr"> </p><br>')).to be_nil }
      it { expect(Translation.text_presence('<p>&nbsp;</p>')).to be_nil }
    end
  end
end
