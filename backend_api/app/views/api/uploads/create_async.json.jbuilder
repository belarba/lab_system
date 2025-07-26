json.message 'File uploaded successfully and queued for processing'
json.upload do
  json.partial! 'shared/lab_file_upload', lab_file_upload: @upload.reload
end
json.processing_info do
  json.async true
  json.estimated_time "#{(@upload.file_size / 1024.0 / 1024.0 * 2).round} minutes"
  json.status_check_url api_upload_url(@upload)
end

# app/views/api/uploads/reprocess.json.jbuilder
json.message 'File reprocessed successfully'
json.upload do
  json.partial! 'shared/lab_file_upload', lab_file_upload: @upload.reload, include_details: true
end

# app/views/shared/_lab_file_upload.json.jbuilder (updated)
json.id lab_file_upload.id
json.filename lab_file_upload.filename
json.file_size lab_file_upload.file_size
json.file_size_human lab_file_upload.file_size_human
json.status lab_file_upload.status
json.status_description lab_file_upload.status_description
json.status_color lab_file_upload.status_color
json.total_records lab_file_upload.total_records
json.processed_records lab_file_upload.processed_records
json.failed_records lab_file_upload.failed_records
json.success_rate lab_file_upload.success_rate
json.failure_rate lab_file_upload.failure_rate
json.processed_at lab_file_upload.processed_at
json.processing_duration lab_file_upload.processing_duration
json.created_at lab_file_upload.created_at
json.updated_at lab_file_upload.updated_at
json.can_reprocess lab_file_upload.can_reprocess?
json.file_exists lab_file_upload.file_exists?

# Uploaded by info
json.uploaded_by do
  json.id lab_file_upload.uploaded_by.id
  json.name lab_file_upload.uploaded_by.name
  json.email lab_file_upload.uploaded_by.email
end

# Include detailed info if requested
if local_assigns[:include_details]
  json.error_details lab_file_upload.error_details
  json.processing_summary lab_file_upload.processing_summary_data

  json.records_summary do
    json.total lab_file_upload.total_records
    json.processed lab_file_upload.processed_records
    json.failed lab_file_upload.failed_records
    json.pending lab_file_upload.total_records - lab_file_upload.processed_records - lab_file_upload.failed_records
    json.success_rate lab_file_upload.success_rate
    json.failure_rate lab_file_upload.failure_rate
  end

  # Sample errors for quick debugging
  json.sample_errors lab_file_upload.sample_errors(3) do |error|
    json.timestamp error['timestamp']
    json.message error['message']
  end

  # File information
  json.file_info do
    json.path lab_file_upload.file_path
    json.exists lab_file_upload.file_exists?
    json.download_url api_upload_download_url(lab_file_upload) if lab_file_upload.file_exists?
  end
end
