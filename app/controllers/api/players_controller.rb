module Api
  class PlayersController < BaseController
    def current
      player = current_user.players.first
      if player
        render json: player
      else
        render json: { error: "No player found for current user" }, status: :not_found
      end
    end

    def show
      @player = Player.find_by(id: params[:id])
      if @player
        render json: @player
      else
        render json: { error: "Player not found" }, status: :not_found
      end
    end

    def create
      @player = Player.new(
        name: params[:name],
        user: current_user
      )

      if @player.save
        render json: @player, status: :created
      else
        render json: { errors: @player.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
