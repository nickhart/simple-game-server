module Api
  class GameSessionsController < BaseController
    before_action :set_game_session, except: %i[index create cleanup]
    before_action :set_player, only: %i[create join start leave]
    before_action :set_game, only: %i[create]

    def index
      @game_sessions = GameSession.all
      render json: @game_sessions, include: { players: { only: %i[id name] }, game: { only: %i[id name] } }
    end

    def show
      render json: @game_session, include: { players: { only: %i[id name] }, game: { only: %i[id name] } }
    end

    def create
      @game_session = GameSession.new(game_session_params)
      @game_session.game = @game
      @game_session.creator = @player

      if @game_session.save
        @game_session.players << @player
        render json: @game_session, include: { players: { only: %i[id name] }, game: { only: %i[id name] } },
               status: :created
      else
        render json: { errors: @game_session.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @game_session.update(game_session_params)
        @game_session.advance_turn
        render json: @game_session, include: { players: { only: %i[id name] }, game: { only: %i[id name] } }
      else
        render json: { errors: @game_session.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def join
      if @game_session.players.include?(@player)
        render json: { error: "Player is already in this game session" }, status: :unprocessable_entity
      elsif @game_session.players.count >= @game_session.max_players
        render json: { error: "Game session is full" }, status: :unprocessable_entity
      else
        @game_session.players << @player
        render json: @game_session, include: { players: { only: %i[id name] }, game: { only: %i[id name] } }
      end
    end

    def leave
      unless @game_session.players.include?(@player)
        return render json: { error: "Player not in game" },
                      status: :unprocessable_entity
      end

      @game_session.players.delete(@player)
      render json: { message: "Player left the game" }
    end

    def start
      unless @game_session.creator_id == @player.id
        return render json: { error: "Only the creator can start the game" },
                      status: :unauthorized
      end
      unless @game_session.waiting?
        return render json: { error: "Game is not in waiting status" },
                      status: :unprocessable_entity
      end
      if @game_session.players.count < @game_session.min_players
        return render json: { error: "Not enough players" },
                      status: :unprocessable_entity
      end
      if @game_session.players.count > @game_session.max_players
        return render json: { error: "Too many players" },
                      status: :unprocessable_entity
      end

      if @game_session.start(@player.id)
        render json: @game_session, include: { players: { only: %i[id name] } }
      else
        render json: { errors: @game_session.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def cleanup
      before_time = params[:before] ? Time.zone.parse(params[:before]) : 1.day.ago
      old_games = GameSession.where(status: "waiting")
                             .where(created_at: ...before_time)

      old_games.destroy_all
      render json: { message: "Cleanup completed" }
    end

    private

    def set_game_session
      @game_session = GameSession.find(params[:id])
    end

    def set_player
      @player = Player.find(params[:player_id])
    end

    def set_game
      # First try to find by game_id if provided
      if params[:game_session][:game_id].present?
        @game = Game.find(params[:game_session][:game_id])
      else
        # Fall back to finding by game_name
        game_name = params[:game_session][:game_name]
        @game = Game.find_by(name: game_name)
      end

      return if @game

      render json: { error: "Game not found" }, status: :not_found
    end

    def game_session_params
      params.require(:game_session).permit(:min_players, :max_players, :state)
    end
  end
end
