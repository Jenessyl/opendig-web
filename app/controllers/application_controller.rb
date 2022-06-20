class ApplicationController < ActionController::Base
  before_action :set_db, :set_descriptions
  http_basic_authenticate_with name: "balua", password: "k3r@k2019"

  private
  def set_db
    @db = Rails.application.config.couchdb
  end

  def set_descriptions
    @descriptions = Rails.application.config.descriptions
  end

end
