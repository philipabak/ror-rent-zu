class MessagesController < ApplicationController
  before_action :authenticate_user!
  respond_to :html, :json

  def index
    respond_to do |format|
      format.json { render json: current_user.mailbox.conversations.to_json(:include => [:messages]) }
      format.html {}
    end
  end

  def create
    @recipient = User.find params[:msg_receiver]
    @receipt = current_user.send_message(@recipient, params[:msg_body], "test subject")
    if (@receipt.errors.blank?)
      flash[:success]= "Message sent!"
    else
      flash[:error]= "Error!"
    end
  end
end
