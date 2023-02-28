class ShopifyPolicy < ApplicationPolicy
    def index?
      @account_user.administrator?
    end
  
    def update?
      @account_user.administrator?
    end
  
    def destroy?
      @account_user.administrator?
    end
  
    def create?
      @account_user.administrator?
    end

    def check_access_token?
      @account_user.administrator?
    end
  end
  