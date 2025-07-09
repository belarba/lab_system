json.message 'File uploaded and processed successfully'
json.upload do
  json.partial! 'shared/lab_file_upload', lab_file_upload: @upload.reload
end
