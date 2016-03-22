class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:terms]

  def my_profile
    @page_title = "My Zumin Account"
  end

  def update
    current_user.update_attributes(user_params)
    redirect_to my_account_path, notice: "Saved successfully"
  end
  
  def subscriptions
  end
  
  def update_subscriptions
    current_user.update_attributes(user_params)
    redirect_to subscriptions_path, notice: "Saved successfully"
  end
  
  def terms
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :address, :city, :province, :country, :postal_code, :phone_number, :newsletter_subscribed, :unsubscribe_all)
  end
end