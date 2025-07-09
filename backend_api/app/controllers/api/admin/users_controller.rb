class Api::Admin::UsersController < Api::Admin::BaseController
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    @users = User.includes(:roles).order(:name)

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
    # @user já está definido pelo before_action
  end

  def create
    @user = User.new(user_params)
    @user.password = params[:password] || 'defaultpassword123'
    @user.password_confirmation = @user.password

    if @user.save
      # Atribuir roles
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
    if @user.update(user_params)
      # Atualizar roles se fornecido
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
    if @user == current_user
      return render json: {
        error: 'You cannot delete your own account'
      }, status: :unprocessable_entity
    end

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
    render_not_found('User not found')
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone)
  end
end
