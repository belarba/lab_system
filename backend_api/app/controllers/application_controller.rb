class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  include Pundit::Authorization

  before_action :set_default_response_format

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def set_default_response_format
    request.format = :json
  end

  def render_not_found(exception = nil)
    render json: { error: 'Resource not found' }, status: :not_found
  end

  def render_bad_request(exception = nil)
    render json: { error: 'Bad request', message: exception&.message }, status: :bad_request
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
