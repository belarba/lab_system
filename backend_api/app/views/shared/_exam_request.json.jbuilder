json.id exam_request.id
json.scheduled_date exam_request.scheduled_date
json.status exam_request.status
json.notes exam_request.notes
json.created_at exam_request.created_at
json.updated_at exam_request.updated_at

# Patient info
json.patient do
  json.id exam_request.patient.id
  json.name exam_request.patient.name
  json.email exam_request.patient.email
  json.phone exam_request.patient.phone if local_assigns[:include_patient_phone]
end

# Doctor info
json.doctor do
  json.id exam_request.doctor.id
  json.name exam_request.doctor.name
  json.email exam_request.doctor.email
end

# Exam type info
json.exam_type do
  json.partial! 'shared/exam_type', exam_type: exam_request.exam_type
end

# Include result if present
if exam_request.exam_result.present?
  json.result do
    json.partial! 'shared/exam_result', exam_result: exam_request.exam_result
  end
end

# Include cancellation permission for patients
if local_assigns[:current_user]&.patient?
  json.can_cancel local_assigns[:current_user].can_cancel_exam_request?(exam_request)
end
