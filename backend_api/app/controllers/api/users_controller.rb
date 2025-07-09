class Api::UsersController < ApplicationController
  include Authenticable

  def me
    render 'api/users/me'
  end

  def update_me
    if current_user.update(user_params)
      render 'api/users/update_me'
    else
      render json: {
        error: 'Failed to update profile',
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :phone, :email)
  end
end
