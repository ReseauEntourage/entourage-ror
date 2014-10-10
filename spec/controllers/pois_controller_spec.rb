RSpec.describe "PoisController" do
  describe "GET index" do
    it "assigns @categories" do
      expect(assigns(:teams)).to eq([team])
    end
  end
end