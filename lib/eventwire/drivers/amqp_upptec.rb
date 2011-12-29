require 'bunny'
require 'amqp'

class Eventwire::Drivers::AMQP_UPPTEC
  def metaclass
    class << self; self; end
  end

  def publish(event_name, event_data = nil)
    Bunny.run do |mq|
      mq.exchange("test_ex", :type => :topic,  :persistent => true, :durable => true).publish(event_data, :key => event_name.to_s)
    end    
  end

  def subscribe(event_name, handler_id, &handler)
    subscriptions << [event_name, handler_id, handler]
  end

  def start
    puts "Start"
    EM.run do|em|
      @em = em
      AMQP.connect() do |connection|
    
        channel = AMQP::Channel.new(connection, 2, :auto_recovery => true) 
        #puts "connected to #{APP_CONFIG["eventwire_event_host"]} #{APP_CONFIG["eventwire_event_port"]} #{APP_CONFIG["eventwire_event_user"]} #{APP_CONFIG["eventwire_event_password"]} #{APP_CONFIG["eventwire_event_vhost"]} Exchange: #{APP_CONFIG["eventwire_event_exchange"]} Queue: #{APP_CONFIG["eventwire_event_queue"]}"
        puts subscriptions.count
        puts subscriptions

        if channel.auto_recovering?
          puts "Channel #{channel.id} IS auto-recovering"
        end

        connection.on_tcp_connection_loss do |conn, settings|
          
          puts "[network failure] Trying to reconnect..."
          conn.reconnect(false, 2)

        end

        connection.on_recovery do |conn, settings|
          puts "[recovery] Connection has recovered"

          #Send error event abount the downtime
          #mq = MessageQueue.new
          #mq.message_type = "error"
          #mq.message_name = "" #Not used
          #mq.message_data = {:error_message => "Connection to Broker has been down: #{Rails.application.class.parent_name}"}.to_json
          #mq.save
          
        end

        #Setup event handler queue
        event_exchange = channel.topic("test_ex", :durable => true)
        event_queue    = channel.queue("test_queue", :durable => true, :auto_delete => false)

        #Bind to events
        subscriptions.each do |subscription|
          puts subscription
          event_queue.bind("test_ex", :routing_key => subscription[0].to_s, :durable => true)
        end
        

        event_queue.subscribe(:ack => true) do |header, body|
          puts " [event] #{header.routing_key}: ---  #{body}"
          
          event_not_already_handled = true

          if self.respond_to?('event_validator')
            event_not_already_handled = self.event_validator
          end

          if event_not_already_handled
            subscriptions.each do |subscription|
              if (subscription[0].to_s == header.routing_key)
                puts "#{subscription}"
                subscription[2].call body           
              end
            end          
          end

          if self.respond_to?('event_creator')
            self.event_creator
          end
        
          header.ack          

          puts "HANDLER RESULT"
          
        end
      end
    end
  end

  def stop
    AMQP.stop { EM.stop }
  end
  
  def purge
    AMQP.start() do |connection|
      channel = AMQP::Channel.new(connection) 
      queue = channel.queue("test_queue", :durable => true, :auto_delete => false)
      queue.purge

      EventMachine::add_timer( 1 ) { EM.stop; exit }
    end

  end

  def subscriptions
    @subscriptions ||= []
  end

  
end