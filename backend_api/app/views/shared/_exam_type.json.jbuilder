json.id exam_type.id
json.name exam_type.name
json.description exam_type.description
json.unit exam_type.unit
json.reference_range exam_type.reference_range
json.created_at exam_type.created_at
json.updated_at exam_type.updated_at

# Incluir contagem apenas se solicitado
if local_assigns[:include_requests_count]
  json.requests_count exam_type.exam_requests.count
end
