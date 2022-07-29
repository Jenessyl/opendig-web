require 'date'

class Find

  attr_accessor :locus, :pail_number, :pail_date, :field_number, :type, :remarks, :id, :season

  def initialize(row)
    @locus, @pail_number, @pail_date, @field_number, @type, @remarks, @id = row
    @season = Date.parse(@pail_date)&.year || nil
  end

  def to_ary
    [locus, pail_number, pail_date, field_number, type, remarks, id]
  end

end