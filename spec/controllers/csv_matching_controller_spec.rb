require 'rails_helper'

RSpec.describe Api::V1::CsvMatchingController, type: :controller do
  describe "GET show" do
    before do
      stub_request(:get, "http://foo.com/bar.csv").
          to_return(:status => 200, :body => File.read("spec/fixtures/atd.csv"), :headers => {})

      stub_request(:put, /https:\/\/entourage-csv.s3-eu-west-1.amazonaws.com/).
          with(:body => "atd_id1,entourage_id,email,phone,status\n",).
          to_return(:status => 200, :body => "", :headers => {})
    end

    before { @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{ENV["ATD_USERNAME"]}:#{ENV["ATD_PASSWORD"]}") }
    before { get :show, {url: "http://foo.com/bar.csv"} }
    it { expect(response.body).to match(/https:\/\/entourage-csv.s3-eu-west-1.amazonaws.com/) }
  end
end
