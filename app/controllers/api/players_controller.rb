module Api
  class PlayersController < BaseController
    def current
      player = current_user.players.first
      if player
        render_success(player)
      else
        render_error("No player found for current user", status: :not_found)
      end
    end

    def show
      @player = Player.find_by(id: params[:id])
      if @player
        render_success(@player)
      else
        render_error("Player not found", status: :not_found)
      end
    end

    def create
      @player = Player.new(player_params.merge(user: current_user))

      if @player.save
        render_success(@player, status: :created)
      else
        render_error(@player.errors.full_messages, status: :unprocessable_entity)
      end
    end

    private

      def player_params
        params.require(:player).permit(:name)
      end
  end
end
