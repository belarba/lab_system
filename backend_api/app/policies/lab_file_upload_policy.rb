class LabFileUploadPolicy < ApplicationPolicy
  def index?
    user.lab_technician? || user.admin?
  end

  def show?
    user.admin? || user == record.uploaded_by
  end

  def create?
    user.lab_technician? || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.lab_technician?
        scope.where(uploaded_by: user)
      else
        scope.none
      end
    end
  end
end
