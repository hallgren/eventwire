require 'spec_helper'


describe 'Integration test on the handle event function' do
  
  drivers = %w{AMQP_UPPTEC}

  drivers.each do |driver|

    context "using the #{driver} driver" do

      before do
        
        
        Eventwire.driver = Eventwire::Drivers::AMQP_UPPTEC.new({:host => "localhost"})
        Eventwire.on_event_creation() { |event| Event.add(event) }
        Eventwire.on_event_validation() { |event| Event.check(event) == false ? true : false}

        load_environment
        start_worker

      end

      after do
        stop_worker
        sleep 1
        purge
      end

      example 'Adding items should add events' do
        item1 = Item.new
        item1.add_item("item1")
        item2 = Item.new
        item2.add_item("item2")

        fail unless Event.get_event_count() == 2
      end

      example 'Adding same items should not add events' do
        item1 = Item.new
        item1.add_item("item1")
        item2 = Item.new
        item2.add_item("item1")

        fail unless Event.get_event_count() == 1
      end

      example 'Adding same items in diffrent order should not add events' do
        item1 = Item.new
        item1.add_item("item1")
        item2 = Item.new
        item2.add_item("item2")
        item3 = Item.new
        item3.add_item("item3")
        item4 = Item.new
        item4.add_item("item1")
        item5 = Item.new
        item5.add_item("item2")
        item6 = Item.new
        item6.add_item("item3")

        fail unless Event.get_event_count() == 3
      end

    end

  end
  
  private

  def start_worker
    @t = Thread.new { 
      require 'rake'
      require 'eventwire/tasks'
      
      Rake::Task['eventwire:work'].execute 
    }
    @t.abort_on_exception = true
    sleep 0.1
  end

  def load_environment
    load 'examples/event_sourcing/event.rb'
    load 'examples/event_sourcing/item.rb'
  end

  def stop_worker
    return unless @t.alive?
    
    Eventwire.stop_worker
    
    @t.join(1)
    fail 'Worker should have stopped' if @t.alive?
    @t.kill # even if not alive, it seems that in 1.8.7 we need to kill it
  end
  
  def purge
    Eventwire.driver.purge
  end

end