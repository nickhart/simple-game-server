module Api
  class GameSessionsController < BaseController
    before_action :authenticate_user!
    before_action :set_game_session, except: %i[index create]
    before_action :set_player, only: %i[create join leave start]

    def index
      @game_sessions = GameSession.includes(:players)
      render json: @game_sessions, include: { players: { only: %i[id name] } }
    end

    def show
      render json: @game_session, include: { players: { only: %i[id name] } }
    end

    def create
      @game_session = GameSession.new(game_session_params)
      @game_session.creator = @player
      @game_session.players << @player

      if @game_session.save
        render json: @game_session, include: { players: { only: %i[id name] } }, status: :created
      else
        render json: { errors: @game_session.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def join
      unless @game_session.waiting?
        return render json: { error: "Game is not in waiting status" },
                      status: :unprocessable_entity
      end

      if @game_session.players.include?(@player)
        render json: { error: "Player already in game" }, status: :unprocessable_entity
      else
        @game_session.players << @player
        render json: @game_session, include: { players: { only: %i[id name] } }
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

    private

    def set_game_session
      @game_session = GameSession.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Game session not found" }, status: :not_found
    end

    def set_player
      @player = Player.find(params[:player_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Player not found" }, status: :not_found
    end

    def game_session_params
      params.expect(game_session: %i[game_type min_players max_players])
    end
  end
end
