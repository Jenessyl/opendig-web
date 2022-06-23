class SquaresController < ApplicationController

  before_action :set_field_and_squares

  def index
  end

  def new
  end

  def pails
    @pails = @db.view('opendig/pails', {group: true, start_key: [params[:id]], end_key: [params[:id], {}]})["rows"].map{|row| row["key"][1]}
  end

  def create
    new_square = params[:square].upcase
    unless @squares.include? new_square
      doc = {"temp-doc" => true}.merge({"square" => new_square, "field" => @field})
      if @db.save_doc(doc)
        flash[:success] = "Square #{new_square} in Field #{@field} created!"
        redirect_to field_squares_path(@field)
      else
        flash.now[:error] = "Something went wrong"
        render :new
      end
    else
      flash.now[:error] = "Square #{new_square} in Field #{@field} already exists!"
      render :new
    end
  end

  private
    def set_field_and_squares
      @field = params[:field_id]
      @squares = @db.view('opendig/squares', {group: true, start_key: [@field], end_key: [@field, {}]})["rows"].map{|row| row["key"][1]}
    end

end