module Api
  class PlayersController < BaseController
    rescue_from ActiveRecord::RecordNotFound, with: -> { render_not_found("Player not found") }

    def show
      return me if params[:id] == "me"

      @player = Player.find_by!(id: params[:id], user_id: current_user.id)
      render_success(@player)
    end

    def create
      return render_error("Player already exists", status: :unprocessable_entity) if current_user.player.present?

      @player = current_user.build_player
      @player.assign_attributes(player_params)

      if @player.save
        render_success(@player, status: :created)
      else
        render_error(@player.errors.full_messages, status: :unprocessable_entity)
      end
    end

    def me
      player = current_user.player
      if player
        render_success(player)
      else
        render_not_found("No player found for current user")
      end
    end

    private

    def player_params
      params.require(:player).permit(:name)
    end
  end
end
