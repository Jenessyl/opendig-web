class BulkUploadsController < ApplicationController
  def new
  end

  def create
    uploaded_files = params[:files]
    uploaded_file_keys = []

    uploaded_files.each do |file|
      s3_object = Aws::S3::Resource.new.bucket('your_bucket_name').object(file.original_filename)

      s3_object.upload_file(file.tempfile.path, acl: 'public-read') do |progress|
        # Progress tracking logic here
        puts "Uploaded #{progress.loaded} of #{progress.total} bytes"
      end

      uploaded_file_keys << s3_object.key
    end

    render json: { keys: uploaded_file_keys }
  end
end