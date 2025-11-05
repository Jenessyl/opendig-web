require "rails_helper"

RSpec.describe ApplicationController, type: :controller do

  describe "add" do
    it "adds two numbers" do
      expect(1 + 1).to eq(2)
    end

    it "has all the documents" do
      # five docs, plus the design doc and config doc
      expect(Rails.application.config.couchdb.all_docs["rows"].count).to eq(7)
    end
  end

end