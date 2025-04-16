class GamesController < BaseController
    before_action :authorize_admin!
  
    def index
      render json: Game.all
    end
  
    def show
      render json: Game.find(params[:id])
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