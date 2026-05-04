require 'rails_helper'

RSpec.describe "Admin Assets", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "loads the login page successfully and ensures script tags exist" do
    visit '/admin/sessions/new'

    # Check that basic layout loads correctly
    expect(page).to have_content("Connexion")

    # Verify the presence of stylesheet and javascript tags
    expect(page).to have_xpath("//link[@rel='stylesheet']", visible: false)
    expect(page).to have_xpath("//script", visible: false)

    # We can also verify that data-turbo-track is set
    expect(page.html).to include('data-turbo-track="reload"')
  end
end
