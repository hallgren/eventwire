require 'spec_helper'

describe Eventwire::EventHandler do
  
  describe 'handle event' do
    
    before do
      @driver = mock
      Eventwire.middleware.clear
      Eventwire.driver = @driver
    end
    
    subject { class_including(Eventwire::EventHandler).new }
    

    it 'should get the event handle_event parsed with json middleware' do
      middleware1 = Eventwire::Middleware::JSONSerializer
      Eventwire.middleware.replace [[middleware1]]
      Eventwire.driver = @driver
      Eventwire.driver.should_receive(:handle_event).with(:task_created, {"name" => "eventwire"})
      
      subject.handle_event :task_created, '{"name":"eventwire"}'
    end

   
    
  end
end