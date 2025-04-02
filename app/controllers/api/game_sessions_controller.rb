module Api
  class GameSessionsController < BaseController
    def index
      @game_sessions = GameSession.all.includes(:players)
      render json: @game_sessions.as_json(include: { players: { only: %i[id name] } })
    end

    def show
      @game_session = GameSession.find(params[:id])
      Rails.logger.info "GET /api/game_sessions/#{params[:id]}"
      Rails.logger.info "Game session state: #{@game_session.state}"
      Rails.logger.info "Current player index: #{@game_session.current_player_index}"
      Rails.logger.info "Players: #{@game_session.players.map { |p| { id: p.id, name: p.name } }}"
      render json: @game_session.as_json(include: { players: { only: %i[id name] } })
    end

    def create
      @game_session = GameSession.new(game_session_params)
      if @game_session.save
        render json: @game_session.as_json(include: { players: { only: %i[id name] } }), status: :created
      else
        render json: @game_session.errors, status: :unprocessable_entity
      end
    end

    def update
      @game_session = GameSession.find(params[:id])
      if @game_session.update(game_session_params)
        render json: @game_session.as_json(include: { players: { only: %i[id name] } })
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

      if @game_session.active? || @game_session.finished?
        render json: { error: "Cannot join a game that is already #{@game_session.status}" },
               status: :unprocessable_entity
        return
      end

      if @game_session.players.count >= @game_session.max_players
        render json: { error: "Game is full" }, status: :unprocessable_entity
        return
      end

      @game_session.players.create!(
        user: current_user,
        name: "Player #{@game_session.players.count + 1}"
      )

      render json: @game_session.as_json(include: { players: { only: %i[id name] } })
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
          @game_session.update(status: :waiting) if @game_session.players.empty?

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
      player_id = params[:player_id]

      unless player_id
        render json: { error: "player_id is required" }, status: :unprocessable_entity
        return
      end

      if @game_session.start(player_id)
        render json: @game_session.as_json(include: { players: { only: %i[id name] } })
      else
        render json: { error: "Could not start game" }, status: :unprocessable_entity
      end
    end

    def cleanup
      # Default to 1 day ago if no date provided
      before = params[:before] ? Time.parse(params[:before]) : 1.day.ago

      deleted_count = GameSession.where("created_at < ? AND status = ?", before,
                                        GameSession.statuses[:waiting]).destroy_all.count
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

    def update_game_state
      @game_session = GameSession.find(params[:id])
      Rails.logger.info "PATCH /api/game_sessions/#{params[:id]}/update_game_state"
      Rails.logger.info "Request params: #{params}"
      Rails.logger.info "Current game state: #{@game_session.state}"
      Rails.logger.info "Current player index: #{@game_session.current_player_index}"

      # Check if it's the player's turn
      unless @game_session.current_player.id == params[:player_id]
        Rails.logger.info "Not player's turn. Current player: #{@game_session.current_player.id}, Requested player: #{params[:player_id]}"
        render json: { error: "It's not your turn" }, status: :unprocessable_entity
        return
      end

      # Update the game state
      @game_session.state = params[:state]
      Rails.logger.info "Updated game state: #{@game_session.state}"

      # Advance to next player's turn
      if @game_session.advance_turn
        Rails.logger.info "Turn advanced successfully"
        Rails.logger.info "New current player index: #{@game_session.current_player_index}"
        render json: @game_session.as_json(include: { players: { only: %i[id name] } })
      else
        Rails.logger.error "Failed to advance turn"
        render json: { error: "Could not advance turn" }, status: :unprocessable_entity
      end
    end

    private

    def game_session_params
      params.require(:game_session).permit(:status, :min_players, :max_players)
    end

    def player_params
      params.require(:player).permit(:name)
    end
  end
end
