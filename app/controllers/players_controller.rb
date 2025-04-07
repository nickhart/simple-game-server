class PlayersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      redirect_to new_user_session_path, notice: t(".account_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def player_params
    params.require(:player).permit(:name, :email, :password, :password_confirmation)
  end
end
