json.doctor do
  json.partial! 'shared/user', user: @doctor, include_roles: true
end

json.patients @patients do |patient|
  json.partial! 'shared/user', user: patient

  # Estatísticas específicas da relação médico-paciente
  recent_requests = patient.patient_exam_requests.where(doctor: @doctor).order(scheduled_date: :desc).limit(5)
  json.recent_requests_count recent_requests.count
  json.last_request_date recent_requests.first&.scheduled_date
  json.total_results patient.patient_exam_requests.joins(:exam_result).where(doctor: @doctor).count
end
