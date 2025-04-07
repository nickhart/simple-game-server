class GameSessionsController < ApplicationController
  before_action :set_game_session, only: %i[show]

  def index
    @game_sessions = GameSession.all
  rescue StandardError => e
    Rails.logger.error "Error loading game sessions: #{e.message}"
    @game_sessions = []
  end

  def show; end

  def new
    @game_session = GameSession.new(min_players: 2, max_players: 4)
  end

  def create
    @game_session = GameSession.new(game_session_params)
    @game_session.creator_id = params[:player_id]

    if @game_session.save
      add_creator_as_player
      redirect_to @game_session, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    handle_create_error(t(".player_not_found"))
  rescue ActionController::ParameterMissing => e
    handle_create_error(e.message)
  rescue StandardError => e
    Rails.logger.error "Error creating game session: #{e.message}"
    handle_create_error(t(".create_error"))
  end

  def cleanup
    cutoff_date = Time.zone.parse(params[:before])

    # Find and delete games that:
    # 1. Are older than the cutoff date
    # 2. Have no players (haven't been joined)
    # 3. Are in 'waiting' status
    deleted_count = GameSession.where("created_at < ? AND players_count = 0 AND status = ?",
                                      cutoff_date,
                                      "waiting").destroy_all.count

    render json: {
      message: "Deleted #{deleted_count} unused game sessions created before #{cutoff_date}",
      deleted_count: deleted_count
    }
  end

  private

  def set_game_session
    @game_session = GameSession.find(params[:id])
  end

  def game_session_params
    params.require(:game_session).permit(:min_players, :max_players, :game_type)
  end

  def add_creator_as_player
    @game_session.players << Player.find(params[:player_id])
  end

  def handle_create_error(message)
    @game_session = GameSession.new
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end
end
