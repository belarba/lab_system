class ExamRequestPolicy < ApplicationPolicy
  def index?
    user.admin? || user.lab_technician?
  end

  def show?
    user.admin? ||
    user == record.doctor ||
    user == record.patient ||
    user.lab_technician?
  end

  def create?
    user.doctor? || user.admin?
  end

  def cancel?
    # Primeira verificação: usuário tem permissão básica?
    return false unless (user.admin? || user == record.doctor || user == record.patient)

    # Segunda verificação: se for paciente, respeitar a regra de 3 horas
    if user.patient? && user == record.patient
      return false unless record.scheduled_date > 3.hours.from_now
    end

    # Terceira verificação: não pode cancelar se completado
    return false if record.completed?

    true
  end

  def blood_work_requests?
    user.admin? || user.lab_technician?
  end

  def my_requests?
    user.patient?
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.lab_technician?
        scope.all
      elsif user.doctor?
        scope.where(doctor: user)
      elsif user.patient?
        scope.where(patient: user)
      else
        scope.none
      end
    end
  end

  private

  def can_patient_cancel?
    record.scheduled_date > 3.hours.from_now
  end
end
