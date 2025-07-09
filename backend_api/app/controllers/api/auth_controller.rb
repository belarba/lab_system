class Api::AuthController < ApplicationController
  before_action :authenticate_request, only: [:logout]
  include Authenticable
  skip_before_action :authenticate_request, only: [:login, :refresh]

  def login
    @user = User.find_by(email: params[:email])

    if @user&.authenticate(params[:password])
      @tokens = @user.generate_tokens
      render 'api/auth/login'
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

    @user = token_record.user

    # Revogar o token antigo
    token_record.destroy

    # Gerar novos tokens
    @tokens = @user.generate_tokens
    render 'api/auth/refresh'
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

    render 'api/auth/logout'
  end
end
