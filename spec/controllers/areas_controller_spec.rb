require "rails_helper"

RSpec.describe AreasController, type: :controller do

  describe "GET index" do
    it "assigns @areas" do
      get :index
      expect(assigns(:areas)).to eq([1])
    end
  end

end