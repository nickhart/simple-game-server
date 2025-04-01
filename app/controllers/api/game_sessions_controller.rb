module Api
  class GameSessionsController < BaseController
    def index
      @game_sessions = GameSession.all
      render json: @game_sessions
    end

    def create
      @game_session = GameSession.new(game_session_params)
      if @game_session.save
        render json: @game_session, status: :created
      else
        render json: @game_session.errors, status: :unprocessable_entity
      end
    end

    def show
      @game_session = GameSession.find(params[:id])
      render json: @game_session
    end

    def update
      @game_session = GameSession.find(params[:id])
      if @game_session.update(game_session_params)
        render json: @game_session
      else
        render json: @game_session.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @game_session = GameSession.find(params[:id])
      @game_session.destroy
      head :no_content
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
  end
end 