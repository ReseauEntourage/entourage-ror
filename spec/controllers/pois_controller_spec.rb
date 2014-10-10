RSpec.describe "PoisController" do
  describe "GET index" do
    it "assigns @categories" do
      expect(assigns(:categories)).to eq([categories])
    end
  end
end