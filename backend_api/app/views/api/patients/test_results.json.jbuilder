json.patient do
  json.partial! 'shared/user', user: @patient
end

json.test_results @results do |result|
  json.id result.id
  json.value result.value
  json.unit result.unit
  json.performed_at result.performed_at
  json.notes result.notes

  json.exam_request do
    json.id result.exam_request.id
    json.scheduled_date result.exam_request.scheduled_date
    json.doctor do
      json.id result.exam_request.doctor.id
      json.name result.exam_request.doctor.name
    end
  end

  json.exam_type do
    json.partial! 'shared/exam_type', exam_type: result.exam_request.exam_type
  end

  json.lab_technician do
    json.id result.lab_technician.id
    json.name result.lab_technician.name
  end

  json.status helpers.determine_result_status(result.value, result.exam_request.exam_type)
end

json.pagination do
  json.limit @limit
  json.offset @offset
  json.total @total
end


# Trends por tipo de exame
json.trends @results_by_type do |exam_type, type_results|
  json.exam_type do
    json.partial! 'shared/exam_type', exam_type: exam_type
  end

  json.results_count type_results.count
  json.latest_value type_results.first&.value
  json.latest_date type_results.first&.performed_at
  json.average_value type_results.map(&:value).sum / type_results.count.to_f

  json.values_over_time type_results.first(10) do |result|
    json.value result.value
    json.date result.performed_at
    json.status helpers.determine_result_status(result.value, exam_type)
  end
end

# Summary
json.summary @summary_data
