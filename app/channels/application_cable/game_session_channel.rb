module ApplicationCable
  class GameSessionChannel < ApplicationCable::Channel
    def subscribed
      game_session = GameSession.find(params[:id])
      stream_for game_session
    end

    def unsubscribed; end

    def receive(data)
      Rails.logger.info("Received data on GameSessionChannel: #{data.inspect}")
    end

    def self.broadcast_update(game_session)
      broadcast_to(game_session, {
                     event: "updated",
                     data: game_session.as_json
                   })
    end
  end
end
