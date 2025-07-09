json.id user.id
json.email user.email
json.name user.name
json.phone user.phone
json.created_at user.created_at
json.updated_at user.updated_at

# Incluir roles se estiverem carregados
if user.association(:roles).loaded? || local_assigns[:include_roles]
  json.roles user.roles do |role|
    json.partial! 'shared/role', role: role
  end
end

# Incluir estatísticas detalhadas se solicitado
if local_assigns[:include_stats]
  json.stats do
    json.exam_requests_as_patient user.patient_exam_requests.count
    json.exam_requests_as_doctor user.doctor_exam_requests.count
    json.exam_results_as_lab_tech user.lab_exam_results.count
    json.uploads_count user.respond_to?(:lab_file_uploads) ? user.lab_file_uploads.count : 0
  end
end
