require 'hashie/mash'

module Eventwire
  module Middleware
    class DataObjects < Base
      def subscribe(event_name, handler_id, &handler)
        @app.subscribe event_name, handler_id do |data|
          puts "biuld hash subscribe from #{data}"
          handler.call build_event(data)
        end
      end

      def handle_event(event_name, event_data)
        puts "handle_event: DataObjects #{event_name} #{event_data}"
        @app.handle_event event_name, build_event(event_data)
        puts "AFTER handle_event: DataObjects #{event_name} #{event_data}"
      end

      private

      def build_event(data)
        Hashie::Mash.new(data)
      end
    end
  end
end