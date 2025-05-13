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

        render_success(game_session.as_json.merge(game_id: game_session.game_id))
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game session")
      end

      def create
        Rails.logger.info { "GameSessionsController#create - Current.user: #{Current.user.inspect}" }
        game = Game.find(params[:game_id])
        return render_unprocessable_entity("No associated player") unless current_user.player

        game_session = game.game_sessions.create!(creator: current_user.player)
        game_session.players << current_user.player
        render_created(game_session.as_json.merge(game_id: game_session.game_id))
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game")
      rescue ActiveRecord::RecordInvalid => e
        render_unprocessable_entity(e.record)
      end

      def update
        game_session = GameSession.find(params[:id])

        authorize_update!(game_session)

        attrs = build_update_attrs(game_session)
        return if performed?

        if game_session.update(attrs)
          render_success(game_session.as_json.merge(game_id: game_session.game_id))
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
          render_success(game_session.as_json.merge(game_id: game_session.game_id))
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
        render_success(game_session.as_json.merge(game_id: game_session.game_id))
      rescue ActiveRecord::RecordNotFound
        render_not_found("Game session")
      rescue ActiveRecord::RecordInvalid => e
        render_unprocessable_entity(e.record)
      end

      private

      def authorize_update!(game_session)
        unless current_user.player && game_session.players.include?(current_user.player)
          render_forbidden("Not authorized to update this game session")
        end
      end

      def build_update_attrs(game_session)
        raw = game_session_params.to_h
        attrs = raw.symbolize_keys

        if attrs.key?(:current_player_index)
          validate_current_player_index!(attrs[:current_player_index], game_session)
        else
          next_idx = next_player_index(game_session)
          attrs[:current_player_index] = next_idx
        end

        attrs
      end

      def next_player_index(game_session)
        current = game_session.current_player_index.to_i
        count   = game_session.players.count
        (current + 1) % count
      end

      def validate_current_player_index!(index, game_session)
        max = game_session.players.count - 1
        unless (0..max).cover?(index.to_i)
          render_unprocessable_entity("Invalid current_player_index: must be between 0 and #{max}")
        end
      end

      def game_session_params
        params.require(:game_session)
              .permit(:status, :current_player_index, state: {})
      end
    end
  end
end
