module Api
  module Games
    class SessionsController < BaseController
      def index
        game = Game.find(params[:game_id])
        game_sessions = game.game_sessions
        render_success(game_sessions)
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game")
      end

      def show
        game_session = GameSession.find(params[:id])
        # Optional: validate access rights
        unless game_session.players.include?(current_user.player)
          head :forbidden and return
        end
        render_success(game_session)
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game session")
      end

      def create
        game = Game.find(params[:game_id])
        game_session = game.game_sessions.create!(player: current_user.player)
        render_created(game_session)
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game")
      rescue ActiveRecord::RecordInvalid => e
        render_unprocessable_entity(e.record)
      end

      def update
        game_session = GameSession.find(params[:id])
        # TODO: Add authorization logic here if needed
        unless game_session.players.include?(current_user.player)
          return render_forbidden("Not authorized to update this game session")
        end

        if game_session.update(game_session_params)
          render_success(game_session)
        else
          render_unprocessable_entity(game_session)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game session")
      end

      def join
        game_session = GameSession.find(params[:id])
        unless current_user.player
          return render_unprocessable_entity("No associated player")
        end

        if game_session.add_player(current_user.player)
          render_success(game_session)
        else
          render_forbidden("Unable to join game session")
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game session")
      end

      def leave
        game_session = GameSession.find(params[:id])
        unless current_user.player
          return render_unprocessable_entity("No associated player")
        end

        if game_session.remove_player(current_user.player)
          render_success(message: "Left the game session")
        else
          render_forbidden("Unable to leave game session")
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game session")
      end

      private

      def game_session_params
        params.require(:game_session).permit(:state, :status)
      end
    end
  end
end
