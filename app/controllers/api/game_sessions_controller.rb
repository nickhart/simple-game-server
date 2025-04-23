module Api
  class GameSessionsController < BaseController
    before_action :set_game_session, except: %i[index create cleanup]
    before_action :set_game, only: %i[create]
    before_action :ensure_player_present, only: %i[create join leave start]

    def index
      @game_sessions = GameSession.all
      render json: @game_sessions, include: { players: { only: %i[id name] }, game: { only: %i[id name] } }
    end

    def show
      game_session = GameSession.find(params[:id])
      render_success(game_session)
    rescue ActiveRecord::RecordNotFound
      render_error("Game session not found", status: :not_found)
    end

    def create
      player = @player
      return render_error("Player not found", status: :forbidden) unless player

      @game_session = GameSession.new(game_session_params)
      @game_session.game = @game
      @game_session.creator = player

      if @game_session.save
        @game_session.players << player
        render_success(@game_session, include: { players: { only: %i[id name] }, game: { only: %i[id name] } },
                                      status: :created)
      else
        render_error(@game_session.errors.full_messages, status: :unprocessable_entity)
      end
    end

    def update
      if @game_session.update(game_session_params)
        @game_session.advance_turn
        render_success(@game_session, include: { players: { only: %i[id name] }, game: { only: %i[id name] } })
      else
        render_error(@game_session.errors.full_messages, status: :unprocessable_entity)
      end
    end

    def join
      player = @player
      render_error("Player not found", status: :forbidden) unless player

      if @game_session.players.include?(player)
        render_error("Player is already in this game session", status: :unprocessable_entity)
      elsif @game_session.players.count >= @game_session.max_players
        render_error("Game session is full", status: :unprocessable_entity)
      else
        @game_session.players << player
        render_success(@game_session, include: { players: { only: %i[id name] }, game: { only: %i[id name] } })
      end
    end

    def leave
      player = @player
      render_error("Player not found", status: :forbidden) unless player

      unless @game_session.players.include?(player)
        return render_error("Player not in game", status: :unprocessable_entity)
      end

      @game_session.players.delete(player)
      render_success({ message: "Player left the game" })
    end

    def start
      player = @player
      render_error("Player not found", status: :forbidden) unless player

      unless @game_session.creator_id == player.id
        return render_error("Only the creator can start the game", status: :unauthorized)
      end

      unless @game_session.status_waiting?
        return render_error("Game is not in waiting status",
                            status: :unprocessable_entity)
      end

      if @game_session.players.count < @game_session.min_players
        return render_error("Not enough players", status: :unprocessable_entity)
      end
      if @game_session.players.count > @game_session.max_players
        return render_error("Too many players", status: :unprocessable_entity)
      end

      if @game_session.start(player.id)
        render_success(@game_session, include: { players: { only: %i[id name] } })
      else
        render_error(@game_session.errors.full_messages, status: :unprocessable_entity)
      end
    end

    def cleanup
      cleanup_params = params.permit(:before)
      before_time = cleanup_params[:before].present? ? Time.zone.parse(cleanup_params[:before]) : 1.day.ago
      old_games = GameSession.where(status: :waiting)
                             .where(created_at: ...before_time)

      old_games.destroy_all
      render_success({ message: "Cleanup completed" })
    end

    private

    def set_game_session
      @game_session = GameSession.find(params[:id])
    end

    def set_game
      game_params = params.require(:game_session).permit(:game_id, :game_name)

      if game_params[:game_id].present?
        @game = Game.find_by(id: game_params[:game_id])
      elsif game_params[:game_name].present?
        @game = Game.find_by(name: game_params[:game_name])
      end

      render_error("Game not found", status: :not_found) unless @game
    end

    def game_session_params
      params.require(:game_session).permit(:min_players, :max_players, :state, :game_id, :game_name)
    end

    def ensure_player_present
      @player = Player.find_by(user_id: current_user.id)
      render_error("Player not found", status: :forbidden) and return unless @player
    end
  end
end
