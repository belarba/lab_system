class ApplicationController < ActionController::API
  # Adicionar suporte para respond_to em APIs Rails
  include ActionController::MimeResponds

  # Desabilitar proteção CSRF para API
  # protect_from_forgery with: :null_session
  before_action :set_default_response_format

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

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
end
