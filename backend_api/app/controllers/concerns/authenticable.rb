module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
    attr_reader :current_user
  end

  private

  def authenticate_request
    token = extract_token_from_header
    return render_unauthorized unless token

    decoded_token = JwtService.decode_token(token)
    return render_unauthorized unless decoded_token
    return render_unauthorized if JwtService.token_expired?(token)
    return render_unauthorized unless decoded_token[:type] == "access"

    @current_user = User.find(decoded_token[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_unauthorized
  end

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header

    auth_header.split(" ").last if auth_header.start_with?("Bearer ")
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def authenticate_role(required_role)
    return render_forbidden unless current_user.has_role?(required_role)
  end

  def render_forbidden
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
