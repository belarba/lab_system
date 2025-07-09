json.exam_type do
  json.partial! 'shared/exam_type', exam_type: @exam_type

  if current_user&.patient?
    json.can_request current_user.can_request_exam?(@exam_type)

    # Informações sobre última requisição
    last_request = current_user.patient_exam_requests
                              .where(exam_type: @exam_type)
                              .order(created_at: :desc)
                              .first

    if last_request
      json.last_request do
        json.id last_request.id
        json.status last_request.status
        json.scheduled_date last_request.scheduled_date
        json.created_at last_request.created_at
        json.can_request_again_at last_request.created_at + 1.week
      end
    else
      json.last_request nil
    end

    # Resultados recentes
    recent_results = ExamResult.joins(exam_request: :patient)
                               .where(exam_requests: { patient: current_user, exam_type: @exam_type })
                               .order(performed_at: :desc)
                               .limit(3)

    json.recent_results recent_results do |result|
      json.id result.id
      json.value result.value
      json.unit result.unit
      json.performed_at result.performed_at
      json.status helpers.determine_result_status(result.value, @exam_type)
    end
  end
end
