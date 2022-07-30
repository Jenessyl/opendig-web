if ENV['S3_URL']
  Aws.config.update(
    endpoint: ENV['S3_URL'],
    force_path_style: true
  )
end

Aws.config.update(
  region: 'us-east-1'
)

s3 = Aws::S3::Resource.new

bucket_name = ENV['S3_BUCKET_NAME'] || "opendig_#{Rails.env}"
Rails.application.config.s3_bucket = s3.bucket(bucket_name)
