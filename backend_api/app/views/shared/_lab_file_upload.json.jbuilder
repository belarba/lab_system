json.id lab_file_upload.id
json.filename lab_file_upload.filename
json.file_size lab_file_upload.file_size
json.status lab_file_upload.status
json.total_records lab_file_upload.total_records
json.processed_records lab_file_upload.processed_records
json.failed_records lab_file_upload.failed_records
json.success_rate lab_file_upload.success_rate
json.processed_at lab_file_upload.processed_at
json.created_at lab_file_upload.created_at
json.updated_at lab_file_upload.updated_at

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
  end
end
