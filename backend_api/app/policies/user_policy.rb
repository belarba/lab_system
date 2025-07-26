class UserPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin? || user == record || can_view_as_doctor_or_patient?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || user == record
  end

  def destroy?
    user.admin? && user != record
  end

  def me?
    true
  end

  def update_me?
    true
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end

  private

  def can_view_as_doctor_or_patient?
    if user.doctor? && record.patient?
      user.doctor_patients.include?(record)
    elsif user.patient? && record.doctor?
      user.patient_doctors.include?(record)
    elsif user.lab_technician? && record.patient?
      true
    else
      false
    end
  end
end
