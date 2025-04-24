module Api
  module Admin
    class GamesController < BaseController
      before_action :authenticate_user!
      before_action :authorize_admin!
      before_action :set_game, only: %i[update destroy]

      rescue_from ActiveRecord::RecordNotFound, with: -> { render_not_found(Game) }

      def index
        head :not_implemented
      end

      def create
        game = Game.new(game_params)
        if game.save
          render_created(game)
        else
          render_unprocessable_entity(game.errors)
        end
      end

      def update
        if @game.update(game_params)
          render_success(@game)
        else
          render_unprocessable_entity(@game.errors)
        end
      end

      def destroy
        @game.destroy
        head :no_content
      end

      private

      def game_params
        params.require(:game).permit(:name, :state_json_schema)
      end

      def set_game
        @game = Game.find(params[:id])
      end
    end
  end
end
