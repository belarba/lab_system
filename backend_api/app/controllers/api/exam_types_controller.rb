class Api::ExamTypesController < ApplicationController
  include Authenticable
  before_action :set_exam_type, only: [:show]

  def index
    exam_types = ExamType.all.order(:name)

    # Incluir informação se o usuário atual pode solicitar cada tipo
    exam_types_with_availability = exam_types.map do |exam_type|
      response = exam_type_response(exam_type)

      if current_user&.patient?
        response[:can_request] = current_user.can_request_exam?(exam_type)
        response[:last_request] = last_request_info(exam_type)
      end

      response
    end

    render json: {
      exam_types: exam_types_with_availability
    }, status: :ok
  end

  def show
    response = exam_type_response(@exam_type)

    if current_user&.patient?
      response[:can_request] = current_user.can_request_exam?(@exam_type)
      response[:last_request] = last_request_info(@exam_type)
      response[:recent_results] = recent_results_info(@exam_type)
    end

    render json: {
      exam_type: response
    }, status: :ok
  end

  private

  def set_exam_type
    @exam_type = ExamType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Exam type not found' }, status: :not_found
  end

  def exam_type_response(exam_type)
    {
      id: exam_type.id,
      name: exam_type.name,
      description: exam_type.description,
      unit: exam_type.unit,
      reference_range: exam_type.reference_range
    }
  end

  def last_request_info(exam_type)
    return nil unless current_user&.patient?

    last_request = current_user.patient_exam_requests
                              .where(exam_type: exam_type)
                              .order(created_at: :desc)
                              .first

    return nil unless last_request

    {
      id: last_request.id,
      status: last_request.status,
      scheduled_date: last_request.scheduled_date,
      created_at: last_request.created_at,
      can_request_again_at: last_request.created_at + 1.week
    }
  end

  def recent_results_info(exam_type)
    return nil unless current_user&.patient?

    recent_results = ExamResult.joins(exam_request: :patient)
                               .where(exam_requests: { patient: current_user, exam_type: exam_type })
                               .order(performed_at: :desc)
                               .limit(3)

    recent_results.map do |result|
      {
        id: result.id,
        value: result.value,
        unit: result.unit,
        performed_at: result.performed_at,
        status: determine_result_status(result.value, exam_type)
      }
    end
  end

  def determine_result_status(value, exam_type)
    return 'normal' unless exam_type.reference_range.present?

    case exam_type.reference_range.downcase
    when /< (\d+\.?\d*)/
      max_value = $1.to_f
      value <= max_value ? 'normal' : 'high'
    when /(\d+\.?\d*)-(\d+\.?\d*)/
      min_value = $1.to_f
      max_value = $2.to_f
      if value < min_value
        'low'
      elsif value > max_value
        'high'
      else
        'normal'
      end
    else
      'normal'
    end
  end
end
