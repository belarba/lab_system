json.upload do
  json.partial! 'shared/lab_file_upload', lab_file_upload: @upload, include_details: true
end
