require 'bunny'
require 'amqp'

class Eventwire::Drivers::AMQP_UPPTEC
  def metaclass
    class << self; self; end
  end

  
  def initialize(*args)
    
    puts args

    @event_host = "localhost"
    @event_port = 5672
    @event_user = "guest"
    @event_password = "guest"
    @event_vhost = "/"

    @command_host = "localhost"
    @command_port = 5672
    @command_user = "guest"
    @command_password = "guest"
    @command_vhost = "/"

    @command_ex = "command_ex3"
    @event_ex = "event_ex3"
    @event_queue = "event_queue3"
   # @error_ex = @event_ex


    if args.length > 0

      @event_host = args[0][:event_host] if !args[0][:event_host].nil?
      @event_port = args[0][:event_port] if !args[0][:event_port].nil?
      @event_user = args[0][:event_user] if !args[0][:event_user].nil?
      @event_password = args[0][:event_password] if !args[0][:event_password].nil?
      @event_vhost = args[0][:event_vhost] if !args[0][:event_vhost].nil?

      @command_host = args[0][:command_host] if !args[0][:command_host].nil?
      @command_port = args[0][:command_port] if !args[0][:command_port].nil?
      @command_user = args[0][:command_user] if !args[0][:command_user].nil?
      @command_password = args[0][:command_password] if !args[0][:command_password].nil?
      @command_vhost = args[0][:command_vhost] if !args[0][:command_vhost].nil?

      @command_ex = args[0][:command_ex] if !args[0][:command_ex].nil?
      @event_ex = args[0][:event_ex] if !args[0][:event_ex].nil?
      @event_queue = args[0][:event_queue] if !args[0][:event_queue].nil?
      #@error_ex = args[0][:error_ex] if !args[0][:error_ex].nil?

    end

  end

  
  def publish(event_name, event_data = nil)
    Bunny.run(:host => @event_host, :port => @event_port, :user => @event_user, :pass => @event_password, :vhost => @event_vhost) do |mq|
      mq.exchange(@event_ex, :type => :topic,  :persistent => true, :durable => true).publish(event_data, :key => event_name.to_s)
    end    
  end

  def subscribe(event_name, handler_id, &handler)
    subscriptions << [event_name, handler_id, handler]
  end

  def start
    AMQP.start(:host => @event_host, :port => @event_port, :user => @event_user, :pass => @event_password, :vhost => @event_vhost) do |connection|
  
      AMQP::Channel.new(connection, 2, :auto_recovery => true) do |channel|
        #puts "connected to #{APP_CONFIG["eventwire_event_host"]} #{APP_CONFIG["eventwire_event_port"]} #{APP_CONFIG["eventwire_event_user"]} #{APP_CONFIG["eventwire_event_password"]} #{APP_CONFIG["eventwire_event_vhost"]} Exchange: #{APP_CONFIG["eventwire_event_exchange"]} Queue: #{APP_CONFIG["eventwire_event_queue"]}"
        #puts subscriptions.count
        #puts subscriptions

        if channel.auto_recovering?
          #puts "Channel #{channel.id} IS auto-recovering"
        end

        connection.on_tcp_connection_loss do |conn, settings|
          
          #puts "[network failure] Trying to reconnect..."
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
        event_exchange = channel.topic(@event_ex, :durable => true)
        event_queue    = channel.queue(@event_queue, :durable => true, :auto_delete => false)

        #Bind to events
        subscriptions.each do |subscription|
          event_queue.bind(@event_ex, :routing_key => subscription[0].to_s, :durable => true)
        end
        

        event_queue.subscribe(:ack => true) do |header, body|
          puts " [event] #{header.routing_key}: ---  #{body}"
          
          handle_event header.routing_key, body
        
          header.ack          
          
        end
      end
    end
  end

  def stop
    AMQP.stop { EM.stop }
  end
  
  def purge
    AMQP.start(:host => @event_host, :port => @event_port, :user => @event_user, :pass => @event_password, :vhost => @event_vhost) do |connection|
      channel = AMQP::Channel.new(connection) 
      queue = channel.queue(@event_queue, :durable => true, :auto_delete => false)
      queue.purge(:nowait => true)

      AMQP.stop { EM.stop } 
    end
  end

  def handle_event event_name, event_data
    puts "handle event #{event_name} #{event_data}"
    event_not_already_handled = true

    if self.respond_to?('event_validator')
      event_not_already_handled = self.event_validator(event_data)
    end

    if event_not_already_handled
      subscriptions.each do |subscription|
        if (subscription[0].to_s == event_name)
          subscription[2].call event_data           
        end
      end
    else
      return false          
    end

    if self.respond_to?('event_creator')
      self.event_creator(event_data)
    end

    return true
  end

  def subscriptions
    @subscriptions ||= []
  end

  
end