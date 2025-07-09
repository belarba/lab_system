json.message 'Blood work request created successfully'
json.blood_work_request do
  json.partial! 'shared/exam_request', exam_request: @blood_work_request
end
