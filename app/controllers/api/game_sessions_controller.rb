module Api
  class GameSessionsController < BaseController
    def index
      @game_sessions = GameSession.all.includes(:players)
      render json: @game_sessions.as_json(include: { players: { only: [:id, :name] } })
    end

    def create
      @game_session = GameSession.new(game_session_params)
      if @game_session.save
        render json: @game_session.as_json(include: { players: { only: [:id, :name] } }), status: :created
      else
        render json: @game_session.errors, status: :unprocessable_entity
      end
    end

    def show
      @game_session = GameSession.find(params[:id])
      render json: @game_session.as_json(include: { players: { only: [:id, :name] } })
    end

    def update
      @game_session = GameSession.find(params[:id])
      if @game_session.update(game_session_params)
        render json: @game_session.as_json(include: { players: { only: [:id, :name] } })
      else
        render json: @game_session.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @game_session = GameSession.find(params[:id])
      @game_session.destroy
      head :no_content
    end

    def join
      @game_session = GameSession.find(params[:id])
      
      # Check if game is in waiting state
      unless @game_session.waiting?
        render json: { error: "Game session is not available to join" }, status: :unprocessable_entity
        return
      end

      # Create a new player
      @player = Player.new(player_params)
      
      if @player.save
        # Associate player with game session
        if @game_session.add_player(@player)
          render json: @player, status: :created
        else
          @player.destroy
          render json: { error: "Could not add player to game session" }, status: :unprocessable_entity
        end
      else
        render json: @player.errors, status: :unprocessable_entity
      end
    end

    def leave
      @game_session = GameSession.find(params[:id])
      @player = @game_session.players.find_by(id: params[:player_id])

      if @player
        # Find and destroy the game_player association
        game_player = @game_session.game_players.find_by(player: @player)
        if game_player
          game_player.destroy
          
          # If no players left, update game status to waiting
          if @game_session.players.empty?
            @game_session.update(status: :waiting)
          end
          
          render json: { message: "Player successfully left the game" }, status: :ok
        else
          render json: { error: "Player is not in this game session" }, status: :not_found
        end
      else
        render json: { error: "Player not found" }, status: :not_found
      end
    end

    def start
      @game_session = GameSession.find(params[:id])
      
      # Check if game is in waiting state
      unless @game_session.waiting?
        render json: { error: "Game can only be started when in waiting state" }, status: :unprocessable_entity
        return
      end

      # Check if we have enough players
      if @game_session.players.count < @game_session.min_players
        render json: { 
          error: "Not enough players to start game",
          current_players: @game_session.players.count,
          min_players: @game_session.min_players
        }, status: :unprocessable_entity
        return
      end

      # Start the game
      if @game_session.start_game
        render json: @game_session.as_json(include: { players: { only: [:id, :name] } })
      else
        render json: { error: "Could not start game" }, status: :unprocessable_entity
      end
    end

    def cleanup
      begin
        # Default to 1 day ago if no date provided
        before = params[:before] ? Time.parse(params[:before]) : 1.day.ago
        
        deleted_count = GameSession.where('created_at < ? AND status = ?', before, GameSession.statuses[:waiting]).destroy_all.count
        render json: { 
          message: "Deleted #{deleted_count} unused game sessions", 
          deleted_count: deleted_count,
          before: before.iso8601
        }
      rescue ArgumentError => e
        render json: { 
          error: "Invalid date format. Please provide a valid ISO8601 date.",
          details: e.message
        }, status: :unprocessable_entity
      end
    end

    private

    def game_session_params
      params.require(:game_session).permit(:status)
    end

    def player_params
      params.require(:player).permit(:name)
    end
  end
end 