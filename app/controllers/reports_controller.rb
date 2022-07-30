class ReportsController < ApplicationController

  def index
    @seasons = @db.view('opendig/seasons', {group: true})["rows"].map{|row| row["key"]}.sort.reverse
    @report_types = {"Artifacts" => "A", "Objects" => "B", "Samples" => "S", "Bone Bag" => "Z"}
  end

  def show
    @season = params[:id].to_i
    report_type_param = params[:report_type]
    if %w( A B S ).include? report_type_param
      case report_type_param
      when "A"
        @report_type = "artifacts"
      when "B"
        @report_type = "objects"
      when "S"
        @report_type = "samples"
      end
      @rows = @db.view('opendig/report', {reduce: false, start_key: [@season, report_type_param], end_key:[@season, report_type_param, {}] })["rows"]
    elsif %w( Z ).include? report_type_param
      @report_type = "bones"
      @rows = @db.view('opendig/bone_report', {reduce: false, start_key: [@season], end_key:[@season, {}] })["rows"]
      @rows.sort_by!{|row| [row.dig('value', 'area'), row.dig('value', 'square'), row.dig('value', 'locus'), row.dig('value', 'pail')]}
    end

    @rows.sort_by!{ |row| row.dig('value','registration_number').to_s }

    field_set_selector = @descriptions['reports'][@report_type]['field_set']
    @report_type_title = @descriptions['reports'][@report_type]['title']
    style = @descriptions['reports'][@report_type]['style']
    @field_set = @descriptions['field_sets'][field_set_selector]

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "#{@season}_#{@report_type}_report",
        template: "reports/pdf_#{style}",
        layout: 'pdf', formats: [:html],
        show_as_html: debug?,
        footer: { right: '[page] of [topage]' }
        # disposition: 'attachment'
      end
    end
  end

  protected
  def debug?
    params[:debug].present? && Rails.env == 'development'
  end
end