require "rails_helper"

RSpec.describe AreasController, type: :controller do

  describe "GET index" do
    it "assigns @areas" do
      get :index
      expect(assigns(:areas).map{|a| a['key']}).to eq(["24", "25", "42", "55"])
    end
  end

end