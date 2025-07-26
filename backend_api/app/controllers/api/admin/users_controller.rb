class Api::Admin::UsersController < ApplicationController
  include Authenticable
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    authorize User, :index?

    @users = policy_scope(User).includes(:roles).order(:name)

    # Filtros
    @users = @users.joins(:roles).where(roles: { name: params[:role] }) if params[:role].present?
    @users = @users.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?

    # Paginação
    @limit = [params[:limit].to_i, 100].min
    @limit = 20 if @limit <= 0
    @offset = [params[:offset].to_i, 0].max
    @total = User.count

    @users = @users.limit(@limit).offset(@offset)
  end

  def show
    authorize @user
  end

  def create
    authorize User, :create?

    @user = User.new(user_params)
    @user.password = params[:password] || 'defaultpassword123'
    @user.password_confirmation = @user.password

    if @user.save
      if params[:role_ids].present?
        roles = Role.where(id: params[:role_ids])
        @user.roles = roles
      end

      render :create, status: :created
    else
      render json: {
        error: 'Failed to create user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    authorize @user

    if @user.update(user_params)
      if params[:role_ids].present?
        roles = Role.where(id: params[:role_ids])
        @user.roles = roles
      end

      render :update
    else
      render json: {
        error: 'Failed to update user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user

    if @user.destroy
      render :destroy
    else
      render json: {
        error: 'Failed to delete user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone)
  end
end
