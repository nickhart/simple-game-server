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

  def me
    if current_user&.player
      render_success(current_user.player)
    else
      render_not_found("Player not found")
    end
  end

  private

  def player_params
    params.require(:player).permit(:name, :email, :password, :password_confirmation)
  end
end
