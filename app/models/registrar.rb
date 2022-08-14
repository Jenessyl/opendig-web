class Registrar

  attr_accessor :code, :pail_number, :field_number, :registration_number, :type, :remarks, :id, :state, :square, :area

  def initialize(row_values)
    @area, @square, @code, @pail_number, @field_number, @registration_number, @type, @remarks, @state, @id = row_values
    @state = 'unregistered' unless @state.present?
  end



  def to_ary
    [locus, pail_number, field_number, type, remarks, id, state]
  end

  def full_locus_code
    "#{area}.#{square}.#{code}"
  end

  def formatted_locus_code
    "#{area}.#{square}.#{sprintf('%03d',code.to_i)}"
  end

  def self.all_by_season(season)
    rows = []
    Rails.application.config.couchdb.view('opendig/registrar', {keys: [season], reduce: false})['rows'].map do |row|
      rows << Registrar.new(row['value'])
    end
    rows
  end

end