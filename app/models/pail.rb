# doc.field, doc.square, doc.code, doc._id, doc.locus_type, doc.designation, doc.age

class Pail

  attr_accessor :pail_number, :pail_date, :locus

  def initialize(row)
    @pail_number, @locus, @pail_date = row
  end

  def to_ary
    [pail_number, locus, pail_date]
  end

end