json.exam_requests @requests do |request|
  json.partial! 'shared/exam_request', exam_request: request, current_user: current_user
end

json.pagination do
  json.limit @limit
  json.offset @offset
  json.total @total
end
