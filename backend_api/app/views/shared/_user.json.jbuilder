json.id user.id
json.email user.email
json.name user.name
json.phone user.phone
json.created_at user.created_at
json.updated_at user.updated_at

# Incluir roles se estiverem carregados ou solicitado
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

    # Verificar se o usuário tem lab_file_uploads
    if user.respond_to?(:lab_file_uploads)
      json.uploads_count user.lab_file_uploads.count
    else
      # Para usuários que fizeram upload (uploaded_by)
      json.uploads_count LabFileUpload.where(uploaded_by: user).count
    end
  end
end

# Incluir informações adicionais para contextos específicos
if local_assigns[:include_permissions]
  json.permissions do
    json.can_create_requests user.doctor? || user.admin?
    json.can_upload_files user.lab_technician? || user.admin?
    json.can_view_all_data user.admin?
    json.can_manage_users user.admin?
  end
end
