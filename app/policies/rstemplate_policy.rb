class RstemplatePolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      # scope.all # If users can see all records
      # show only the records that have the same user_id as current user (user_id: user.id)
      scope.where(user: user).or(scope.where(user_id: User.where(admin: true).first.id).where(public: true)) # If users can only see their records or admin's records
      # scope.where("name LIKE 't%'") # If users can only see records starting with `t`
    end
  end
  def show?
    record.user == user
  end

  def copy?
    return create?
  end

  def new?
    return create?
  end

  def create?
    return true
  end

  def edit?
    return update?
  end

  def update?
    record.user == user
  end

  def destroy?
    record.user == user
  end
end
