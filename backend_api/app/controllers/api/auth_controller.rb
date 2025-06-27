class Api::AuthController < ApplicationController
  before_action :authenticate_request, only: [:logout]
  include Authenticable
  skip_before_action :authenticate_request, only: [:login, :refresh]

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      tokens = user.generate_tokens
      render json: {
        message: "Login successful",
        user: user_response(user),
        **tokens
      }, status: :ok
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def refresh
    refresh_token = params[:refresh_token]
    return render json: { error: "Refresh token required" }, status: :bad_request unless refresh_token

    decoded_token = JwtService.decode_token(refresh_token)
    return render json: { error: "Invalid refresh token" }, status: :unauthorized unless decoded_token
    return render json: { error: "Invalid token type" }, status: :unauthorized unless decoded_token[:type] == "refresh"

    # Verificar se o token existe no banco e não expirou
    token_record = RefreshToken.active.find_by(token: refresh_token)
    return render json: { error: "Invalid or expired refresh token" }, status: :unauthorized unless token_record

    user = token_record.user

    # Revogar o token antigo
    token_record.destroy

    # Gerar novos tokens
    tokens = user.generate_tokens
    render json: {
      message: "Token refreshed",
      user: user_response(user),
      **tokens
    }, status: :ok
  end

  def logout
    refresh_token = params[:refresh_token]

    if refresh_token
      token_record = current_user.refresh_tokens.find_by(token: refresh_token)
      token_record&.destroy
    else
      # Se não enviou refresh token, revoga todos os tokens do usuário
      current_user.revoke_all_tokens
    end

    render json: { message: "Logged out successfully" }, status: :ok
  end

  private

  def user_response(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      roles: user.roles.pluck(:name)
    }
  end
end
