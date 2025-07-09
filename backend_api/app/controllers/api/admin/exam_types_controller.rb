class Api::Admin::ExamTypesController < Api::Admin::BaseController
  include Authenticable
  before_action :ensure_admin_role
  before_action :set_exam_type, only: [:show, :update, :destroy]

  def index
    @exam_types = ExamType.all.order(:name)
  end

  def show
    # @exam_type já está definido pelo before_action
  end

  def create
    @exam_type = ExamType.new(exam_type_params)

    if @exam_type.save
      render :create, status: :created
    else
      render json: {
        error: 'Failed to create exam type',
        errors: @exam_type.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @exam_type.update(exam_type_params)
      render :update
    else
      render json: {
        error: 'Failed to update exam type',
        errors: @exam_type.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @exam_type.exam_requests.any?
      return render json: {
        error: 'Cannot delete exam type that has associated requests'
      }, status: :unprocessable_entity
    end

    if @exam_type.destroy
      render :destroy
    else
      render json: {
        error: 'Failed to delete exam type',
        errors: @exam_type.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def ensure_admin_role
    render_forbidden unless current_user.admin?
  end

  def set_exam_type
    @exam_type = ExamType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Exam type not found')
  end

  def exam_type_params
    params.require(:exam_type).permit(:name, :description, :unit, :reference_range)
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
