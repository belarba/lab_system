json.message 'Blood work request cancelled successfully'
json.exam_request do
  json.partial! 'shared/exam_request', exam_request: @exam_request, current_user: current_user
end
