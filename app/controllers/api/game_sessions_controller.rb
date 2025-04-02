module Api
  class GameSessionsController < ApplicationController
    before_action :set_game_session, except: [:index, :create]
    before_action :set_player, only: [:create, :join, :leave]

    def index
      @game_sessions = GameSession.includes(:players)
      render json: @game_sessions, include: { players: { only: [:id, :name] } }
    end

    def create
      @game_session = GameSession.new(game_session_params)
      @game_session.creator = @player
      @game_session.players << @player

      if @game_session.save
        render json: @game_session, include: { players: { only: [:id, :name] } }, status: :created
      else
        render json: { errors: @game_session.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def join
      return render json: { error: "Game is not in waiting status" }, status: :unprocessable_entity unless @game_session.waiting?
      return render json: { error: "Player already in game" }, status: :unprocessable_entity if @game_session.players.include?(@player)
      return render json: { error: "Game is full" }, status: :unprocessable_entity if @game_session.players.count >= @game_session.max_players

      @game_session.players << @player
      render json: @game_session, include: { players: { only: [:id, :name] } }
    end

    def leave
      return render json: { error: "Player not in game" }, status: :unprocessable_entity unless @game_session.players.include?(@player)

      @game_session.players.delete(@player)
      
      # If no players left, update game status to waiting
      @game_session.update(status: :waiting) if @game_session.players.empty?
      
      render json: { message: "Successfully left the game" }
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
      params.require(:game_session).permit(:game_type, :min_players, :max_players)
    end
  end
end
