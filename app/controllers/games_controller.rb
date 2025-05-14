class GamesController < ApplicationController
  before_action :set_game, only: %i[show update destroy]
  before_action :require_admin, only: %i[create update destroy]

  def index
    render json: Game.all
  end

  def show
    render json: @game
  end

  def create
    @game = Game.new(game_params)
    if @game.save
      render json: @game, status: :created
    else
      render json: { errors: @game.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @game.update(game_params)
      render json: @game
    else
      render json: { errors: @game.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @game.destroy
    head :no_content
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.expect(game: %i[name min_players max_players state_json_schema])
  end

  def require_admin
    render_forbidden("Admin access required") unless current_user&.admin?
  end
end
