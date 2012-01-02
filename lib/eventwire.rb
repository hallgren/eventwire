require 'eventwire/version'
require 'eventwire/publisher'
require 'eventwire/subscriber'
require 'eventwire/event_handler'
require 'eventwire/drivers'
require 'eventwire/middleware'

module Eventwire
  
  class << self
    
    def reset!
      @driver = nil
      @middleware = nil
      @logger = nil
      @namespace = nil
    end
    
    def driver
      puts "DRIVER init() #{@driver}"
      @driver ||= decorate(Drivers::InProcess.new)
    end
  
    def driver=(driver)
      puts "DRIVER  #{driver}"
      klass = Drivers.const_get(driver.to_sym) if driver.respond_to?(:to_sym)
      @driver = decorate(klass ? klass.new() : driver)
    end
    
    def logger
      @logger ||= Logger.new(nil)
    end
  
    def logger=(logger)
      @logger = logger
    end
    
    def namespace
      @namespace
    end
    
    def namespace=(namespace)
      @namespace = namespace
    end
  
    def start_worker
      driver.start
    end
  
    def stop_worker
      driver.stop
    end
  
    def on_error(&block)
      @error_handler = block
    end
    
    def error_handler
      @error_handler ||= lambda {|ex| puts "EXCEPTION #{ex}"}
    end

    #def event_validator_handler
    #  @event_validator_handler ||= lambda {|data| true} 
    #end

    def on_event_validation(&block)

      driver.metaclass.send(:define_method, 'event_validator') do |event|
        block.call event
      end

    end

    # def event_creator_handler
    #   @event_creator_handler ||= lambda {|data|}
    # end

    def on_event_creation(&block)

      driver.metaclass.send(:define_method, 'event_creator') do |event|
        block.call event
      end

    end

    def handle_event(event_name, event_data = nil)
      driver.handle_event event_name, event_data
    end
  
    def publish(event_name, event_data = nil)
      driver.publish event_name, event_data
    end
    
    def subscribe(event_name, handler_id, &handler)
      driver.subscribe event_name, handler_id, &handler
    end

    def middleware
      @middleware ||= [ [Eventwire::Middleware::ErrorHandler, {:error_handler => Eventwire.error_handler, :logger => Eventwire.logger}],
                        [Eventwire::Middleware::Logger, {:logger => Eventwire.logger}],
                         Eventwire::Middleware::JSONSerializer,
                         Eventwire::Middleware::DataObjects]
                    #    [Eventwire::Middleware::EventValidatorHandler, {:event_creator_handler => Eventwire.event_creator_handler ,:event_validator_handler => Eventwire.event_validator_handler, :error_handler => Eventwire.error_handler}] ]
    end
    
    def decorate(driver)
      middleware.inject(driver) do |driver, args|
        
        args = Array(args)
        klass = args.shift

        if args && args.any?
          klass.new(driver, *args)
        else
          klass.new(driver)
        end
      end
    end

  end
  
end
