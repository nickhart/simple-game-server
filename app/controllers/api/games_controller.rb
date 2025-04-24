module Api
  class GamesController < BaseController
    before_action :authenticate_user!

    def index
      render_success(Game.all)
    end

    def show
      game = Game.find_by(id: params[:id])
      if game
        render_success(game)
      else
        render_error("Game not found", status: :not_found)
      end
    end
  end
end
