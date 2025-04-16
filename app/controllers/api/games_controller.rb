module Api
  class GamesController < BaseController
    before_action :authenticate_user!
    before_action :authorize_admin!, except: %i[index show]

    def index
      render json: Game.all
    end

    def show
      game = Game.find_by(id: params[:id])
      if game
        render_success(game)
      else
        render_error("Game not found", status: :not_found)
      end
    end

    def create
      game = Game.new(game_params)
      if game.save
        render json: game, status: :created
      else
        render json: game.errors, status: :unprocessable_entity
      end
    end

    def update
      game = Game.find(params[:id])
      if game.update(game_params)
        render json: game
      else
        render json: game.errors, status: :unprocessable_entity
      end
    end

    def destroy
      game = Game.find(params[:id])
      game.destroy
      head :no_content
    end

    private

    def game_params
      params.require(:game).permit(:name, :state_json_schema)
    end
  end
end
