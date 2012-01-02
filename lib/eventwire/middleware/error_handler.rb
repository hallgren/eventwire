module Eventwire
  module Middleware
    class ErrorHandler < Base

      def initialize(app, options = {})
        super(app)
        #puts options
        @error_handler = options.delete(:error_handler) || lambda{|ex|}
        @logger = options.delete(:logger) || ::Logger.new(nil)
      end

      def subscribe(event_name, handler_id, &handler)
        @app.subscribe event_name, handler_id do |data|
          begin
            handler.call(data)
          rescue Exception => ex
            @logger.error "\nAn error occurred in (subscribe): `#{ex.message}`\n#{ex.backtrace.join("\n")}\n"
            @error_handler.call(ex)
          end
        end
      end

      def handle_event(event_name, event_data)
        begin
          @app.handle_event event_name, event_data
        rescue Exception => ex
          puts "\nAn error occurred in (hadnle_event): `#{ex.message}`\n#{ex.backtrace.join("\n")}\n"
          @logger.error "\nAn error occurred in (hadnle_event): `#{ex.message}`\n#{ex.backtrace.join("\n")}\n"
          @error_handler.call(ex)
        end
      end
      
    end
  end
end