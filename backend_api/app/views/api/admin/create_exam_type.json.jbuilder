json.message 'Exam type created successfully'
json.exam_type do
  json.partial! 'shared/exam_type', exam_type: @exam_type, include_requests_count: true
end
