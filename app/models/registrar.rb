class Registrar

  attr_accessor :locus, :pail_number, :field_number, :type, :remarks, :id, :state

  def initialize(row_values)
    @locus, @pail_number, @field_number, @type, @remarks, @state, @id = row_values
    @state = 'unregistered' if @state.nil?
  end

  def to_ary
    [locus, pail_number, field_number, type, remarks, id, state]
  end

  def self.all_by_season(season)
    rows = []
    Rails.application.config.couchdb.view('opendig/registrar', {keys: [season], reduce: false})['rows'].map do |row|
      rows << Registrar.new(row['value'])
    end
    rows
  end

end