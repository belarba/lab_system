class Api::UsersController < ApplicationController
  include Authenticable

  def me
    render json: {
      user: user_response(current_user)
    }, status: :ok
  end

  def update_me
    if current_user.update(user_params)
      render json: {
        message: 'Profile updated successfully',
        user: user_response(current_user)
      }, status: :ok
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

  def user_response(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      roles: user.roles.pluck(:name),
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
