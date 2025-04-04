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
      Rails.logger.info "Showing game session #{@game_session.id}"
      Rails.logger.info "Current state: #{@game_session.state.inspect}"
      Rails.logger.info "Current status: #{@game_session.status}"
      Rails.logger.info "Is game active? #{@game_session.active?}"
      render json: @game_session, include: { players: { only: %i[id name] } }
    end

    def update
      Rails.logger.info "Updating game session #{@game_session.id}"
      Rails.logger.info "Current state: #{@game_session.state.inspect}"
      Rails.logger.info "Current status: #{@game_session.status}"
      Rails.logger.info "Update params: #{game_session_params.inspect}"
      Rails.logger.info "Params being passed to update: #{game_session_params.except(:state).inspect}"

      # Merge new state with existing state if present
      if game_session_params[:state].present?
        @game_session.state = @game_session.state.merge(game_session_params[:state])
      end

      if @game_session.update(game_session_params.except(:state))
        Rails.logger.info "Game session updated successfully"
        Rails.logger.info "New state: #{@game_session.state.inspect}"
        Rails.logger.info "New status: #{@game_session.status}"
        Rails.logger.info "Is game active? #{@game_session.active?}"
        
        # If status is being set to finished, ensure the game is properly terminated
        if game_session_params[:status] == "finished"
          Rails.logger.info "Setting status to finished"
          @game_session.status = :finished
          Rails.logger.info "Status before save: #{@game_session.status}"
          @game_session.save
          Rails.logger.info "Status after save: #{@game_session.status}"
          Rails.logger.info "Is game active after save? #{@game_session.active?}"
          Rails.logger.info "Final state: #{@game_session.state.inspect}"
        # Only advance turn if game is still active and state is being updated
        elsif game_session_params[:state].present? && @game_session.active?
          Rails.logger.info "Advancing turn because game is active"
          @game_session.advance_turn
        end

        # Verify state is not empty
        if @game_session.state.empty?
          Rails.logger.error "Game session state is empty after update!"
          raise "Game session state is empty after update"
        end

        render json: @game_session, include: { players: { only: %i[id name] } }
      else
        Rails.logger.error "Failed to update game session: #{@game_session.errors.full_messages}"
        render json: { errors: @game_session.errors.full_messages }, status: :unprocessable_entity
      end
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
      Rails.logger.info "Setting game session for id: #{params[:id]}"
      @game_session = GameSession.find(params[:id])
      Rails.logger.info "Found game session:"
      Rails.logger.info "State: #{@game_session.state.inspect}"
      Rails.logger.info "Status: #{@game_session.status}"
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Game session not found for id: #{params[:id]}"
      render json: { error: "Game session not found" }, status: :not_found
    end

    def set_player
      @player = Player.find(params[:player_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Player not found" }, status: :not_found
    end

    def game_session_params
      params.require(:game_session).permit(
        :current_player_index,
        :status,
        :current_player_id,
        state: {}
      )
    end
  end
end
