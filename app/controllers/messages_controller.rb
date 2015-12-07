class MessagesController < ApplicationController
  def create
    message = Message.new(message_params)
    if message.save
      render json: {status: :ok }, status: 200
    else
      render json: {errors: message.errors.full_messages }, status: 400
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end