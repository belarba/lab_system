class DoctorPolicy < ApplicationPolicy
  def patients?
    can_view_doctor_patients?
  end

  def blood_work_requests?
    can_view_doctor_requests?
  end

  def export_patient_results?
    can_view_doctor_requests?
  end

  def export_all_results?
    can_view_doctor_requests?
  end

  def search_patients?
    user.doctor? || user.admin?
  end

  def add_patient?
    user.doctor? || user.admin?
  end

  def all_patients?
    user.doctor? || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.joins(:roles).where(roles: { name: 'doctor' })
      else
        scope.where(id: user.id)
      end
    end
  end

  private

  def can_view_doctor_patients?
    user.admin? || user == record
  end

  def can_view_doctor_requests?
    user.admin? || user == record
  end
end
