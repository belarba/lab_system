json.patient do
  json.partial! 'shared/user', user: @patient

  # Médicos associados
  doctors = @patient.patient_doctors.distinct
  json.doctors doctors do |doctor|
    json.partial! 'shared/user', user: doctor
  end

  # Estatísticas
  json.statistics do
    json.total_requests @patient.patient_exam_requests.count
    json.completed_requests @patient.patient_exam_requests.joins(:exam_result).count
    json.pending_requests @patient.patient_exam_requests.where(status: ['pending', 'scheduled']).count
    json.cancelled_requests @patient.patient_exam_requests.where(status: 'cancelled').count
    json.unique_exam_types @patient.patient_exam_requests.joins(:exam_type).distinct.count('exam_types.id')
    json.last_result_date @patient.patient_exam_requests.joins(:exam_result).maximum('exam_results.performed_at')
  end
end
