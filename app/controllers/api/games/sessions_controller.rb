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
        head :forbidden and return unless current_user.player && game_session.players.include?(current_user.player)

        render_success(game_session)
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game session")
      end

      def create
        Rails.logger.debug { "GameSessionsController#create - Current.user: #{Current.user.inspect}" }
        game = Game.find(params[:game_id])
        return render_unprocessable_entity("No associated player") unless current_user.player

        game_session = game.game_sessions.create!(creator: current_user.player)
        game_session.players << current_user.player
        render_created(game_session)
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game")
      rescue ActiveRecord::RecordInvalid => e
        render_unprocessable_entity(e.record)
      end

      def update
        game_session = GameSession.find(params[:id])
        # TODO: Add authorization logic here if needed
        unless current_user.player && game_session.players.include?(current_user.player)
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
        return render_unprocessable_entity("No associated player") unless current_user.player

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
        return render_unprocessable_entity("No associated player") unless current_user.player

        if game_session.players.destroy(current_user.player)
          render_success(message: "Left the game session")
        else
          render_forbidden("Unable to leave game session")
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game session")
      end

      def start
        game_session = GameSession.find(params[:id])

        unless current_user.player && game_session.creator == current_user.player
          return render_forbidden("Not authorized to start this game session")
        end

        return render_unprocessable_entity("Game session is not in a waiting state") if game_session.status != "waiting"

        player_count = game_session.players.count
        if player_count < game_session.game.min_players || player_count > game_session.game.max_players
          return render_unprocessable_entity("Invalid number of players to start the game")
        end

        game_session.update!(status: "active")
        render_success(game_session)
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game session")
      rescue ActiveRecord::RecordInvalid => e
        render_unprocessable_entity(e.record)
      end

      private

      def game_session_params
        params.require(:game_session).permit(:state, :status)
      end
    end
  end
end
