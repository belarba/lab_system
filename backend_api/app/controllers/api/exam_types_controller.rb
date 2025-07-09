class Api::ExamTypesController < ApplicationController
  include Authenticable
  before_action :set_exam_type, only: [:show]

  def index
    @exam_types = ExamType.all.order(:name)
    render 'api/exam_types/index'
  end

  def show
    render 'api/exam_types/show'
  end

  private

  def set_exam_type
    @exam_type = ExamType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Exam type not found' }, status: :not_found
  end
end
