json.exam_types @exam_types do |exam_type|
  json.partial! 'shared/exam_type', exam_type: exam_type, include_requests_count: true
end
