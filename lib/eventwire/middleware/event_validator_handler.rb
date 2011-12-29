module Eventwire
  module Middleware
    class EventValidatorHandler < Base

      def initialize(app, options = {})
        super(app)
        @event_validator_handler = options.delete(:event_validator_handler) || lambda{|ex|}
        @event_creator_handler = options.delete(:event_creator_handler) || lambda{|ex|}
        @error_handler = options.delete(:error_handler) || lambda{|ex|}

      end

      def subscribe(event_name, handler_id, &handler)
        @app.subscribe event_name, handler_id do |data|

            if @event_validator_handler.call(data)
              handler.call(data)
              @event_creator_handler.call(data)
            else
              @error_handler.call("Event already handled before: #{data}")
            end
        end
      end
      
    end
  end
end