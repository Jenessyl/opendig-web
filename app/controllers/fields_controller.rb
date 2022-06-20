class FieldsController < ApplicationController

  def index
    @fields = @db.view('opendig/fields', {group: true})['rows']
  end

  def new
  end

  def create
    @fields = @db.view('opendig/fields', {group: true})['rows'].map{|field| field["key"]}
    new_field = params[:field].upcase
    unless @fields.include? new_field
      doc = {"temp-doc" => true}.merge({"field" => new_field})
      if @db.save_doc(doc)
        flash[:success] = "Field #{new_field} created!"
        redirect_to fields_path
      else
        flash.now[:error] = "Something went wrong"
        render :new
      end
    else
      flash.now[:error] = "Field #{new_field} already exists!"
      render :new
    end
  end
end