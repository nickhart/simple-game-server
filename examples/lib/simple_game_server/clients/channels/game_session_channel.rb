

require "action_cable_client"

module Client
  module Channels
    class GameSessionChannel
      def initialize(url, game_session_id, &on_message)
        @client = ActionCableClient.new(url, "GameSessionChannel", id: game_session_id)
        @on_message = on_message

        setup_callbacks
      end

      def setup_callbacks
        @client.connected do
          puts "[GameSessionChannel] Connected to game session"
        end

        @client.received do |message|
          puts "[GameSessionChannel] Received message: #{message}"
          @on_message.call(message) if @on_message
        end

        @client.disconnected do
          puts "[GameSessionChannel] Disconnected from game session"
        end

        @client.errored do |error|
          puts "[GameSessionChannel] Error: #{error}"
        end
      end

      def send_command(data)
        @client.perform("receive", data)
      end

      def disconnect
        @client.disconnect
      end
    end
  end
end