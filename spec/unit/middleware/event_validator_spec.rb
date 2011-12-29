# encoding: UTF-8
require 'spec_helper'

describe Eventwire::Middleware::EventValidatorHandler do
  
  let(:app) { mock }
  subject { Eventwire::Middleware::EventValidatorHandler.new(app) }

  before do
    @driver = mock
    Eventwire.middleware.clear
    Eventwire.driver = @driver
  end
  
  describe 'subscribe' do

    context "Standard stuff" do

      it 'should call app’s subscribe' do
        app.should_receive(:subscribe).with(:event_name, :handler_id)
        
        subject.subscribe(:event_name, :handler_id)
      end
    end
        
    context 'when event_validator_handler is present' do
      
      
      it 'should set the event var to true' do
        subject { Eventwire::Middleware::EventValidatorHandler.new(app, :event_validator_handler => lambda { |e| return true; }) }
        @event = false
        
        app.stub :subscribe do |_, _, handler|
          @event = handler.call
        end

        subject.subscribe :event_name, :handler_id do
        end

        @event == true
      end

      it 'should set the event var to false' do
        subject { Eventwire::Middleware::EventValidatorHandler.new(app, :event_validator_handler => lambda { |e| return false; }) }
        @event = true
        
        app.stub :subscribe do |_, _, handler|
          @event = handler.call
        end

        subject.subscribe :event_name, :handler_id do
        end

        @event == false
      end

    end
  end
  
end