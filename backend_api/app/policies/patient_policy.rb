class PatientPolicy < ApplicationPolicy
  def show?
    can_view_patient?
  end

  def blood_work_requests?
    can_view_patient?
  end

  def test_results?
    can_view_patient_results?
  end

  def search_patients?
    user.doctor? || user.admin?
  end

  def all_patients?
    user.doctor? || user.admin?
  end

  def add_patient?
    user.doctor? || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.joins(:roles).where(roles: { name: 'patient' })
      elsif user.doctor?
        scope.joins(:roles).where(roles: { name: 'patient' })
      elsif user.patient?
        scope.where(id: user.id)
      else
        scope.none
      end
    end
  end

  private

  def can_view_patient?
    user.admin? ||
    user == record ||
    (user.doctor? && user.doctor_patients.include?(record))
  end

  def can_view_patient_results?
    user.admin? ||
    user == record ||
    user.lab_technician? ||
    (user.doctor? && user.doctor_patients.include?(record))
  end
end
