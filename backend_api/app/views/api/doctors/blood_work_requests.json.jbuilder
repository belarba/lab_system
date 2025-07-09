json.doctor do
  json.partial! 'shared/user', user: @doctor, include_roles: true
end

json.blood_work_requests @requests do |request|
  json.partial! 'shared/exam_request', exam_request: request, include_patient_phone: true
end
