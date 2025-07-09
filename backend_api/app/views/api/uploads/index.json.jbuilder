json.uploads @uploads do |upload|
  json.partial! 'shared/lab_file_upload', lab_file_upload: upload
end

json.pagination do
  json.limit @limit
  json.offset @offset
  json.total @total
end
