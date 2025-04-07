class GameSessionsController < ApplicationController
  before_action :set_game_session, only: [:show, :edit, :update, :destroy]

  def index
    @game_sessions = GameSession.all
  rescue StandardError => e
    Rails.logger.error "Error loading game sessions: #{e.message}"
    @game_sessions = []
  end

  def show
  end

  def new
    unless @game_session = GameSession.find_by(id: params[:id])
      redirect_to game_sessions_path, alert: t('.not_found')
    end
  end

  def create
    @game_session = GameSession.new(game_session_params)
    @player = Player.find_by(id: params[:player_id])

    if @player
      @game_session.players << @player
      if @game_session.save
        redirect_to @game_session, notice: t('.created')
      else
        render :new
      end
    else
      flash.now[:alert] = t('.player_not_found')
      render :new
    end
  rescue StandardError => e
    flash.now[:alert] = t('.create_error')
    render :new
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
    params.require(:game_session).permit(:name, :game_id)
  end
end
