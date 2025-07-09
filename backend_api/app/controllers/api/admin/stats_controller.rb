class Api::Admin::StatsController < Api::Admin::BaseController
  include Authenticable
  before_action :ensure_admin_role

  def index
    @stats = {
      users: {
        total: User.count,
        patients: User.joins(:roles).where(roles: { name: 'patient' }).count,
        doctors: User.joins(:roles).where(roles: { name: 'doctor' }).count,
        lab_technicians: User.joins(:roles).where(roles: { name: 'lab_technician' }).count,
        admins: User.joins(:roles).where(roles: { name: 'admin' }).count
      },
      exam_requests: {
        total: ExamRequest.count,
        pending: ExamRequest.where(status: 'pending').count,
        scheduled: ExamRequest.where(status: 'scheduled').count,
        completed: ExamRequest.where(status: 'completed').count,
        cancelled: ExamRequest.where(status: 'cancelled').count
      },
      exam_results: {
        total: ExamResult.count,
        last_week: ExamResult.where(performed_at: 1.week.ago..Time.current).count,
        last_month: ExamResult.where(performed_at: 1.month.ago..Time.current).count
      },
      uploads: {
        total: LabFileUpload.count,
        completed: LabFileUpload.where(status: 'completed').count,
        failed: LabFileUpload.where(status: 'failed').count,
        processing: LabFileUpload.where(status: 'processing').count
      },
      exam_types: {
        total: ExamType.count,
        most_requested: most_requested_exam_types
      }
    }
  end

  private

  def ensure_admin_role
    render_forbidden unless current_user.admin?
  end

  def most_requested_exam_types
    ExamType.joins(:exam_requests)
            .group('exam_types.id', 'exam_types.name')
            .order('count_exam_requests_id DESC')
            .limit(5)
            .count('exam_requests.id')
            .map { |k, v| { name: k.last, count: v } }
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
