class PailsController < ApplicationController
  def index
    @field = params[:field_id]
    @square = params[:square_id]
    @pails = @db.view('opendig/pails', {reduce: false, keys: ["#{@field}.#{@square}"]})["rows"].map{|row| Pail.new(row["value"])}
    @pails.sort!{|a,b| a.pail_number.to_i <=> b.pail_number.to_i}
  end

  def show
  end

  def edit
  end

  def new
    @field = params[:field_id]
    @square = params[:square_id]
    @locus = {"locus_type" => params[:type]}
  end

  def update
    locus_params = params[:locus].to_enum.to_h
    locus_params = @locus.deep_merge(locus_params)
    if @db.save_doc(locus_params)
      flash[:success] = "Success! Locus Updated"
      redirect_to field_square_locus_path(@field, @square, locus_params['code'])
    else
      flash.now[:error] = "Something went wrong"
      render :edit
    end
  end

  def create
    new_locus = params[:locus]
    if @db.save_doc(new_locus)
      flash[:success] = "Success! New Locus Created"
      redirect_to field_square_loci_path(params[:field_id], params[:square_id])
    else
      flash.now[:error] = "Something went wrong"
      render :new
    end

  end

  private
    def set_locus
      @field = params[:field_id]
      @square = params[:square_id]
      @locus_code = params[:id]
      @locus = @db.view('opendig/locus', key: [@field, @square, @locus_code])["rows"]&.first&.dig("value")
    end
end