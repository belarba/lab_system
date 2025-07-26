class ExamTypePolicy < ApplicationPolicy
  def index?
    true # Todos podem ver tipos de exame disponíveis
  end

  def show?
    true # Todos podem ver detalhes de tipos de exame
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin? && !record.exam_requests.any?
  end

  class Scope < Scope
    def resolve
      scope.all # Todos podem ver todos os tipos de exame
    end
  end
end
