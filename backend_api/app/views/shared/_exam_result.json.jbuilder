json.id exam_result.id
json.value exam_result.value
json.unit exam_result.unit
json.performed_at exam_result.performed_at
json.notes exam_result.notes

# Lab technician info
json.lab_technician do
  json.id exam_result.lab_technician.id
  json.name exam_result.lab_technician.name
end

# Include detailed exam request info if requested
if local_assigns[:include_exam_request]
  json.exam_request do
    json.id exam_result.exam_request.id
    json.scheduled_date exam_result.exam_request.scheduled_date
    json.doctor do
      json.id exam_result.exam_request.doctor.id
      json.name exam_result.exam_request.doctor.name
    end
  end

  json.exam_type do
    json.partial! 'shared/exam_type', exam_type: exam_result.exam_request.exam_type
  end
end

# Include status determination if exam_type is available
if local_assigns[:include_status] && exam_result.exam_request&.exam_type
  json.status determine_result_status(exam_result.value, exam_result.exam_request.exam_type)
end
