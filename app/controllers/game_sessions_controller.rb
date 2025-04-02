class GameSessionsController < ApplicationController
  def index
    @game_sessions = GameSession.all
  rescue StandardError => e
    Rails.logger.error "Error loading game sessions: #{e.message}"
    @game_sessions = []
  end

  def show
    @game_session = GameSession.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to game_sessions_path, alert: "Game session not found."
  end

  def new
    @game_session = GameSession.new(min_players: 2, max_players: 4)
  end

  def create
    @game_session = GameSession.new(game_session_params)

    if @game_session.save
      redirect_to @game_session, notice: "Game session was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => e
    @game_session = GameSession.new
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "Error creating game session: #{e.message}"
    @game_session = GameSession.new
    flash.now[:alert] = "Error creating game session. Please try again."
    render :new, status: :unprocessable_entity
  end

  def cleanup
    cutoff_date = Time.parse(params[:before])

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

  def game_session_params
    params.require(:game_session).permit(:min_players, :max_players)
  end
end
