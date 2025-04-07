module Api
  class GameSessionsController < BaseController
    before_action :set_game_session, except: %i[index create cleanup]
    before_action :set_player, only: %i[create join leave start]
    before_action :set_game, only: %i[create]

    def index
      @game_sessions = GameSession.includes(:players, :game)
      render json: @game_sessions, include: { players: { only: %i[id name] }, game: { only: %i[id name] } }
    end

    def show
      render json: @game_session, include: { players: { only: %i[id name] }, game: { only: %i[id name] } }
    end

    def create
      # Validate that if either min_players or max_players is provided, both must be
      if params[:game_session][:min_players].present? || params[:game_session][:max_players].present?
        unless params[:game_session][:min_players].present? && params[:game_session][:max_players].present?
          return render json: { error: "Both min_players and max_players must be provided if either is specified" },
                        status: :unprocessable_entity
        end

        # Validate against game configuration limits
        min_players = params[:game_session][:min_players].to_i
        max_players = params[:game_session][:max_players].to_i

        if min_players < @game.min_players
          return render json: { error: "min_players cannot be less than #{@game.min_players}" },
                        status: :unprocessable_entity
        end

        if max_players > @game.max_players
          return render json: { error: "max_players cannot be greater than #{@game.max_players}" },
                        status: :unprocessable_entity
        end

        if min_players > max_players
          return render json: { error: "min_players cannot be greater than max_players" },
                        status: :unprocessable_entity
        end
      end

      @game_session = GameSession.new(game_session_params)
      @game_session.game = @game
      @game_session.creator = @player
      @game_session.players << @player

      # Set default min/max players from game configuration if not provided
      @game_session.min_players ||= @game.min_players
      @game_session.max_players ||= @game.max_players

      if @game_session.save
        render json: @game_session, include: { players: { only: %i[id name] }, game: { only: %i[id name] } },
               status: :created
      else
        render json: { errors: @game_session.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      Rails.logger.info "Updating game session #{@game_session.id}"
      Rails.logger.info "Current state: #{@game_session.state.inspect}"
      Rails.logger.info "Current status: #{@game_session.status}"
      Rails.logger.info "Update params: #{params[:game_session].inspect}"

      # Only allow updating status and state
      update_params = params.require(:game_session).permit(:status, state: {})

      Rails.logger.info "Params being passed to update: #{update_params.inspect}"

      # Merge the new state with the existing state
      if update_params[:state].present?
        new_state = @game_session.state.merge(update_params[:state])
        update_params[:state] = new_state
      end

      if @game_session.update(update_params)
        # Advance turn if state was updated and game is active
        if update_params[:state].present? && @game_session.active?
          Rails.logger.info "Advancing turn because state was updated and game is active"
          @game_session.advance_turn
        end

        render json: @game_session, include: { players: { only: %i[id name] } }
      else
        Rails.logger.error "Failed to update game session: #{@game_session.errors.full_messages}"
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

    def cleanup
      before_time = params[:before] ? Time.zone.parse(params[:before]) : 1.day.ago
      old_games = GameSession.where(status: "waiting")
                             .where(created_at: ...before_time)

      old_games.destroy_all
      render json: { message: "Cleanup completed" }
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
      @player = Player.find(params[:player_id] || params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Player not found" }, status: :not_found
    end

    def set_game
      @game = if params[:game_id]
                Game.find(params[:game_id])
              else
                # Use game_name from params or default to Tic-Tac-Toe
                game_name = params.dig(:game_session, :game_name) || "Tic-Tac-Toe"
                game = Game.find_by(name: game_name)
                unless game
                  render json: { error: "Game '#{game_name}' not found" }, status: :not_found
                  return
                end
                game
              end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Game not found" }, status: :not_found
    end

    def game_session_params
      params.require(:game_session).permit(
        :status,
        :current_player_id,
        :min_players,
        :max_players,
        :game_id,
        state: @game&.state_schema || {}
      )
    end
  end
end
