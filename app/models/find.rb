require 'date'
require "aws-sdk-s3"
require "net/http"

class Find

  attr_accessor :locus, :pail_number, :pail_date, :field_number, :type, :remarks, :id, :season, :gis_id

  def initialize(row)
    @locus, @pail_number, @pail_date, @field_number, @type, @remarks, @gis_id, @id = row
    @season = Date.parse(@pail_date)&.year || nil
  end

  def to_ary
    [locus, pail_number, pail_date, field_number, type, remarks, gis_id, id]
  end


  def self.get_presigned_url(registration_number)
    bucket = Rails.application.config.s3_bucket
    object_key = "#{registration_number}.jpg"
    if bucket.object(object_key).exists?
      begin
        url = bucket.object(object_key).presigned_url(:get)
      rescue Aws::Errors::ServiceError => e
        Rails.logger.error "Couldn't create presigned URL for #{bucket.name}:#{object_key}. Here's why: #{e.message}"
        url = 'https://upload.wikimedia.org/wikipedia/commons/6/65/No-Image-Placeholder.svg'

      end
    else
      url = 'https://upload.wikimedia.org/wikipedia/commons/6/65/No-Image-Placeholder.svg'
    end

    url
  end
end